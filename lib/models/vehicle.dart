class Vehicle {
  final String id;
  final String name;
  final String brand;
  final String category;
  final int year;
  final String transmission;
  final String fuelType;
  final int engineCC;
  final int capacity;
  final int doors;
  final String luggage;
  final String description;
  final int pricePerDay;
  final int driverPricePerDay;
  final int deliveryPrice;
  final String imageUrl;
  final bool isAvailable;
  final bool isPopular;
  final DateTime? createdAt;

  Vehicle({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.year,
    required this.transmission,
    required this.fuelType,
    required this.engineCC,
    required this.capacity,
    this.doors = 4,
    this.luggage = '-',
    this.description = '',
    required this.pricePerDay,
    this.driverPricePerDay = 0,
    this.deliveryPrice = 0,
    this.imageUrl = '',
    this.isAvailable = true,
    this.isPopular = false,
    this.createdAt,
  });

  factory Vehicle.fromFirestore(String id, Map<String, dynamic> data) {
    // Handle baik jika imageUrl bertipe String maupun jika sebelumnya List
    String img = '';
    if (data['imageUrl'] is String) {
      img = data['imageUrl'];
    } else if (data['imageUrls'] is List && (data['imageUrls'] as List).isNotEmpty) {
      img = (data['imageUrls'] as List).first.toString();
    }

    return Vehicle(
      id: id,
      name: data['name'] ?? '',
      brand: data['brand'] ?? '',
      category: data['category'] ?? '',
      year: (data['year'] as num?)?.toInt() ?? 0,
      transmission: data['transmission'] ?? '',
      fuelType: data['fuelType'] ?? '',
      engineCC: (data['engineCC'] as num?)?.toInt() ?? 0,
      capacity: (data['capacity'] as num?)?.toInt() ?? 0,
      doors: (data['doors'] as num?)?.toInt() ?? 4,
      luggage: data['luggage'] ?? '-',
      description: data['description'] ?? '',
      pricePerDay: (data['pricePerDay'] as num?)?.toInt() ?? 0,
      driverPricePerDay: (data['driverPricePerDay'] as num?)?.toInt() ?? 0,
      deliveryPrice: (data['deliveryPrice'] as num?)?.toInt() ?? 0,
      imageUrl: img,
      isAvailable: data['isAvailable'] ?? false,
      isPopular: data['isPopular'] is bool
          ? data['isPopular']
          : (data['isPopular']?.toString().toLowerCase() == 'true'),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'brand': brand,
      'category': category,
      'year': year,
      'transmission': transmission,
      'fuelType': fuelType,
      'engineCC': engineCC,
      'capacity': capacity,
      'doors': doors,
      'luggage': luggage,
      'description': description,
      'pricePerDay': pricePerDay,
      'driverPricePerDay': driverPricePerDay,
      'deliveryPrice': deliveryPrice,
      'imageUrl': imageUrl,
      'isAvailable': isAvailable,
      'isPopular': isPopular,
    };
  }
}
