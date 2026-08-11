class AppConfig {
  const AppConfig._();

  static const String graphHopperApiKey = String.fromEnvironment(
    'GRAPHHOPPER_API_KEY',
    defaultValue: '',
  );

  static const String graphHopperProfile = String.fromEnvironment(
    'GRAPHHOPPER_PROFILE',
    defaultValue: 'foot',
  );

  static const String openFreeMapStyleUrl = String.fromEnvironment(
    'OPENFREEMAP_STYLE_URL',
    defaultValue: 'https://tiles.openfreemap.org/styles/liberty',
  );

  static bool get hasGraphHopperApiKey => graphHopperApiKey.trim().isNotEmpty;
}
