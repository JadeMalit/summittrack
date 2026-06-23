class Mountain {
  final String name;
  final String region; // Luzon, Visayas, Mindanao
  final int elevation; // meters
  final String location; // province / city
  final String description; // short hiking info

  Mountain({
    required this.name,
    required this.region,
    required this.elevation,
    required this.location,
    required this.description,
  });
}
