/// Reglas centralizadas para la navegación y la ejecución de DOM en Automy.
///
/// El host del portal se autoriza explícitamente al guardar la configuración.
/// Los dominios de autenticación adicionales también requieren una acción
/// explícita del usuario; no se aceptan comodines ni HTTP.
final class WebViewSecurityPolicy {
  WebViewSecurityPolicy({
    required this.portalUrl,
    Iterable<String> additionalHosts = const [],
  }) : _additionalHosts = additionalHosts
           .map(_normalizeHost)
           .whereType<String>()
           .toSet();

  final Uri? portalUrl;
  final Set<String> _additionalHosts;

  Set<String> get allowedHosts => {
    if (portalUrl != null) portalUrl!.host.toLowerCase(),
    ..._additionalHosts,
  };

  bool get isConfigured => portalUrl != null && allowedHosts.isNotEmpty;

  bool isAllowedUri(Uri uri) =>
      uri.scheme.toLowerCase() == 'https' &&
      allowedHosts.contains(uri.host.toLowerCase());

  bool canRunJavaScript(Uri? uri) => uri != null && isAllowedUri(uri);

  static Uri? parsePortalUrl(String raw) {
    final uri = Uri.tryParse(raw.trim());
    if (uri == null ||
        uri.scheme.toLowerCase() != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      return null;
    }
    return uri.replace(query: '', fragment: '');
  }

  static String? _normalizeHost(String value) {
    final host = value.trim().toLowerCase();
    if (host.isEmpty ||
        host.contains('/') ||
        host.contains(':') ||
        host.contains('@') ||
        !RegExp(r'^[a-z0-9.-]+$').hasMatch(host)) {
      return null;
    }
    return host;
  }

  static List<String>? parseAdditionalHosts(String raw) {
    if (raw.trim().isEmpty) return const [];
    final hosts = raw.split(',').map(_normalizeHost).toList(growable: false);
    if (hosts.any((host) => host == null)) return null;
    return hosts.cast<String>().toSet().toList()..sort();
  }

  static String displayUrl(Uri? uri) {
    if (uri == null) return 'Sin abrir';
    final path = uri.path.isEmpty || uri.path == '/' ? '' : uri.path;
    return '${uri.scheme}://${uri.host}$path';
  }
}
