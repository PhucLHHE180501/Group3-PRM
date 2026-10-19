class ServiceModel {
  final int id;
  final String name;
  final String description;
  final double price;
  final int durationMin;
  final String imageUrl;
  final bool isActive;

  ServiceModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.durationMin,
    required this.imageUrl,
    this.isActive = true,
  });
}
