const { onRequest } = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const cors = require("cors")({ origin: true });

exports.getSummitTrackWeather = onRequest((req, res) => {
  // Pinapayagan nito ang Flutter app mo na makatawag dito nang walang CORS error
  cors(req, res, async () => {
    try {
      const { lat, lon } = req.query;

      if (!lat || !lon) {
        return res.status(400).json({ error: "Missing lat or lon parameters. Kailangan ng coordinate, boss!" });
      }

      // 🔒 SECURE WAY: Kukunin ang API Key mula sa Environment Variable (Hindi na nakalantad)
      const OPENWEATHER_API_KEY = process.env.OPENWEATHER_API_KEY;

      if (!OPENWEATHER_API_KEY) {
        return res.status(500).json({ error: "Server configuration error: OpenWeather API Key is missing." });
      }

      // 2. TAWAGIN SI OPENWEATHER (Para sa Current Weather)
      const openWeatherUrl = `https://api.openweathermap.org/data/2.5/weather?lat=${lat}&lon=${lon}&appid=${OPENWEATHER_API_KEY}&units=metric`;
      const openWeatherResponse = await fetch(openWeatherUrl);
      const currentData = await openWeatherResponse.json();

      // 3. TAWAGIN SI OPEN-METEO (Para sa 15-Day Forecast)
      const openMeteoUrl = `https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max&timezone=auto&forecast_days=15`;
      const openMeteoResponse = await fetch(openMeteoUrl);
      const forecastData = await openMeteoResponse.json();

      // 4. MIX & MATCH (Pagsamahin ang data)
      const combinedResponse = {
        current: {
          temp: Math.round(currentData.main?.temp || 0),
          condition: currentData.weather?.[0]?.main || "Unknown",
          description: currentData.weather?.[0]?.description || "",
          humidity: currentData.main?.humidity || 0,
          wind_speed: currentData.wind?.speed || 0,
          location_name: currentData.name || "Unknown Mountain",
        },
        forecast: forecastData.daily?.time.map((date, index) => {
          return {
            date: date,
            temp_max: Math.round(forecastData.daily?.temperature_2m_max?.[index] || 0),
            temp_min: Math.round(forecastData.daily?.temperature_2m_min?.[index] || 0),
            rain_chance: forecastData.daily?.precipitation_probability_max?.[index] || 0,
            weather_code: forecastData.daily?.weather_code?.[index] || 0,
          };
        }) || []
      };

      return res.status(200).json(combinedResponse);

    } catch (error) {
      logger.error("Weather Sync Error!", error);
      return res.status(500).json({ error: "May sumabog sa server side, boss!", details: error.message });
    }
  });
});