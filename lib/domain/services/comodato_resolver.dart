import '../entities/client.dart';
import '../entities/comodato.dart';

abstract final class ComodatoResolver {
  static Comodato? resolve({
    required Client client,
    required String lineId,
    Comodato? explicit,
  }) {
    if (explicit != null) return explicit;
    final lineValues = client.comodatosPorLinea[lineId] ?? const [];
    if (lineValues.length == 1) return lineValues.single;
    final general = client.comodatosPorLinea['general'] ?? const [];
    if (general.isNotEmpty) return general.first;
    return null;
  }
}
