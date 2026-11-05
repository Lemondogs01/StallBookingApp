class EventModel {
  final int id;
  final String name;
  final String? description;
  final String location;
  final double price;
  final int stallsLeft;
  final String imageUrl;

  EventModel({
    required this.id,
    required this.name,
    this.description,
    required this.location,
    required this.price,
    required this.stallsLeft,
    required this.imageUrl,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? json['title'] ?? 'Untitled Event',
      description: json['description'],
      location: json['location'] ?? 'Chiang Rai',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      stallsLeft: json['stalls_left'] ?? json['stallsLeft'] ?? 0,
      imageUrl: json['image_url'] ?? json['imageUrl'] ?? '',
    );
  }
}
