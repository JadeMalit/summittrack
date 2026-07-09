class MountainScheduleIdentity {
  const MountainScheduleIdentity._();

  static const Map<String, String> _displayNamesById = {
    'mt-apo': 'Mt. Apo',
    'mt-pulag': 'Mt. Pulag',
    'mayon': 'Mt. Mayon',
    'batulao': 'Mt. Batulao',
    'ulap': 'Mt. Ulap',
    'daraitan': 'Mt. Daraitan',
    'maculot': 'Mt. Maculot',
    'picodeloro': 'Mt. Pico de Loro',
    'pinatubo': 'Mt. Pinatubo',
    'g2': 'Mt. Guiting-Guiting',
  };

  static const Map<String, String> _weatherNamesById = {
    'mt-apo': 'Mount Apo',
    'mt-pulag': 'Mount Pulag',
    'mayon': 'Mount Mayon',
    'batulao': 'Mount Batulao',
    'ulap': 'Mount Ulap',
    'daraitan': 'Mount Daraitan',
    'maculot': 'Mount Maculot',
    'picodeloro': 'Mount Pico de Loro',
    'pinatubo': 'Mount Pinatubo',
    'g2': 'Mount Guiting-Guiting',
    'manabu': 'Mount Manabu',
    'gulugod-baboy': 'Mount Gulugod Baboy',
    'maynoba': 'Mount Maynoba',
    'cutuno': 'Mount Cutuno',
    'lingguhob': 'Mount Lingguhob',
    'arayat': 'Mount Arayat',
    'makiling': 'Mount Makiling',
    'damas': 'Mount Damas',
    'tugew': 'Mount Tugew',
    'mariglem': 'Mount Mariglem',
    'tapulao': 'Mount Tapulao',
    'espadang-bato': 'Mount Espadang Bato',
    'hibok-hibok': 'Mount Hibok-Hibok',
    'kitanglad': 'Mount Kitanglad',
  };

  static const Map<String, String> _idsByWeatherName = {
    'Mount Apo': 'mt-apo',
    'Mount Pulag': 'mt-pulag',
    'Mount Mayon': 'mayon',
    'Mount Batulao': 'batulao',
    'Mount Ulap': 'ulap',
    'Mount Daraitan': 'daraitan',
    'Mount Maculot': 'maculot',
    'Mount Pico de Loro': 'picodeloro',
    'Mount Pinatubo': 'pinatubo',
    'Mount Guiting-Guiting': 'g2',
    'Mount Manabu': 'manabu',
    'Mount Gulugod Baboy': 'gulugod-baboy',
    'Mount Maynoba': 'maynoba',
    'Mount Cutuno': 'cutuno',
    'Mount Lingguhob': 'lingguhob',
    'Mount Arayat': 'arayat',
    'Mount Makiling': 'makiling',
    'Mount Damas': 'damas',
    'Mount Tugew': 'tugew',
    'Mount Mariglem': 'mariglem',
    'Mount Tapulao': 'tapulao',
    'Mount Espadang Bato': 'espadang-bato',
    'Mount Hibok-Hibok': 'hibok-hibok',
    'Mount Kitanglad': 'kitanglad',
  };

  static String idFromRoute(String route) {
    final normalizedRoute = route.trim();
    if (normalizedRoute.isEmpty) {
      return 'unknown-mountain';
    }

    final uri = Uri.tryParse(normalizedRoute);
    final segments = uri?.pathSegments ?? const <String>[];

    if (segments.length >= 2 && segments.first == 'mountain') {
      return normalizeMountainId(segments[1]);
    }

    return normalizeMountainId(normalizedRoute);
  }

  static String idForWeatherName(String mountainName) {
    return _idsByWeatherName[mountainName] ?? normalizeMountainId(mountainName);
  }

  static String displayNameForMountainId(String mountainId) {
    final normalizedId = normalizeMountainId(mountainId);
    return _displayNamesById[normalizedId] ??
        _weatherNamesById[normalizedId] ??
        _fallbackMountainName(normalizedId, prefix: 'Mt.');
  }

  static String weatherNameForMountainId(String mountainId) {
    final normalizedId = normalizeMountainId(mountainId);
    return _weatherNamesById[normalizedId] ??
        _fallbackMountainName(normalizedId, prefix: 'Mount');
  }

  static String normalizeMountainId(String value) {
    var normalized = value.trim().toLowerCase();
    normalized = normalized.replaceAll('&', 'and');
    normalized = normalized.replaceAll(RegExp(r'^(mount|mt\.?)\s+'), '');
    normalized = normalized
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');

    if (normalized == 'apo') {
      return 'mt-apo';
    }

    if (normalized == 'pulag') {
      return 'mt-pulag';
    }

    return normalized.isEmpty ? 'unknown-mountain' : normalized;
  }

  static String _fallbackMountainName(
    String mountainId, {
    required String prefix,
  }) {
    final words = mountainId
        .replaceAll(RegExp(r'^mt-'), '')
        .split('-')
        .where((word) => word.isNotEmpty)
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');

    if (words.isEmpty) {
      return '$prefix Unknown Mountain';
    }

    return '$prefix $words';
  }
}
