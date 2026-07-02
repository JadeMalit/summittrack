import '../data/trail_data/additional_mountains_data.dart';
import '../data/trail_data/mountain.dart';

class DataService {
  static List<Mountain> getMountains() {
    return [
      Mountain(
        name: 'Mt. Apo',
        region: 'Mindanao',
        elevation: 2954,
        location:
            'Mindanao, Philippines, between Davao City, Davao del Sur, and Cotabato',
        description:
            'Mt. Apo is the highest mountain in the Philippines, offering diverse ecosystems, sulfur vents, forests, and a challenging multi-day climb.',
        slope: 'Steep, rugged, and challenging',
        trails: const [
          'Sta. Cruz / Sibulan Trail',
          'Kapatagan Trails',
          'Kidapawan Trail',
          'Magpet Trail',
          'Bansalan Trail',
        ],
        imageAsset: 'assets/images/apo.jpg',
      ),
      Mountain(
        name: 'Mt. Pulag',
        region: 'Luzon',
        elevation: 2928,
        location: 'Benguet, Philippines',
        description:
            'Mt. Pulag is known for its sea of clouds, grassland summit, cold weather, and scenic highland trails.',
        slope: 'Moderate to challenging depending on the trail',
        trails: const [
          'Ambangeg Trail',
          'Akiki Trail',
          'Tawangan Trail',
          'Ambaguio Trail',
        ],
        imageAsset: 'assets/images/pulag.jpg',
      ),
      Mountain(
        name: 'Mt. Mayon',
        region: 'Luzon',
        elevation: 2462,
        location: 'Albay',
        description:
            'Known for its iconic perfect cone shape; offers stunning views from nearby trails like Mayon Skyline.',
      ),
      Mountain(
        name: 'Mt. Batulao',
        region: 'Luzon',
        elevation: 761,
        location: 'Batangas',
        description:
            'A popular beginner hike with rolling hills and great views, perfect for a day trip.',
      ),
      Mountain(
        name: 'Mt. Ulap',
        region: 'Luzon',
        elevation: 1826,
        location: 'Itogon, Benguet',
        description:
            'Easily accessible from Manila, known for its scenic ridges and panoramic vistas.',
      ),
      Mountain(
        name: 'Mt. Daraitan',
        region: 'Luzon',
        elevation: 700,
        location: 'Rizal',
        description:
            'Offers a mix of river trekking and mountain climbing with beautiful limestone formations.',
      ),
      Mountain(
        name: 'Mt. Maculot',
        region: 'Luzon',
        elevation: 706,
        location: 'Batangas',
        description:
            'Features the famous "Rocky Trail" leading to stunning views of Taal Volcano.',
      ),
      Mountain(
        name: 'Mt. Pico de Loro',
        region: 'Luzon',
        elevation: 688,
        location: 'Cavite/Batangas',
        description:
            'Known for its distinctive "Parrot\'s Beak" monolith, a challenging but rewarding climb.',
      ),
      Mountain(
        name: 'Mt. Pinatubo',
        region: 'Luzon',
        elevation: 1486,
        location: 'Pampanga/Zambales',
        description:
            'Hike to the crater lake of this active volcano for a unique landscape.',
      ),
      Mountain(
        name: 'Mt. Guiting-Guiting',
        region: 'Visayas',
        elevation: 2058,
        location: 'Romblon',
        description:
            'A major challenge for experienced hikers, known for its jagged ridges and demanding trails.',
      ),
      ...additionalMountainsData,
    ];
  }
}
