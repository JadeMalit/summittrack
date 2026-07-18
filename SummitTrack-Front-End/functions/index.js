const { onRequest } = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const cors = require("cors")({ origin: true });

exports.getSummitTrackWeather = onRequest((req, res) => {
  // Pinapayagan nito ang Flutter app mo (kahit sa Web/Emulator) na makatawag dito nang walang CORS error
  cors(req, res, async () => {
    try {
      // 1. Kunin ang latitude at longitude na ipapasa ng Flutter app mo (e.g. galing sa GPS o napiling bundok)
      const { lat, lon } = req.query;

      if (!lat || !lon) {
        return res.status(400).json({ error: "Missing lat or lon parameters. Kailangan ng coordinate, boss!" });
      }

      // ⚠️ PAALALA: Palitan mo ito ng sarili mong totoong OpenWeather API Key mamaya
      const OPENWEATHER_API_KEY = "19985b4c77467b7032a49fd008575e80";

      // 2. TAWAGIN SI OPENWEATHER (Para sa Current Weather sa itaas ng UI mo)
      const openWeatherUrl = `https://api.openweathermap.org/data/2.5/weather?lat=${lat}&lon=${lon}&appid=${OPENWEATHER_API_KEY}&units=metric`;
      const openWeatherResponse = await fetch(openWeatherUrl);
      const currentData = await openWeatherResponse.json();

      // 3. TAWAGIN SI OPEN-METEO (Para sa 15-Day Forecast sa ilalim ng UI mo - 100% LIBRE!)
      const openMeteoUrl = `https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max&timezone=auto&forecast_days=15`;
      const openMeteoResponse = await fetch(openMeteoUrl);
      const forecastData = await openMeteoResponse.json();

      // 4. MIX & MATCH (Pagsamahin ang data para isang bagsakang pasa lang sa Flutter)
      const combinedResponse = {
        // Data para sa malaking Weather card mo sa itaas
        current: {
          temp: Math.round(currentData.main?.temp || 0),
          condition: currentData.weather?.[0]?.main || "Unknown",
          description: currentData.weather?.[0]?.description || "",
          humidity: currentData.main?.humidity || 0,
          wind_speed: currentData.wind?.speed || 0,
          location_name: currentData.name || "Unknown Mountain",
        },
        // Data para sa 15-day scrollable list sa ibaba
        forecast: forecastData.daily?.time.map((date, index) => {
          return {
            date: date, // Format: YYYY-MM-DD
            temp_max: Math.round(forecastData.daily?.temperature_2m_max?.[index] || 0),
            temp_min: Math.round(forecastData.daily?.temperature_2m_min?.[index] || 0),
            rain_chance: forecastData.daily?.precipitation_probability_max?.[index] || 0,
            weather_code: forecastData.daily?.weather_code?.[index] || 0, // Gagamitin natin para sa Icons mamaya
          };
        }) || []
      };

      // Ibalik ang malinis at pinagsamang data sa Flutter
      return res.status(200).json(combinedResponse);

    } catch (error) {
      logger.error("Weather Sync Error!", error);
      return res.status(500).json({ error: "May sumabog sa server side, boss!", details: error.message });
    }
  });
});