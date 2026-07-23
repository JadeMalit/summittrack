const {HttpsError, onCall, onRequest} =
  require("firebase-functions/v2/https");
const {defineSecret} =
  require("firebase-functions/params");
const logger = require("firebase-functions/logger");
const cors = require("cors")({origin: true});

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
