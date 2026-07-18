import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  // Base URL ng local Firebase Cloud Function mo
  final String _baseUrl = 'http://localhost:5001/summittrack-10481/us-central1/getSummitTrackWeather';

  // Heto ang hinahanap na method ng weather.dart mo!
  Future<Map<String, dynamic>> fetch15DayWeather(double lat, double lon) async {
    try {
      final url = Uri.parse('$_baseUrl?lat=$lat&lon=$lon');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        // Ibinabalik nito ang pinagsamang data ng OpenWeather at Open-Meteo
        return json.decode(response.body);
      } else {
        throw Exception('Server Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Hindi makakonekta sa local Firebase server: $e');
    }
  }
}