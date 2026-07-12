import 'comodato.dart';

final class Client {
  const Client({
    required this.id,
    required this.nombre,
    this.nroOc = '',
    this.archivoOc = '',
    this.unidad = '',
    this.servicio = '',
    this.institucion = '',
    this.departamento = '',
    this.provincia = '',
    this.distrito = '',
    this.direccion = '',
    this.contacto = '',
    this.telefono = '',
    this.comentarioFinal = '',
    this.direccionNueva = false,
    this.contactoNuevo = false,
    this.horaInicio = '09:00',
    this.horaFin = '10:00',
    this.igv = false,
    this.moneda = 'Soles',
    this.adelanto = false,
    this.motivo = 'SIN OC',
    this.comodatosPorLinea = const {},
  });

  final String id;
  final String nombre;
  final String nroOc;
  final String archivoOc;
  final String unidad;
  final String servicio;
  final String institucion;
  final String departamento;
  final String provincia;
  final String distrito;
  final String direccion;
  final String contacto;
  final String telefono;
  final String comentarioFinal;
  final bool direccionNueva;
  final bool contactoNuevo;
  final String horaInicio;
  final String horaFin;
  final bool igv;
  final String moneda;
  final bool adelanto;
  final String motivo;
  final Map<String, List<Comodato>> comodatosPorLinea;

  Client copyWith({
    String? id,
    String? nombre,
    String? nroOc,
    String? archivoOc,
    String? unidad,
    String? servicio,
    String? institucion,
    String? departamento,
    String? provincia,
    String? distrito,
    String? direccion,
    String? contacto,
    String? telefono,
    String? comentarioFinal,
    bool? direccionNueva,
    bool? contactoNuevo,
    String? horaInicio,
    String? horaFin,
    bool? igv,
    String? moneda,
    bool? adelanto,
    String? motivo,
    Map<String, List<Comodato>>? comodatosPorLinea,
  }) {
    return Client(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      nroOc: nroOc ?? this.nroOc,
      archivoOc: archivoOc ?? this.archivoOc,
      unidad: unidad ?? this.unidad,
      servicio: servicio ?? this.servicio,
      institucion: institucion ?? this.institucion,
      departamento: departamento ?? this.departamento,
      provincia: provincia ?? this.provincia,
      distrito: distrito ?? this.distrito,
      direccion: direccion ?? this.direccion,
      contacto: contacto ?? this.contacto,
      telefono: telefono ?? this.telefono,
      comentarioFinal: comentarioFinal ?? this.comentarioFinal,
      direccionNueva: direccionNueva ?? this.direccionNueva,
      contactoNuevo: contactoNuevo ?? this.contactoNuevo,
      horaInicio: horaInicio ?? this.horaInicio,
      horaFin: horaFin ?? this.horaFin,
      igv: igv ?? this.igv,
      moneda: moneda ?? this.moneda,
      adelanto: adelanto ?? this.adelanto,
      motivo: motivo ?? this.motivo,
      comodatosPorLinea: comodatosPorLinea ?? this.comodatosPorLinea,
    );
  }
}
