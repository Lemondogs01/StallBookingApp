class StallModel {
  final int id;
  final String code;
  final String zone;
  final String size;
  final double pricePerDay;
  final String productType;
  final String status;
  final bool covered;
  final bool power;
  final String note;

  StallModel({
    required this.id,
    required this.code,
    required this.zone,
    required this.size,
    required this.pricePerDay,
    required this.productType,
    this.status = 'active',
    this.covered = false,
    this.power = false,
    this.note = '',
  });

  String get sizeLabel => '${size.replaceAll('x', '×')} m';

  /// Short label used on the stall map, e.g. "A-07" -> "A07".
  String get label => code.replaceAll('-', '');

  factory StallModel.fromJson(Map<String, dynamic> json) {
    return StallModel(
      id: json['id'] as int,
      code: json['code'] as String,
      zone: json['zone'] as String,
      size: json['size'] as String,
      pricePerDay: double.parse('${json['price_per_day']}'),
      productType: json['product_type'] as String,
      status: json['status'] as String,
      covered: (json['covered'] as bool?) ?? false,
      power: (json['power'] as bool?) ?? false,
      note: (json['note'] as String?) ?? '',
    );
  }
}
