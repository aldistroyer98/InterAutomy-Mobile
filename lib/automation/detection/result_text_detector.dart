enum PortalResult { success, error, unknown }

abstract final class ResultTextDetector {
  static PortalResult detect(String raw) {
    final text = raw
        .toLowerCase()
        .replaceAll(RegExp(r'[áàäâ]'), 'a')
        .replaceAll(RegExp(r'[éèëê]'), 'e')
        .replaceAll(RegExp(r'[íìïî]'), 'i')
        .replaceAll(RegExp(r'[óòöô]'), 'o')
        .replaceAll(RegExp(r'[úùüû]'), 'u')
        .replaceAll(RegExp(r'\s+'), ' ');
    if (RegExp(r'error|fallo|no se pudo|rechazado').hasMatch(text)) {
      return PortalResult.error;
    }
    if (RegExp(
      r'solicitud.{0,80}(enviada|registrada|completada)|pedido.{0,80}(registrado|enviado|completado)|producto.{0,80}enviado',
    ).hasMatch(text)) {
      return PortalResult.success;
    }
    return PortalResult.unknown;
  }
}
