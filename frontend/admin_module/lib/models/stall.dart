/// Mirrors the `stalls` table: id, code, zone, size, price_per_day, product_type, status
enum StallStatus {
  available('Available'),
  unavailable('Unavailable');

  const StallStatus(this.label);
  final String label;
}

class Stall {
  const Stall({
    required this.id,
    required this.code,
    required this.zone,
    required this.size,
    required this.pricePerDay,
    required this.productType,
    required this.status,
  });

  final int id;
  final String code;
  final String zone;
  final String size;
  final double pricePerDay;
  final String productType;
  final StallStatus status;

  Stall copyWith({
    int? id,
    String? code,
    String? zone,
    String? size,
    double? pricePerDay,
    String? productType,
    StallStatus? status,
  }) {
    return Stall(
      id: id ?? this.id,
      code: code ?? this.code,
      zone: zone ?? this.zone,
      size: size ?? this.size,
      pricePerDay: pricePerDay ?? this.pricePerDay,
      productType: productType ?? this.productType,
      status: status ?? this.status,
    );
  }
}
