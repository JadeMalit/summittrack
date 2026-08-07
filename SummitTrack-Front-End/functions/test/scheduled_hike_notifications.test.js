const assert = require("node:assert/strict");
const test = require("node:test");

const {
  buildFcmMessage,
  dateKeyForTimeZone,
  eligibleDevice,
  eligibleHike,
  invalidTokenFailure,
  notificationJobId,
  reserveJobAttempt,
  runImmediateSameDayScheduledHikeNotification,
  runScheduledHikeNotifications,
} = require("../scheduled_hike_notifications");

test("uses the Asia/Manila calendar date instead of the UTC date", () => {
  const instant = new Date("2026-08-02T16:15:00.000Z");
  assert.equal(dateKeyForTimeZone(instant), "2026-08-03");
});

test("builds the deterministic notification_jobs document ID", () => {
  assert.equal(
      notificationJobId({
        uid: "user123",
        hikeId: "hike456",
        deviceId: "device789",
        dateKey: "2026-08-03",
      }),
      "scheduled_hike_user123_hike456_device789_2026-08-03",
  );
});

test("requires the complete server-side hike and device eligibility", () => {
  assert.equal(eligibleHike({
    status: "scheduled",
    notificationEnabled: true,
  }), true);
  assert.equal(eligibleHike({
    status: "scheduled",
    notificationEnabled: false,
  }), false);

  const activeDevice = {
    fcmToken: "token-value",
    platform: "android",
    notificationsEnabled: true,
    tokenStatus: "active",
    timezone: "Asia/Manila",
  };
  assert.equal(eligibleDevice(activeDevice), true);
  assert.equal(
      eligibleDevice({...activeDevice, tokenStatus: "disabled"}),
      false,
  );
  assert.equal(eligibleDevice({...activeDevice, fcmToken: ""}), false);
  assert.equal(eligibleDevice({...activeDevice, platform: "web"}), false);
});

test("builds notification and string-only data payloads", () => {
  const message = buildFcmMessage({
    token: "token-value",
    uid: "user123",
    hikeId: "hike456",
    deviceId: "device789",
    dateKey: "2026-08-03",
    hike: {
      mountainId: "mt-pulag",
      mountainName: "Mt. Pulag",
    },
    now: new Date("2026-08-03T01:00:00.000Z"),
  });

  assert.equal(message.notification.title, "Your Hike is Today!");
  assert.equal(message.data.type, "scheduled_hike_reminder");
  assert.equal(message.data.dateKey, "2026-08-03");
  assert.equal(message.data.screen, "scheduled_hike_details");
  assert.equal(message.android.notification.channelId, "hike_day_reminders");
  assert.equal(message.android.notification.icon, "ic_stat_summittrack");
  assert.ok(Object.values(message.data).every((value) => {
    return typeof value === "string";
  }));
});

test("invalid-argument only invalidates an identified token", () => {
  assert.equal(invalidTokenFailure({
    code: "messaging/registration-token-not-registered",
  }), true);
  assert.equal(invalidTokenFailure({
    code: "messaging/invalid-argument",
    message: "The registration token is invalid.",
  }), true);
  assert.equal(invalidTokenFailure({
    code: "messaging/invalid-argument",
    message: "The notification payload is invalid.",
  }), false);
});

test("a processing lease prevents a second real send attempt", async () => {
  const job = {status: "pending", attemptCount: 0};
  const reference = {id: "job-1"};
  const firestore = {
    runTransaction: async (operation) => operation({
      get: async () => ({exists: true, data: () => job}),
      update: (_reference, values) => Object.assign(job, values),
    }),
  };
  const now = new Date("2026-08-03T01:00:00.000Z");

  const first = await reserveJobAttempt({
    firestore,
    jobReference: reference,
    now,
  });
  const second = await reserveJobAttempt({
    firestore,
    jobReference: reference,
    now,
  });

  assert.equal(first.reserved, true);
  assert.equal(first.attemptCount, 1);
  assert.equal(second.reserved, false);
  assert.equal(second.reason, "processing");
  assert.equal(job.attemptCount, 1);
});

