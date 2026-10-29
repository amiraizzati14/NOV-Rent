enum CarCategory { suv, sedan, luxury, electric }

class Vehicle {
  final String id;
  final String name;
  final CarCategory category;
  final double pricePerDay;
  final String imageUrl;
  final bool isAvailable;

  Vehicle({
    required this.id,
    required this.name,
    required this.category,
    required this.pricePerDay,
    required this.imageUrl,
    this.isAvailable = true,
  });
}