const crypto = require("crypto");
const admin = require("firebase-admin");
const logger = require("firebase-functions/logger");
const {onDocumentWritten} = require("firebase-functions/v2/firestore");
const {onSchedule} = require("firebase-functions/v2/scheduler");

const notificationType = "scheduled_hike_reminder";
const notificationChannelId = "hike_day_reminders";
const notificationIcon = "ic_stat_summittrack";
const reminderTimeZone = "Asia/Manila";
const processingLeaseMs = 10 * 60 * 1000;
const retryDelayMs = 15 * 60 * 1000;
const maximumAttempts = 3;
const supportedPlatforms = new Set(["android", "ios"]);
const invalidTokenCodes = new Set([
  "messaging/invalid-registration-token",
  "messaging/registration-token-not-registered",
]);
const permanentFailureCodes = new Set([
  ...invalidTokenCodes,
  "messaging/mismatched-credential",
  "messaging/sender-id-mismatch",
  "messaging/third-party-auth-error",
]);

const dateKeyForTimeZone = (date, timeZone = reminderTimeZone) => {
  const formatter = new Intl.DateTimeFormat("en-CA", {
    timeZone,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  });
  const parts = formatter.formatToParts(date).reduce((values, part) => {
    values[part.type] = part.value;
    return values;
  }, {});
  return `${parts.year}-${parts.month}-${parts.day}`;
};

const nextManilaMidnight = (dateKey) => {
  const [year, month, day] = dateKey.split("-").map(Number);
  return new Date(Date.UTC(year, month - 1, day + 1) - 8 * 60 * 60 * 1000);
};

const messageTtlMs = (now, dateKey) => {
  return Math.max(0, nextManilaMidnight(dateKey).getTime() - now.getTime());
};

const notificationEventKey = ({uid, hikeId, deviceId, dateKey}) => {
  return `${uid}|${hikeId}|${dateKey}|${deviceId}`;
};

const notificationJobId = ({uid, hikeId, deviceId, dateKey}) => {
  return `scheduled_hike_${uid}_${hikeId}_${deviceId}_${dateKey}`;
};

const maskedIdentifier = (value) => {
  return crypto.createHash("sha256").update(value).digest("hex").slice(0, 10);
};

const ownerUidFromHikeDocument = (snapshot) => {
  const userReference = snapshot.ref.parent.parent;
  if (!userReference || userReference.parent.id !== "users") {
    return null;
  }
  return userReference.id;
};

const eligibleHike = (hike) => {
  return hike.status === "scheduled" && hike.notificationEnabled === true;
};

const eligibleDevice = (device) => {
  const token = typeof device.fcmToken === "string" ?
    device.fcmToken.trim() :
    "";
  const platform = typeof device.platform === "string" ?
    device.platform.trim().toLowerCase() :
    "";
  const timeZone = typeof device.timezone === "string" ?
    device.timezone.trim() :
    "";

  return device.notificationsEnabled === true &&
    device.tokenStatus === "active" &&
    token !== "" &&
    timeZone !== "" &&
    supportedPlatforms.has(platform);
};

const eligibleAndroidDevice = (device) => {
  const platform = typeof device.platform === "string" ?
    device.platform.trim().toLowerCase() :
    "";
  return platform === "android" && eligibleDevice(device);
};

const safeMountainName = (hike) => {
  const name = typeof hike.mountainName === "string" ?
    hike.mountainName.trim() :
    "";
  return name === "" ? "your scheduled mountain" : name;
};

const buildFcmMessage = (
    {token, uid, hikeId, deviceId, dateKey, hike, now},
) => {
  const mountainName = safeMountainName(hike);
  const eventKey = notificationEventKey({uid, hikeId, deviceId, dateKey});
  const collapseKey = crypto.createHash("sha256")
      .update(eventKey)
      .digest("hex")
      .slice(0, 64);
  const ttl = messageTtlMs(now, dateKey);

  return {
    token,
    notification: {
      title: "Your Hike is Today!",
      body: `Your scheduled hike at ${mountainName} is today. ` +
        "Stay safe and enjoy your hike!",
    },
    data: {
      type: notificationType,
      uid: String(uid),
      hikeId: String(hikeId),
      mountainId: typeof hike.mountainId === "string" ? hike.mountainId : "",
      mountainName,
      dateKey: String(dateKey),
      hikeDateKey: String(dateKey),
      deviceId: String(deviceId),
      eventKey,
      screen: "scheduled_hike_details",
      channelId: notificationChannelId,
    },
    android: {
      priority: "high",
      ttl,
      collapseKey,
      notification: {
        channelId: notificationChannelId,
        icon: notificationIcon,
        sound: "default",
        priority: "high",
        tag: collapseKey,
      },
    },
    apns: {
      headers: {
        "apns-expiration": String(Math.floor((now.getTime() + ttl) / 1000)),
        "apns-collapse-id": collapseKey,
        "apns-push-type": "alert",
        "apns-priority": "10",
      },
      payload: {
        aps: {
          sound: "default",
          category: "SCHEDULED_HIKE_REMINDER",
          threadId: "scheduled-hike-reminders",
        },
      },
    },
  };
};

