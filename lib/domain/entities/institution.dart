final class Institution {
  const Institution({
    required this.id,
    required this.nombre,
    this.clientIds = const [],
    this.departamento = '',
    this.provincia = '',
    this.distrito = '',
    this.direccion = '',
    this.contacto = '',
    this.telefono = '',
  });

  final String id;
  final String nombre;
  final List<String> clientIds;
  final String departamento;
  final String provincia;
  final String distrito;
  final String direccion;
  final String contacto;
  final String telefono;

  Institution copyWith({
    String? id,
    String? nombre,
    List<String>? clientIds,
    String? departamento,
    String? provincia,
    String? distrito,
    String? direccion,
    String? contacto,
    String? telefono,
  }) => Institution(
    id: id ?? this.id,
    nombre: nombre ?? this.nombre,
    clientIds: clientIds ?? this.clientIds,
    departamento: departamento ?? this.departamento,
    provincia: provincia ?? this.provincia,
    distrito: distrito ?? this.distrito,
    direccion: direccion ?? this.direccion,
    contacto: contacto ?? this.contacto,
    telefono: telefono ?? this.telefono,
  );
}
