import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  /// 🌐 LIVE PRODUCTION URL (Gumagana sa Web, Android, at iOS nang walang emulator)
  static String get _baseUrl =>
      'https://us-central1-summittrack-10481.cloudfunctions.net/getSummitTrackWeather';

  // 🗺️ Dictionary ng Coordinates para sa panloob na pag-map ng mga bundok kapag String ang ipinasa
  final Map<String, List<double>> _mountainCoordinates = {
    "Mount Apo": [6.9872, 125.3708],
    "Mount Pulag": [16.5983, 120.8986],
    "Mount Ulap": [16.2917, 120.6358],
    "Mount Manabu": [13.9782, 121.2215],
    "Mount Gulugod Baboy": [13.7119, 120.8988],
    "Mount Maynoba": [14.6333, 121.3167],
    "Mount Batulao": [14.0411, 120.8014],
    "Mount Daraitan": [14.6139, 121.4331],
    "Mount Arayat": [15.2011, 120.7422],
    "Mount Makiling": [14.1308, 121.1925],
    "Mount Pinatubo": [15.1428, 120.3506],
  };

  /// 🚀 PARA SA MGA BAGONG SCREENS (Gaya ng WeatherScreen)
  /// Kukuha ng 15-day forecast gamit ang lat/lon positional parameters
  Future<Map<String, dynamic>> fetch15DayWeather(double lat, double lon) async {
    try {
      final url = Uri.parse('$_baseUrl?lat=$lat&lon=$lon');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Server returned status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch mountain weather: $e');
    }
  }

  /// 🟢 PARA SA MGA LUMANG SCREENS (Eksakto para sa HikeNavigationConfirmation niyo)
  /// Tinitiyak nito na tumanggap siya ng 1 Positional Argument (mountainName String)
  /// at isasalin ang JSON response sa lumang format (temp_c, condition text) para walang mabago sa screen mo.
  Future<Map<String, dynamic>> getWeather(dynamic mountainName) async {
    try {
      final nameStr = mountainName.toString();
      final coords = _mountainCoordinates[nameStr] ?? [6.9872, 125.3708];

      // Tawagin ang totoong backend gamit ang coordinates map
      final newData = await fetch15DayWeather(coords[0], coords[1]);

      final current = newData['current'] ?? {};
      final conditionText = current['condition'] ?? 'Clear';
      final tempValue = current['temp'] ?? 25;

      // Isinalin pabalik sa lumang structure para sa hike_navigation_confirmation mo
      return {
        "current": {
          "temp_c": tempValue,
          "condition": {
            "text": conditionText,
          }
        },
        "forecast": newData['forecast'] ?? [],
      };
    } catch (e) {
      throw Exception('Legacy getWeather failed: $e');
    }
  }
}