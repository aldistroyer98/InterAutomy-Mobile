final class Comodato {
  const Comodato({
    required this.id,
    required this.codigo,
    required this.nombre,
    this.esGeneral = false,
  });

  final String id;
  final String codigo;
  final String nombre;
  final bool esGeneral;

  String get etiqueta => nombre.isEmpty ? codigo : '$codigo · $nombre';
}
