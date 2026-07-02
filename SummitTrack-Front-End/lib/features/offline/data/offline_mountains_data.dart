import '../../../data/trail_data/additional_mountains_data.dart';
import '../../../data/trail_data/mountain.dart';

const List<Mountain> offlineMountainsData = [
  Mountain(
    name: 'Mt. Apo',
    region: 'Mindanao',
    elevation: 2954,
    location:
        'Mindanao, Philippines, between Davao City, Davao del Sur, and Cotabato',
    description:
        'Mt. Apo is the highest mountain in the Philippines, with forests, sulfur vents, open boulder sections, and demanding multi-day trail options.',
    slope: 'Steep, rugged, and challenging',
    trails: [
      'Sta. Cruz / Sibulan Trail',
      'Kapatagan Trails',
      'Kidapawan Trail',
      'Magpet Trail',
      'Bansalan Trail',
    ],
    imageAsset: 'assets/images/mt_apo_enhanced.png',
  ),
  Mountain(
    name: 'Mt. Pulag',
    region: 'Luzon',
    elevation: 2928,
    location: 'Benguet, Philippines',
    description:
        'Mt. Pulag is known for its sea of clouds, cool summit conditions, grassland ridges, and several trail choices for different experience levels.',
    slope: 'Moderate to challenging depending on the trail',
    trails: [
      'Ambangeg Trail',
      'Akiki Trail',
      'Tawangan Trail',
      'Ambaguio Trail',
    ],
    imageAsset: 'assets/images/mt_pulag_home.jpg',
  ),
  Mountain(
    name: 'Mt. Mayon',
    region: 'Luzon',
    elevation: 2462,
    location: 'Albay',
    description:
        'Mt. Mayon is recognized for its near-perfect cone and scenic nearby routes with views of Albay and the volcano landscape.',
    slope: 'Steep volcanic terrain',
    imageAsset: 'assets/images/mayon_home.png',
  ),
  Mountain(
    name: 'Mt. Batulao',
    region: 'Luzon',
    elevation: 761,
    location: 'Batangas',
    description:
        'Mt. Batulao is a popular day hike with rolling ridges, open grassland, and accessible trails for newer hikers.',
    slope: 'Rolling ridges with moderate ascents',
    imageAsset: 'assets/images/mt_batulao_home.png',
  ),
  Mountain(
    name: 'Mt. Ulap',
    region: 'Luzon',
    elevation: 1826,
    location: 'Itogon, Benguet',
    description:
        'Mt. Ulap offers scenic ridgelines, pine forests, and panoramic Cordillera views from a well-known traverse route.',
    slope: 'Moderate ridge trail',
    imageAsset: 'assets/images/mt_ulap.jpg',
  ),
  Mountain(
    name: 'Mt. Daraitan',
    region: 'Luzon',
    elevation: 700,
    location: 'Rizal',
    description:
        'Mt. Daraitan combines forested climbs, limestone formations, river scenery, and access to Tinipak River.',
    slope: 'Rocky forest trail',
    imageAsset: 'assets/images/mt_daraitan_home.png',
  ),
  Mountain(
    name: 'Mt. Maculot',
    region: 'Luzon',
    elevation: 706,
    location: 'Batangas',
    description:
        'Mt. Maculot is known for the Rockies viewpoint overlooking Taal Lake and short but steep trail sections.',
    slope: 'Short, steep, and rocky',
    imageAsset: 'assets/images/mt_maculot_home.png',
  ),
  Mountain(
    name: 'Mt. Pico de Loro',
    region: 'Luzon',
    elevation: 688,
    location: 'Cavite/Batangas',
    description:
        'Mt. Pico de Loro features forest trails and the famous Parrot\'s Beak monolith area.',
    slope: 'Moderate forested climb',
  ),
  Mountain(
    name: 'Mt. Pinatubo',
    region: 'Luzon',
    elevation: 1486,
    location: 'Pampanga/Zambales',
    description:
        'Mt. Pinatubo is known for its crater lake, lahar landscapes, and wide volcanic scenery.',
    slope: 'Gentle to moderate volcanic terrain',
  ),
  Mountain(
    name: 'Mt. Guiting-Guiting',
    region: 'Visayas',
    elevation: 2058,
    location: 'Romblon',
    description:
        'Mt. Guiting-Guiting is a demanding climb with jagged ridges, technical sections, and rugged mountain terrain.',
    slope: 'Very steep and highly challenging',
  ),
  ...additionalMountainsData,
];
