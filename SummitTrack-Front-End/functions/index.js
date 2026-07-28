const {HttpsError, onCall, onRequest} =
  require("firebase-functions/v2/https");
const {onSchedule} =
  require("firebase-functions/v2/scheduler");
const {defineSecret} =
  require("firebase-functions/params");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");
const crypto = require("crypto");
const cors = require("cors")({origin: true});

admin.initializeApp();

const graphHopperApiKey =
  defineSecret("GRAPHHOPPER_API_KEY");

const allowedGraphHopperProfiles = new Set(["foot", "hike"]);
const defaultGraphHopperProfile = "hike";

const buildOpenWeatherUrl = (lat, lon, apiKey) => {
  const url = new URL("https://api.openweathermap.org/data/2.5/weather");
  url.searchParams.set("lat", lat);
  url.searchParams.set("lon", lon);
  url.searchParams.set("appid", apiKey);
  url.searchParams.set("units", "metric");
  return url.toString();
};

const buildOpenMeteoUrl = (lat, lon) => {
  const url = new URL("https://api.open-meteo.com/v1/forecast");
  url.searchParams.set("latitude", lat);
  url.searchParams.set("longitude", lon);
  url.searchParams.set(
      "daily",
      [
        "weather_code",
        "temperature_2m_max",
        "temperature_2m_min",
        "precipitation_probability_max",
      ].join(","),
  );
  url.searchParams.set("timezone", "auto");
  url.searchParams.set("forecast_days", "15");
  return url.toString();
};

const buildForecast = (daily) => {
  const forecastTimes = Array.isArray(daily?.time) ? daily.time : [];

  return forecastTimes.map((date, index) => {
    return {
      date,
      "temp_max": Math.round(daily?.["temperature_2m_max"]?.[index] || 0),
      "temp_min": Math.round(daily?.["temperature_2m_min"]?.[index] || 0),
      "rain_chance": daily?.["precipitation_probability_max"]?.[index] || 0,
      "weather_code": daily?.["weather_code"]?.[index] || 0,
    };
  });
};

const hikeNotificationChannelId = "hike_day_reminders";
const hikeNotificationType = "scheduled_hike_today";
const notificationJobReserveMs = 10 * 60 * 1000;
const invalidFcmTokenCodes = new Set([
  "messaging/invalid-registration-token",
  "messaging/registration-token-not-registered",
]);
const permanentFcmFailureCodes = new Set([
  ...invalidFcmTokenCodes,
  "messaging/invalid-argument",
  "messaging/mismatched-credential",
  "messaging/sender-id-mismatch",
  "messaging/third-party-auth-error",
]);

const dateKeyUtc = (date) => {
  return date.toISOString().slice(0, 10);
};

const addUtcDays = (dateKey, days) => {
  const [year, month, day] = dateKey.split("-").map(Number);
  return dateKeyUtc(new Date(Date.UTC(year, month - 1, day + days)));
};

const possibleDeviceDateKeys = (now) => {
  const utcToday = dateKeyUtc(now);
  return [
    addUtcDays(utcToday, -1),
    utcToday,
    addUtcDays(utcToday, 1),
  ];
};

const localDateKeyForTimeZone = (timeZone, date) => {
  try {
    const formatter = new Intl.DateTimeFormat("en", {
      timeZone,
      year: "numeric",
      month: "2-digit",
      day: "2-digit",
    });
    const parts = formatter.formatToParts(date).reduce((values, part) => {
      values[part.type] = part.value;
      return values;
    }, {});

    if (parts.year && parts.month && parts.day) {
      return `${parts.year}-${parts.month}-${parts.day}`;
    }
  } catch {
    return null;
  }

  return null;
};

const nextLocalMidnightMillis = (timeZone, hikeDateKey, now) => {
  const nextDateKey = addUtcDays(hikeDateKey, 1);
  let low = now.getTime();
  let high = low + 36 * 60 * 60 * 1000;

  while (high - low > 1000) {
    const midpoint = Math.floor((low + high) / 2);
    const midpointKey = localDateKeyForTimeZone(
        timeZone,
        new Date(midpoint),
    );

    if (midpointKey >= nextDateKey) {
      high = midpoint;
    } else {
      low = midpoint + 1;
    }
  }

  return high;
};