const createFakeEnvironment = ({uid, hikeId, hike, devices}) => {
  const jobs = new Map();
  const sentMessages = [];
  const userReference = {
    id: uid,
    parent: {id: "users"},
  };
  const hikeSnapshot = {
    id: hikeId,
    data: () => hike,
    ref: {
      parent: {
        parent: userReference,
      },
    },
  };
  const deviceSnapshots = devices.map((device) => ({
    id: device.id,
    data: () => device.data,
    ref: {
      update: async (values) => Object.assign(device.data, values),
    },
  }));

  const jobReference = (id) => ({
    id,
    create: async (data) => {
      if (jobs.has(id)) {
        const error = new Error("already exists");
        error.code = 6;
        throw error;
      }
      jobs.set(id, {...data});
    },
    update: async (values) => {
      jobs.set(id, {...(jobs.get(id) || {}), ...values});
    },
  });

  const firestore = {
    collection: (name) => {
      if (name === "notification_jobs") {
        return {
          doc: (id) => jobReference(id),
        };
      }
      if (name === "users") {
        return {
          doc: (requestedUid) => ({
            collection: (collectionName) => {
              assert.equal(requestedUid, uid);
              assert.equal(collectionName, "devices");
              return {
                where: (field, operator, value) => {
                  assert.equal(field, "notificationsEnabled");
                  assert.equal(operator, "==");
                  assert.equal(value, true);
                  const docs = deviceSnapshots.filter((snapshot) => {
                    return snapshot.data().notificationsEnabled === true;
                  });
                  return {
                    get: async () => ({size: docs.length, docs}),
                  };
                },
              };
            },
          }),
        };
      }
      throw new Error(`Unexpected collection ${name}`);
    },
    collectionGroup: (name) => {
      assert.equal(name, "scheduled_hikes");
      return {
        where: (field, operator, value) => {
          assert.equal(field, "hikeDateKey");
          assert.equal(operator, "==");
          const docs = hike.hikeDateKey === value ? [hikeSnapshot] : [];
          return {
            get: async () => ({docs}),
          };
        },
      };
    },
    runTransaction: async (operation) => {
      return operation({
        get: async (reference) => ({
          exists: jobs.has(reference.id),
          data: () => jobs.get(reference.id),
        }),
        update: (reference, values) => {
          jobs.set(reference.id, {
            ...(jobs.get(reference.id) || {}),
            ...values,
          });
        },
      });
    },
  };
  const messaging = {
    send: async (message) => {
      sentMessages.push(message);
      return `message-${sentMessages.length}`;
    },
  };

  return {firestore, jobs, messaging, sentMessages};
};

test("immediate same-day trigger creates a deterministic job", async () => {
  const uid = "user123";
  const hikeId = "hike456";
  const deviceId = "device789";
  const hike = {
    mountainId: "mt-apo",
    mountainName: "Mt. Apo",
    hikeDateKey: "2026-08-06",
    status: "scheduled",
    notificationEnabled: true,
  };
  const env = createFakeEnvironment({
    uid,
    hikeId,
    hike,
    devices: [{
      id: deviceId,
      data: {
        fcmToken: "token-value",
        platform: "android",
        notificationsEnabled: true,
        tokenStatus: "active",
        timezone: "Asia/Manila",
      },
    }],
  });

  const stats = await runImmediateSameDayScheduledHikeNotification({
    uid,
    hikeId,
    hike,
    now: new Date("2026-08-06T01:00:00.000Z"),
    firestore: env.firestore,
    messaging: env.messaging,
  });

  const jobId = notificationJobId({
    uid,
    hikeId,
    deviceId,
    dateKey: "2026-08-06",
  });
  assert.equal(stats.sendSuccessCount, 1);
  assert.equal(env.sentMessages.length, 1);
  assert.equal(env.jobs.get(jobId).status, "sent");
});

test("future hike does not send immediately", async () => {
  const env = createFakeEnvironment({
    uid: "user123",
    hikeId: "hike456",
    hike: {
      hikeDateKey: "2026-08-07",
      status: "scheduled",
      notificationEnabled: true,
    },
    devices: [],
  });

  const stats = await runImmediateSameDayScheduledHikeNotification({
    uid: "user123",
    hikeId: "hike456",
    hike: {
      hikeDateKey: "2026-08-07",
      status: "scheduled",
      notificationEnabled: true,
    },
    now: new Date("2026-08-06T01:00:00.000Z"),
    firestore: env.firestore,
    messaging: env.messaging,
  });

  assert.equal(stats.filteredHikeCount, 1);
  assert.equal(env.sentMessages.length, 0);
  assert.equal(env.jobs.size, 0);
});

test("disabled hike notification does not send immediately", async () => {
  const hike = {
    hikeDateKey: "2026-08-06",
    status: "scheduled",
    notificationEnabled: false,
  };
  const env = createFakeEnvironment({
    uid: "user123",
    hikeId: "hike456",
    hike,
    devices: [],
  });

  const stats = await runImmediateSameDayScheduledHikeNotification({
    uid: "user123",
    hikeId: "hike456",
    hike,
    now: new Date("2026-08-06T01:00:00.000Z"),
    firestore: env.firestore,
    messaging: env.messaging,
  });

  assert.equal(stats.filteredHikeCount, 1);
  assert.equal(env.sentMessages.length, 0);
  assert.equal(env.jobs.size, 0);
});

test("hourly scheduler skips a job sent by the immediate trigger", async () => {
  const uid = "user123";
  const hikeId = "hike456";
  const deviceId = "device789";
  const hike = {
    mountainId: "mt-apo",
    mountainName: "Mt. Apo",
    hikeDateKey: "2026-08-06",
    status: "scheduled",
    notificationEnabled: true,
  };
  const env = createFakeEnvironment({
    uid,
    hikeId,
    hike,
    devices: [{
      id: deviceId,
      data: {
        fcmToken: "token-value",
        platform: "android",
        notificationsEnabled: true,
        tokenStatus: "active",
        timezone: "Asia/Manila",
      },
    }],
  });
  const now = new Date("2026-08-06T01:00:00.000Z");

  await runImmediateSameDayScheduledHikeNotification({
    uid,
    hikeId,
    hike,
    now,
    firestore: env.firestore,
    messaging: env.messaging,
  });
  env.sentMessages.length = 0;

  const stats = await runScheduledHikeNotifications({
    now,
    firestore: env.firestore,
    messaging: env.messaging,
  });

  assert.equal(stats.duplicateSkipCount, 1);
  assert.equal(stats.sendSuccessCount, 0);
  assert.equal(env.sentMessages.length, 0);
});
