class TrailData {
  const TrailData({
    required this.name,
    required this.location,
    required this.description,
    required this.slopeDifficulty,
    required this.imageAsset,
    required this.preparationItems,
    required this.essentialItems,
    this.overnightItems = const [],
    this.safetyReminders = const [],
    this.showTrailMap = true,
  });

  final String name;
  final String location;
  final String description;
  final String slopeDifficulty;
  final String imageAsset;
  final List<String> preparationItems;
  final List<String> essentialItems;
  final List<String> overnightItems;
  final List<String> safetyReminders;
  final bool showTrailMap;
}