const isAlreadyExistsError = (error) => {
  return error?.code === 6 || error?.code === "already-exists";
};

const ensurePendingJob = async ({jobReference, job}) => {
  try {
    await jobReference.create({
      uid: job.uid,
      hikeId: job.hikeId,
      deviceId: job.deviceId,
      type: notificationType,
      dateKey: job.dateKey,
      status: "pending",
      attemptCount: 0,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      sentAt: null,
      errorCode: null,
      errorMessage: null,
    });
    return true;
  } catch (error) {
    if (isAlreadyExistsError(error)) {
      return false;
    }
    throw error;
  }
};

const timestampMillis = (value) => {
  return value && typeof value.toMillis === "function" ? value.toMillis() : 0;
};

const reserveJobAttempt = async ({firestore, jobReference, now}) => {
  return firestore.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(jobReference);
    if (!snapshot.exists) {
      return {reserved: false, reason: "missing"};
    }

    const job = snapshot.data() || {};
    const status = job.status;
    const attempts = Number(job.attemptCount || 0);
    const leaseIsActive = status === "processing" &&
      timestampMillis(job.leaseUntil) > now.getTime();
    const retryIsDeferred = status === "failed" &&
      timestampMillis(job.retryAfter) > now.getTime();

    if (status === "sent") {
      return {reserved: false, reason: "sent"};
    }
    if (status === "skipped") {
      return {reserved: false, reason: "skipped"};
    }
    if (leaseIsActive) {
      return {reserved: false, reason: "processing"};
    }
    if (status === "failed" && job.retryable !== true) {
      return {reserved: false, reason: "permanent-failure"};
    }
    if (retryIsDeferred) {
      return {reserved: false, reason: "retry-deferred"};
    }
    if (attempts >= maximumAttempts) {
      return {reserved: false, reason: "attempt-limit"};
    }
    if (!["pending", "processing", "failed"].includes(status)) {
      return {reserved: false, reason: "unsupported-status"};
    }

    transaction.update(jobReference, {
      status: "processing",
      attemptCount: attempts + 1,
      processingStartedAt: admin.firestore.FieldValue.serverTimestamp(),
      leaseUntil: admin.firestore.Timestamp.fromMillis(
          now.getTime() + processingLeaseMs,
      ),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      errorCode: null,
      errorMessage: null,
    });
    return {reserved: true, reason: "reserved", attemptCount: attempts + 1};
  });
};

const invalidTokenFailure = (error) => {
  if (invalidTokenCodes.has(error?.code)) {
    return true;
  }
  if (error?.code !== "messaging/invalid-argument") {
    return false;
  }
  const message = typeof error?.message === "string" ? error.message : "";
  return /registration token|fcm token/i.test(message);
};

const permanentFailure = (error) => {
  return permanentFailureCodes.has(error?.code) || invalidTokenFailure(error);
};

const privacySafeErrorMessage = (error, token) => {
  const raw = typeof error?.message === "string" ?
    error.message :
    "Firebase Messaging send failed.";
  const redacted = token === "" ?
    raw :
    raw.split(token).join("[redacted-token]");
  return redacted.slice(0, 500);
};