const ttlForDeviceDate = (timeZone, hikeDateKey, now) => {
  const expirationMillis = nextLocalMidnightMillis(
      timeZone,
      hikeDateKey,
      now,
  );
  const ttlSeconds = Math.floor((expirationMillis - now.getTime()) / 1000);
  return {
    ttlSeconds: Math.max(0, ttlSeconds),
    expirationSeconds: Math.floor(expirationMillis / 1000),
  };
};

const isScheduledOrActiveHike = (hike) => {
  if (hike?.deletedAt || hike?.isDeleted === true) {
    return false;
  }

  const status = typeof hike?.status === "string" ?
    hike.status.trim().toLowerCase() :
    "";

  return status === "" ||
    status === "scheduled" ||
    status === "active";
};

const ownerUidFromHikeDoc = (snapshot) => {
  const userRef = snapshot.ref.parent.parent;
  if (!userRef || userRef.parent.id !== "users") {
    return null;
  }

  const data = snapshot.data() || {};
  const storedUid = typeof data.ownerUid === "string" ?
    data.ownerUid :
    data.userId;

  if (typeof storedUid === "string" && storedUid.trim() !== userRef.id) {
    return null;
  }

  return userRef.id;
};

const notificationEventKey = ({uid, hikeId, hikeDateKey, deviceId}) => {
  return `${uid}|${hikeId}|${hikeDateKey}|${deviceId}`;
};

const notificationEventDocumentId = (eventKey) => {
  return crypto.createHash("sha256").update(eventKey).digest("hex");
};

const safeJobId = (eventKey) => notificationEventDocumentId(eventKey);

const safeMountainName = (hike) => {
  const mountainName = typeof hike?.mountainName === "string" ?
    hike.mountainName.trim() :
    "";

  return mountainName === "" || mountainName.toLowerCase() === "unknown" ?
    "your scheduled mountain" :
    mountainName;
};

