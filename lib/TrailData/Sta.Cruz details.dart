class TrailData {
  const TrailData({
    required this.name,
    required this.location,
    required this.description,
    required this.imageAsset,
    required this.preparationItems,
    required this.essentialItems,
    required this.overnightItems,
  });

  final String name;
  final String location;
  final String description;
  final String imageAsset;
  final List<String> preparationItems;
  final List<String> essentialItems;
  final List<String> overnightItems;
}

const TrailData staCruzSibulanTrail = TrailData(
  name: 'Sta. Cruz / Sibulan Trail',
  location:
      'Sta. Cruz, Davao del Sur, on the southern side of Mt. Apo. The Davao del Sur government lists the Sibulan, Sta. Cruz Trail as one of the mountain\'s entry points.',
  description:
      'For the Sta. Cruz / Sibulan Trail, the slope is not the same all the way. It starts with farm and jungle trail, then becomes much harder at the Boulder Face. Recent trail guides describe the route as hard, with the upper Boulder Face starting at around 2,400 meters above sea level and turning into a rock scramble over volcanic boulders. Some sections are described as reaching about 60-80 degrees. In simple terms, the trail is moderate at the lower part, then very steep, rocky, and exposed near the upper part.',
  imageAsset: 'assets/images/apo.jpg',
  preparationItems: [
    'Valid ID',
    'Permit / registration details',
    'Guide or organizer confirmation because Mt. Apo trekkers are generally required to register and use a guide',
    'Medical certificate, since major current Mt. Apo climbs and organizers require proof that you are fit to hike, especially for more demanding routes',
  ],
  essentialItems: [
    'Backpack',
    'Hiking shoes with good grip',
    'Rain jacket or poncho',
    'Warm clothes because campsites and summit temperatures can get quite cold',
    'Headlamp or flashlight',
    '2-3 liters of water plus refillable bottle',
    'Trail food / snacks',
    'Personal medicine / first aid',
    'Power bank',
    'Toiletries',
    'Extra clothes and socks',
  ],
  overnightItems: [
    'Tent',
    'Sleeping bag',
    'Mess kit, such as plate, cup, spoon, and fork',
    'Slippers or sandals for camp',
  ],
);
