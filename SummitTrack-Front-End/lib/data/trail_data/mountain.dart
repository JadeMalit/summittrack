class Mountain {
  final String name;
  final String region; // Luzon, Visayas, Mindanao
  final int elevation; // meters
  final String location; // province / city
  final String description; // short hiking info
  final String slope;
  final List<String> trails;
  final String? imageAsset;

  const Mountain({
    required this.name,
    required this.region,
    required this.elevation,
    required this.location,
    required this.description,
    this.slope = 'Not specified',
    this.trails = const [],
    this.imageAsset,
  });

  bool get hasSpecifiedElevation => elevation > 0;

  String get elevationLabel =>
      hasSpecifiedElevation ? '$elevation m' : 'Not specified';

  bool get hasTrails => trails.isNotEmpty;
}