const reserveNotificationJob = async ({jobRef, uid, hikeId, hikeDateKey,
  deviceId, eventKey, now}) => {
  const reservedUntilMillis = now.getTime() + notificationJobReserveMs;

  return admin.firestore().runTransaction(async (transaction) => {
    const snapshot = await transaction.get(jobRef);
    const data = snapshot.exists ? snapshot.data() : {};

    if (
      data?.sent === true ||
      data?.status === "sent" ||
      data?.status === "permanent-failure"
    ) {
      return false;
    }

    if (
      data?.status === "reserved" &&
      Number(data?.reservedUntilMillis || 0) > now.getTime()
    ) {
      return false;
    }

    transaction.set(jobRef, {
      uid,
      hikeId,
      hikeDateKey,
      deviceId,
      eventKey,
      status: "reserved",
      sent: false,
      reservedUntilMillis,
      attempts: Number(data?.attempts || 0) + 1,
      reservedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, {merge: true});

    return true;
  });
};

const buildHikeMessage = ({token, uid, hikeId, hikeDateKey, hike,
  deviceId, eventKey, timeZone, now}) => {
  const mountainName = safeMountainName(hike);
  const expiration = ttlForDeviceDate(timeZone, hikeDateKey, now);
  const collapseId = notificationEventDocumentId(eventKey).slice(0, 64);
  const payload = {
    type: hikeNotificationType,
    uid,
    hikeId,
    hikeDateKey,
    mountainId: typeof hike?.mountainId === "string" ? hike.mountainId : "",
    mountainName,
    deviceId,
    eventKey,
    channelId: hikeNotificationChannelId,
  };

  return {
    token,
    data: payload,
    android: {
      ttl: expiration.ttlSeconds * 1000,
      collapseKey: collapseId,
      priority: "high",
    },
    apns: {
      headers: {
        "apns-expiration": String(expiration.expirationSeconds),
        "apns-collapse-id": collapseId,
        "apns-push-type": "background",
        "apns-priority": "5",
      },
      payload: {
        aps: {
          "contentAvailable": true,
        },
      },
    },
  };
};

const markInvalidDeviceToken = async (deviceRef) => {
  await deviceRef.set({
    fcmToken: admin.firestore.FieldValue.delete(),
    notificationsEnabled: false,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, {merge: true});
};

const isConfirmedLocalSchedule = ({eventData, eventKey, hikeDateKey, now}) => {
  if (
    eventData?.eventKey !== eventKey ||
    eventData?.hikeDateKey !== hikeDateKey ||
    eventData?.localScheduleConfirmed !== true ||
    Number(eventData?.expiresAtMillis || 0) <= now.getTime()
  ) {
    return false;
  }

  return eventData?.status === "scheduled" ||
    eventData?.status === "displayed" ||
    eventData?.status === "claiming";
};

const processHikeNotificationForDevice = async ({hikeSnapshot, hike,
  uid, deviceSnapshot, now, stats}) => {
  const device = deviceSnapshot.data() || {};
  const token = typeof device.fcmToken === "string" ?
    device.fcmToken.trim() :
    "";
  const timeZone = typeof device.timezone === "string" ?
    device.timezone.trim() :
    "";
  const hikeDateKey = typeof hike.hikeDateKey === "string" ?
    hike.hikeDateKey :
    "";

  if (!token || hikeDateKey === "") {
    return;
  }
  stats.validTokenCount++;

  const localDateKey = localDateKeyForTimeZone(timeZone, now);
  if (localDateKey === null) {
    stats.temporaryFailureCount++;
    return;
  }
  if (localDateKey !== hikeDateKey) {
    if (hikeDateKey < localDateKey) {
      stats.expiredSkipCount++;
    }
    return;
  }

  const expiration = ttlForDeviceDate(timeZone, hikeDateKey, now);
  if (expiration.ttlSeconds <= 0) {
    stats.expiredSkipCount++;
    return;
  }

  const eventKey = notificationEventKey({
    uid,
    hikeId: hikeSnapshot.id,
    hikeDateKey,
    deviceId: deviceSnapshot.id,
  });
  const eventSnapshot = await deviceSnapshot.ref
      .collection("notificationEvents")
      .doc(notificationEventDocumentId(eventKey))
      .get();
  if (isConfirmedLocalSchedule({
    eventData: eventSnapshot.data(),
    eventKey,
    hikeDateKey,
    now,
  })) {
    stats.localScheduleConfirmedCount++;
    stats.duplicateSkipCount++;
    return;
  }

  const jobRef = admin.firestore()
      .collection("notificationJobs")
      .doc(safeJobId(eventKey));
  const reserved = await reserveNotificationJob({
    jobRef,
    uid,
    hikeId: hikeSnapshot.id,
    hikeDateKey,
    deviceId: deviceSnapshot.id,
    eventKey,
    now,
  });

  if (!reserved) {
    stats.duplicateSkipCount++;
    return;
  }
  stats.reservedJobCount++;
  stats.fallbackSendCount++;

  try {
    const messageId = await admin.messaging().send(buildHikeMessage({
      token,
      uid,
      hikeId: hikeSnapshot.id,
      hikeDateKey,
      hike,
      deviceId: deviceSnapshot.id,
      eventKey,
      timeZone,
      now,
    }));

    await jobRef.set({
      status: "sent",
      sent: true,
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      messageId,
    }, {merge: true});
    stats.sendSuccessCount++;
  } catch (error) {
    const code = typeof error?.code === "string" ? error.code : "unknown";
    const invalidToken = invalidFcmTokenCodes.has(code);
    const permanentFailure = permanentFcmFailureCodes.has(code);
    if (invalidToken) {
      await markInvalidDeviceToken(deviceSnapshot.ref);
    }

    await jobRef.set({
      status: permanentFailure ? "permanent-failure" : "retryable",
      sent: false,
      errorCode: code,
      reservedUntilMillis: 0,
      failedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, {merge: true});
    if (permanentFailure) {
      stats.permanentFailureCount++;
    } else {
      stats.temporaryFailureCount++;
    }
  }
};

exports.sendScheduledHikeNotifications = onSchedule(
    {
      region: "asia-southeast1",
      schedule: "every 1 hours",
      timeZone: "UTC",
      timeoutSeconds: 540,
      memory: "512MiB",
    },
    async () => {
      const now = new Date();
      const dateKeys = possibleDeviceDateKeys(now);
      const firestore = admin.firestore();
      const stats = {
        candidateDateKeys: dateKeys,
        matchingHikeCount: 0,
        enabledDeviceCount: 0,
        validTokenCount: 0,
        localScheduleConfirmedCount: 0,
        fallbackSendCount: 0,
        reservedJobCount: 0,
        sendSuccessCount: 0,
        permanentFailureCount: 0,
        temporaryFailureCount: 0,
        duplicateSkipCount: 0,
        expiredSkipCount: 0,
      };

      const hikeSnapshots = await Promise.all(dateKeys.map((dateKey) => {
        return firestore
            .collectionGroup("scheduled_hikes")
            .where("hikeDateKey", "==", dateKey)
            .get();
      }));

      for (const querySnapshot of hikeSnapshots) {
        stats.matchingHikeCount += querySnapshot.size;
        for (const hikeSnapshot of querySnapshot.docs) {
          const hike = hikeSnapshot.data() || {};
          const uid = ownerUidFromHikeDoc(hikeSnapshot);

          if (!uid || !isScheduledOrActiveHike(hike)) {
            continue;
          }

          const devicesSnapshot = await firestore
              .collection("users")
              .doc(uid)
              .collection("devices")
              .where("notificationsEnabled", "==", true)
              .get();
          stats.enabledDeviceCount += devicesSnapshot.size;

          for (const deviceSnapshot of devicesSnapshot.docs) {
            try {
              await processHikeNotificationForDevice({
                hikeSnapshot,
                hike,
                uid,
                deviceSnapshot,
                now,
                stats,
              });
            } catch {
              stats.temporaryFailureCount++;
            }
          }
        }
      }
      logger.info("Scheduled hike notification summary.", stats);
    },
);

exports.getSummitTrackWeather = onRequest((req, res) => {
  cors(req, res, async () => {
    try {
      const {lat, lon} = req.query;

      if (!lat || !lon) {
        return res.status(400).json({
          error: "Missing lat or lon parameters.",
        });
      }

      const openWeatherApiKey = process.env.OPENWEATHER_API_KEY;

      if (!openWeatherApiKey) {
        return res.status(500).json({
          error: "Server configuration error: OpenWeather API Key is missing.",
        });
      }

      const openWeatherResponse = await fetch(
          buildOpenWeatherUrl(lat, lon, openWeatherApiKey),
      );
      const currentData = await openWeatherResponse.json();

      const openMeteoResponse = await fetch(buildOpenMeteoUrl(lat, lon));
      const forecastData = await openMeteoResponse.json();

      const combinedResponse = {
        current: {
          temp: Math.round(currentData.main?.temp || 0),
          condition: currentData.weather?.[0]?.main || "Unknown",
          description: currentData.weather?.[0]?.description || "",
          humidity: currentData.main?.humidity || 0,
          wind_speed: currentData.wind?.speed || 0,
          location_name: currentData.name || "Unknown Mountain",
        },
        forecast: buildForecast(forecastData.daily),
      };

      return res.status(200).json(combinedResponse);
    } catch (error) {
      logger.error("Weather Sync Error!", error);
      return res.status(500).json({
        error: "May sumabog sa server side, boss!",
        details: error.message,
      });
    }
  });
});

const isValidLatitude = (value) => {
  return Number.isFinite(value) &&
    value >= -90 &&
    value <= 90;
};

const isValidLongitude = (value) => {
  return Number.isFinite(value) &&
    value >= -180 &&
    value <= 180;
};

const graphHopperPointToCoordinate = (point) => {
  if (!Array.isArray(point) || point.length < 2) {
    return null;
  }

  const longitude = Number(point[0]);
  const latitude = Number(point[1]);
  if (!isValidLatitude(latitude) || !isValidLongitude(longitude)) {
    return null;
  }

  return {latitude, longitude};
};

const distanceMeters = (from, to) => {
  const earthRadiusMeters = 6371000;
  const toRadians = (degrees) => degrees * Math.PI / 180;
  const lat1 = toRadians(from.latitude);
  const lat2 = toRadians(to.latitude);
  const deltaLat = toRadians(to.latitude - from.latitude);
  const deltaLng = toRadians(to.longitude - from.longitude);

  const a =
    Math.sin(deltaLat / 2) * Math.sin(deltaLat / 2) +
    Math.cos(lat1) *
      Math.cos(lat2) *
      Math.sin(deltaLng / 2) *
      Math.sin(deltaLng / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return earthRadiusMeters * c;
};

const responseDiagnostics = (routeData, destination) => {
  const firstPath = routeData && Array.isArray(routeData.paths) ?
    routeData.paths[0] :
    null;
  const rawCoordinates = firstPath &&
    firstPath.points &&
    Array.isArray(firstPath.points.coordinates) ?
    firstPath.points.coordinates :
    [];

  const returnedFirstRoutePoint =
    graphHopperPointToCoordinate(rawCoordinates[0]);
  const returnedLastRoutePoint =
    graphHopperPointToCoordinate(rawCoordinates[rawCoordinates.length - 1]);

  return {
    returnedFirstRoutePoint,
    returnedLastRoutePoint,
    endpointToDestinationDistanceMeters: returnedLastRoutePoint ?
      distanceMeters(returnedLastRoutePoint, destination) :
      null,
  };
};

const buildGraphHopperUrl = (query) => {
  const url = new URL("https://graphhopper.com/api/1/route");
  url.search = query.toString();
  return url.toString();
};

exports.getGraphHopperRoute = onCall(
    {
      region: "asia-southeast1",
      secrets: [graphHopperApiKey],
      timeoutSeconds: 30,
      memory: "256MiB",
      maxInstances: 10,
    },
    async (request) => {
      if (!request.auth) {
        throw new HttpsError(
            "unauthenticated",
            "You must be signed in to request a route.",
        );
      }

      const data = request.data || {};

      const startLat = Number(data.startLat);
      const startLng = Number(data.startLng);
      const endLat = Number(data.endLat);
      const endLng = Number(data.endLng);
      const requestedProfile = typeof data.profile === "string" ?
        data.profile.trim() :
        "";
      const profile = requestedProfile || defaultGraphHopperProfile;

      if (
        !isValidLatitude(startLat) ||
        !isValidLongitude(startLng) ||
        !isValidLatitude(endLat) ||
        !isValidLongitude(endLng)
      ) {
        throw new HttpsError(
            "invalid-argument",
            "Valid start and destination coordinates are required.",
        );
      }

      if (!allowedGraphHopperProfiles.has(profile)) {
        throw new HttpsError(
            "invalid-argument",
            "The requested routing profile is not supported.",
        );
      }

      logger.info("GraphHopper route request diagnostics.", {
        profile,
        startLat,
        startLng,
        endLat,
        endLng,
      });

      const query = new URLSearchParams();
      query.append("point", `${startLat},${startLng}`);
      query.append("point", `${endLat},${endLng}`);
      query.set("profile", profile);
      query.set("locale", "en");
      query.set("instructions", "true");
      query.set("calc_points", "true");
      query.set("points_encoded", "false");
      query.set("key", graphHopperApiKey.value());

      try {
        const response = await fetch(
            buildGraphHopperUrl(query),
            {
              method: "GET",
              headers: {
                "Accept": "application/json",
              },
              signal: AbortSignal.timeout(20000),
            },
        );

        const responseText = await response.text();
        let routeData;

        try {
          routeData = JSON.parse(responseText);
        } catch (parseError) {
          routeData = {};
        }

        if (!response.ok) {
          logger.error("GraphHopper request failed.", {
            status: response.status,
            uid: request.auth.uid,
          });

          throw new HttpsError(
              "unavailable",
              "The route service is currently unavailable.",
          );
        }

        logger.info("GraphHopper route response diagnostics.", {
          profile,
          startLat,
          startLng,
          endLat,
          endLng,
          ...responseDiagnostics(routeData, {
            latitude: endLat,
            longitude: endLng,
          }),
        });

        return routeData;
      } catch (error) {
        if (error instanceof HttpsError) {
          throw error;
        }

        logger.error("Unexpected routing error.", {
          message: error instanceof Error ?
            error.message :
            "Unknown error",
          uid: request.auth.uid,
        });

        throw new HttpsError(
            "internal",
            "Unable to calculate the route.",
        );
      }
    },
);
