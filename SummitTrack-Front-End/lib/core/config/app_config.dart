class AppConfig {
  const AppConfig._();

  static const String graphHopperProfile = String.fromEnvironment(
    'GRAPHHOPPER_PROFILE',
    defaultValue: 'foot',
  );

  static const String openFreeMapStyleUrl = String.fromEnvironment(
    'OPENFREEMAP_STYLE_URL',
    defaultValue: 'https://tiles.openfreemap.org/styles/liberty',
  );

  static const String weatherFunctionUrl = String.fromEnvironment(
    'WEATHER_FUNCTION_URL',
    defaultValue:
        'https://us-central1-summittrack-10481.cloudfunctions.net/getSummitTrackWeather',
  );
}
