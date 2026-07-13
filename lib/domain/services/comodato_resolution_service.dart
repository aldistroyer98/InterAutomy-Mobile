import '../entities/client.dart';
import '../entities/comodato.dart';

enum ComodatoResolutionSource { explicit, line, general, none, invalidExplicit }

final class ComodatoResolution {
  const ComodatoResolution({required this.source, this.comodato});

  final ComodatoResolutionSource source;
  final Comodato? comodato;

  bool get valid => source != ComodatoResolutionSource.invalidExplicit;
}

/// Implementa la prioridad IA1 sin convertir ausencia de dato en un comodato.
abstract final class ComodatoResolutionService {
  static const _generalKeys = {'general', 'general (heredado)'};

  static ComodatoResolution resolve({
    required Client client,
    required String lineId,
    Comodato? explicit,
    bool forceNone = false,
  }) {
    if (forceNone) {
      return const ComodatoResolution(source: ComodatoResolutionSource.none);
    }
    final lineValues = _unique(client.comodatosPorLinea[lineId] ?? const []);
    final generalValues = _generalValues(client);
    if (explicit != null) {
      final allowed = [...lineValues, ...generalValues];
      final isAllowed = allowed.any(
        (value) => value.id == explicit.id || value.codigo == explicit.codigo,
      );
      return ComodatoResolution(
        source: isAllowed
            ? ComodatoResolutionSource.explicit
            : ComodatoResolutionSource.invalidExplicit,
        comodato: explicit,
      );
    }
    if (lineValues.length == 1) {
      return ComodatoResolution(
        source: ComodatoResolutionSource.line,
        comodato: lineValues.single,
      );
    }
    if (generalValues.length == 1) {
      return ComodatoResolution(
        source: ComodatoResolutionSource.general,
        comodato: generalValues.single,
      );
    }
    return const ComodatoResolution(source: ComodatoResolutionSource.none);
  }

  static List<Comodato> _generalValues(Client client) {
    final values = <Comodato>[];
    for (final entry in client.comodatosPorLinea.entries) {
      if (_generalKeys.contains(entry.key.trim().toLowerCase())) {
        values.addAll(entry.value);
      }
    }
    return _unique(values);
  }

  static List<Comodato> _unique(Iterable<Comodato> values) {
    final unique = <String, Comodato>{};
    for (final value in values) {
      unique.putIfAbsent('${value.id}|${value.codigo}', () => value);
    }
    return List.unmodifiable(unique.values);
  }
}