const markInvalidDevice = async (deviceReference) => {
  await deviceReference.update({
    notificationsEnabled: false,
    tokenStatus: "invalid",
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
};

const markJobSent = async ({jobReference, messageId}) => {
  await jobReference.update({
    status: "sent",
    sentAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    messageId,
    leaseUntil: admin.firestore.FieldValue.delete(),
    retryAfter: admin.firestore.FieldValue.delete(),
    retryable: admin.firestore.FieldValue.delete(),
    errorCode: null,
    errorMessage: null,
  });
};

const markJobFailed = async ({jobReference, error, token, retryable, now}) => {
  await jobReference.update({
    status: "failed",
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    failedAt: admin.firestore.FieldValue.serverTimestamp(),
    errorCode: typeof error?.code === "string" ? error.code : "unknown",
    errorMessage: privacySafeErrorMessage(error, token),
    retryable,
    retryAfter: retryable ?
      admin.firestore.Timestamp.fromMillis(now.getTime() + retryDelayMs) :
      admin.firestore.FieldValue.delete(),
    leaseUntil: admin.firestore.FieldValue.delete(),
  });
};

const processDevice = async ({
  firestore,
  messaging,
  hikeSnapshot,
  hike,
  uid,
  deviceSnapshot,
  dateKey,
  now,
  stats,
  deviceEligibility = eligibleDevice,
}) => {
  const device = deviceSnapshot.data() || {};
  if (!deviceEligibility(device)) {
    stats.ineligibleDeviceCount++;
    return;
  }

  stats.validTokenCount++;
  const token = device.fcmToken.trim();
  const job = {
    uid,
    hikeId: hikeSnapshot.id,
    deviceId: deviceSnapshot.id,
    dateKey,
  };
  const jobId = notificationJobId(job);
  const jobReference = firestore.collection("notification_jobs").doc(jobId);
  await ensurePendingJob({jobReference, job});
  const reservation = await reserveJobAttempt({
    firestore,
    jobReference,
    now,
  });

  if (!reservation.reserved) {
    stats.duplicateSkipCount++;
    return;
  }
  stats.reservedJobCount++;

  try {
    const messageId = await messaging.send(buildFcmMessage({
      token,
      uid,
      hikeId: hikeSnapshot.id,
      deviceId: deviceSnapshot.id,
      dateKey,
      hike,
      now,
    }));
    await markJobSent({jobReference, messageId});
    stats.sendSuccessCount++;
  } catch (error) {
    stats.sendFailureCount++;
    const tokenIsInvalid = invalidTokenFailure(error);
    const isPermanent = permanentFailure(error);
    if (tokenIsInvalid) {
      await markInvalidDevice(deviceSnapshot.ref);
      stats.invalidTokenCount++;
    }
    await markJobFailed({
      jobReference,
      error,
      token,
      retryable: !isPermanent,
      now,
    });
    logger.error("Scheduled hike FCM send failed.", {
      uidHash: maskedIdentifier(uid),
      hikeIdHash: maskedIdentifier(hikeSnapshot.id),
      deviceIdHash: maskedIdentifier(deviceSnapshot.id),
      errorCode: typeof error?.code === "string" ? error.code : "unknown",
      permanent: isPermanent,
    });
  }
};

const createExecutionSummary = (dateKey) => ({
  candidateDateKeys: [dateKey],
  matchingHikeCount: 0,
  enabledDeviceCount: 0,
  validTokenCount: 0,
  reservedJobCount: 0,
  duplicateSkipCount: 0,
  sendSuccessCount: 0,
  sendFailureCount: 0,
  invalidTokenCount: 0,
  ineligibleDeviceCount: 0,
  filteredHikeCount: 0,
  processingFailureCount: 0,
});

const runScheduledHikeNotifications = async ({
  now = new Date(),
  firestore = admin.firestore(),
  messaging = admin.messaging(),
} = {}) => {
  const dateKey = dateKeyForTimeZone(now);
  const stats = createExecutionSummary(dateKey);
  const hikes = await firestore
      .collectionGroup("scheduled_hikes")
      .where("hikeDateKey", "==", dateKey)
      .get();

  for (const hikeSnapshot of hikes.docs) {
    const hike = hikeSnapshot.data() || {};
    const uid = ownerUidFromHikeDocument(hikeSnapshot);
    if (!uid || !eligibleHike(hike)) {
      stats.filteredHikeCount++;
      continue;
    }
    stats.matchingHikeCount++;

    try {
      const devices = await firestore
          .collection("users")
          .doc(uid)
          .collection("devices")
          .where("notificationsEnabled", "==", true)
          .get();
      stats.enabledDeviceCount += devices.size;

      for (const deviceSnapshot of devices.docs) {
        try {
          await processDevice({
            firestore,
            messaging,
            hikeSnapshot,
            hike,
            uid,
            deviceSnapshot,
            dateKey,
            now,
            stats,
          });
        } catch (error) {
          stats.processingFailureCount++;
          logger.error("Scheduled hike device processing failed.", {
            uidHash: maskedIdentifier(uid),
            hikeIdHash: maskedIdentifier(hikeSnapshot.id),
            deviceIdHash: maskedIdentifier(deviceSnapshot.id),
            errorCode: typeof error?.code === "string" ?
              error.code :
              "unknown",
          });
        }
      }
    } catch (error) {
      stats.processingFailureCount++;
      logger.error("Scheduled hike device query failed.", {
        uidHash: maskedIdentifier(uid),
        hikeIdHash: maskedIdentifier(hikeSnapshot.id),
        errorCode: typeof error?.code === "string" ? error.code : "unknown",
      });
    }
  }

  logger.info("Scheduled hike notification summary.", stats);
  return stats;
};

const runImmediateSameDayScheduledHikeNotification = async ({
  uid,
  hikeId,
  hike,
  now = new Date(),
  firestore = admin.firestore(),
  messaging = admin.messaging(),
} = {}) => {
  const dateKey = dateKeyForTimeZone(now);
  const stats = createExecutionSummary(dateKey);
  stats.triggerType = "immediate_same_day";

  if (!uid || !hikeId || !hike) {
    stats.filteredHikeCount++;
    logger.info("Immediate scheduled hike notification skipped.", {
      ...stats,
      reason: "missing-trigger-data",
    });
    return stats;
  }

  if (hike.hikeDateKey !== dateKey || !eligibleHike(hike)) {
    stats.filteredHikeCount++;
    logger.info("Immediate scheduled hike notification skipped.", {
      ...stats,
      uidHash: maskedIdentifier(uid),
      hikeIdHash: maskedIdentifier(hikeId),
      reason: "not-eligible-for-current-manila-date",
    });
    return stats;
  }

  stats.matchingHikeCount++;
  try {
    const devices = await firestore
        .collection("users")
        .doc(uid)
        .collection("devices")
        .where("notificationsEnabled", "==", true)
        .get();
    stats.enabledDeviceCount += devices.size;

    const hikeSnapshot = {id: hikeId};
    for (const deviceSnapshot of devices.docs) {
      try {
        await processDevice({
          firestore,
          messaging,
          hikeSnapshot,
          hike,
          uid,
          deviceSnapshot,
          dateKey,
          now,
          stats,
          deviceEligibility: eligibleAndroidDevice,
        });
      } catch (error) {
        stats.processingFailureCount++;
        logger.error("Immediate scheduled hike device processing failed.", {
          uidHash: maskedIdentifier(uid),
          hikeIdHash: maskedIdentifier(hikeId),
          deviceIdHash: maskedIdentifier(deviceSnapshot.id),
          errorCode: typeof error?.code === "string" ?
            error.code :
            "unknown",
        });
      }
    }
  } catch (error) {
    stats.processingFailureCount++;
    logger.error("Immediate scheduled hike device query failed.", {
      uidHash: maskedIdentifier(uid),
      hikeIdHash: maskedIdentifier(hikeId),
      errorCode: typeof error?.code === "string" ? error.code : "unknown",
    });
  }

  logger.info("Immediate scheduled hike notification summary.", stats);
  return stats;
};

const sendScheduledHikeNotifications = onSchedule(
    {
      region: "asia-southeast1",
      schedule: "every 1 hours",
      timeZone: reminderTimeZone,
      timeoutSeconds: 540,
      memory: "512MiB",
    },
    async () => runScheduledHikeNotifications(),
);

const sendImmediateSameDayScheduledHikeNotification = onDocumentWritten(
    {
      region: "asia-southeast1",
      document: "users/{uid}/scheduled_hikes/{hikeId}",
      timeoutSeconds: 120,
      memory: "256MiB",
    },
    async (event) => {
      const after = event.data?.after;
      if (!after || !after.exists) {
        return null;
      }

      return runImmediateSameDayScheduledHikeNotification({
        uid: event.params.uid,
        hikeId: event.params.hikeId,
        hike: after.data() || {},
      });
    },
);

module.exports = {
  buildFcmMessage,
  dateKeyForTimeZone,
  eligibleAndroidDevice,
  eligibleDevice,
  eligibleHike,
  invalidTokenFailure,
  notificationEventKey,
  notificationJobId,
  reserveJobAttempt,
  runImmediateSameDayScheduledHikeNotification,
  runScheduledHikeNotifications,
  sendImmediateSameDayScheduledHikeNotification,
  sendScheduledHikeNotifications,
};
