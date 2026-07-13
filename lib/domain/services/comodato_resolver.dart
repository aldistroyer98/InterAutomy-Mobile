import '../entities/client.dart';
import '../entities/comodato.dart';
import 'comodato_resolution_service.dart';

abstract final class ComodatoResolver {
  static Comodato? resolve({
    required Client client,
    required String lineId,
    Comodato? explicit,
  }) {
    return ComodatoResolutionService.resolve(
      client: client,
      lineId: lineId,
      explicit: explicit,
    ).comodato;
  }
}
