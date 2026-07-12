final class ClientDto {
  const ClientDto({required this.id, required this.name, required this.fields});

  factory ClientDto.fromJson(Map<String, Object?> json) => ClientDto(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    fields: Map<String, Object?>.from(json['fields'] as Map? ?? const {}),
  );

  final String id;
  final String name;
  final Map<String, Object?> fields;

  Map<String, Object?> toJson() => {'id': id, 'name': name, 'fields': fields};
}
