final class ProductDto {
  const ProductDto({
    required this.id,
    required this.code,
    required this.name,
    required this.lineId,
    required this.price,
  });

  factory ProductDto.fromJson(Map<String, Object?> json) => ProductDto(
    id: json['id'] as String? ?? '',
    code: json['code'] as String? ?? '',
    name: json['name'] as String? ?? '',
    lineId: json['line_id'] as String? ?? '',
    price: (json['price'] as num?)?.toDouble() ?? 0,
  );

  final String id;
  final String code;
  final String name;
  final String lineId;
  final double price;

  Map<String, Object?> toJson() => {
    'id': id,
    'code': code,
    'name': name,
    'line_id': lineId,
    'price': price,
  };
}
