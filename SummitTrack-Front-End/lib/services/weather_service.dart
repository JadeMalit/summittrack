import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  static const apiKey = "19985b4c77467b7032a49fd008575e80";

  // Inayos ang mga lokasyon para maging mas kilala sa OpenWeatherMap API
  static const Map<String, String> mountainLocations = {
    "Mount Ulap": "Itogon,PH",
    "Mount Manabu": "Lipas,PH",
    "Mount Gulugod Baboy": "Anilao,PH",
    "Mount Maynoba": "Antipolo,PH",
    "Mount Cutuno": "Angeles,PH",
    "Mount Lingguhob": "Iloilo City,PH",
    "Mount Batulao": "Nasugbu,PH",
    "Mount Daraitan": "Tanay,PH",
    "Mount Arayat": "Arayat,PH",
    "Mount Makiling": "Los Banos,PH",
    "Mount Damas": "Tarlac City,PH",
    "Mount Tugew": "Nueva Vizcaya,PH",
    "Mount Mariglem": "Zambales,PH",
    "Mount Pinatubo": "Capas,PH",
    "Mount Pulag": "Kabayan,PH",
    "Mount Apo": "Davao City,PH",
    "Mount Tapulao": "Iba,PH",
    "Mount Espadang Bato": "Rodriguez,PH",
    "Mount Hibok-Hibok": "Mambajao,PH",
    "Mount Kitanglad": "Malaybalay,PH",
  };

  Future<Map<String, dynamic>> getWeather(String mountainName) async {
    final String queryLocation = mountainLocations[mountainName] ?? "Manila,PH";

    final url =
        "https://api.openweathermap.org/data/2.5/weather?q=$queryLocation&appid=$apiKey&units=metric";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return {
        "location": {"name": data["name"]},
        "current": {
          "temp_c": data["main"]["temp"],
          "humidity": data["main"]["humidity"],
          "wind_kph": (data["wind"]["speed"] * 3.6).toStringAsFixed(1),
          "condition": {"text": data["weather"][0]["description"]},
        },
        "forecast": {
          "forecastday": [
            {
              "day": {"daily_chance_of_rain": data["clouds"]["all"]},
            },
          ],
        },
      };
    }

    // Binago para ibalik ang mas malinis na error message
    throw Exception(
      "City/Mountain info not found in API. (Code: ${response.statusCode})",
    );
  }
}
