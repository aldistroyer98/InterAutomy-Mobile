import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../../../automation/detection/page_detector.dart';
import '../../../automation/webview/portal_diagnostics.dart';
import '../../../automation/webview_automation_gateway.dart';
import '../../../core/security/webview_security_policy.dart';
import '../../../state/app_controller.dart';
import '../../../state/providers.dart';

class PortalScreen extends ConsumerStatefulWidget {
  const PortalScreen({super.key});

  @override
  ConsumerState<PortalScreen> createState() => _PortalScreenState();
}

class _PortalScreenState extends ConsumerState<PortalScreen>
    with WidgetsBindingObserver {
  late final WebViewAutomationGateway _gateway;
  late final WebViewController _controller;
  bool _ready = false;
  String? _setupError;
  Timer? _loadTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _gateway = ref.read(webViewAutomationGatewayProvider);
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'InterAutomyPopup',
        onMessageReceived: (message) => _handlePopup(message.message),
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: _onNavigationRequest,
          onPageStarted: _onPageStarted,
          onPageFinished: (url) {
            _loadTimer?.cancel();
            _gateway.webController.pageFinished(url);
            _gateway.recordPageFinished(Uri.tryParse(url));
            _refreshDiagnosticsSilently();
          },
          onProgress: _gateway.webController.progressChanged,
          onUrlChange: (change) {
            if (change.url != null) {
              _gateway.webController.urlChanged(change.url!);
            }
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame == true) {
              _gateway.webController.webError(error.description);
              final type = error.errorType?.name ?? 'unknown';
              _gateway.recordNetworkError(
                type.contains('hostLookup')
                    ? 'dns'
                    : type.contains('timeout')
                    ? 'timeout'
                    : 'other',
                error.description,
              );
            }
          },
          onHttpError: (error) => _gateway.webController.webError(
            'HTTP ${error.response?.statusCode ?? 'desconocido'}',
          ),
          onSslAuthError: (error) {
            unawaited(error.cancel());
            _gateway.webController.webError('Error SSL; conexión cancelada.');
            _gateway.recordNetworkError(
              'ssl',
              'Error SSL; el certificado no fue ignorado.',
            );
          },
        ),
      );
    Future<void>.microtask(_configure);
  }

  Future<NavigationDecision> _onNavigationRequest(
    NavigationRequest request,
  ) async {
    final uri = Uri.tryParse(request.url);
    if (uri != null && _gateway.webController.mayNavigate(uri)) {
      _gateway.recordNavigationDecision(
        target: uri,
        allowed: true,
        reason: 'HTTPS y host incluido en la lista blanca.',
      );
      return NavigationDecision.navigate;
    }
    if (uri != null) {
      _gateway.recordNavigationDecision(
        target: uri,
        allowed: false,
        reason: uri.scheme == 'https'
            ? 'Host no autorizado.'
            : 'Esquema distinto de HTTPS.',
      );
    }
    if (mounted && uri != null && uri.scheme == 'https') {
      final decision = await showDialog<_ExternalNavigationDecision>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Enlace externo bloqueado'),
          content: Text(
            'El host ${uri.host} no está autorizado para automatización. '
            '¿Deseas abrirlo fuera de InterAutomy?',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, _ExternalNavigationDecision.cancel),
              child: const Text('Cancelar'),
            ),
            OutlinedButton(
              onPressed: () =>
                  Navigator.pop(context, _ExternalNavigationDecision.authorize),
              child: const Text('Autorizar host'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(context, _ExternalNavigationDecision.external),
              child: const Text('Abrir externamente'),
            ),
          ],
        ),
      );
      if (decision == _ExternalNavigationDecision.authorize) {
        await _authorizeHost(uri);
      } else if (decision == _ExternalNavigationDecision.external) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Navegación insegura bloqueada.')),
      );
    }
    return NavigationDecision.prevent;
  }

  void _onPageStarted(String url) {
    _loadTimer?.cancel();
    _gateway.webController.pageStarted(url);
    final seconds = ref.read(appControllerProvider).settings.loadTimeoutSeconds;
    _loadTimer = Timer(Duration(seconds: seconds), () {
      _gateway.webController.webError('Timeout de carga del portal.');
      _gateway.recordNetworkError(
        'timeout',
        'La página superó el timeout configurado.',
      );
    });
  }

  Future<void> _authorizeHost(Uri uri) async {
    final state = ref.read(appControllerProvider);
    final hosts = {...state.settings.additionalAllowedHosts, uri.host}.toList()
      ..sort();
    final updated = state.settings.copyWith(additionalAllowedHosts: hosts);
    await ref.read(appControllerProvider.notifier).updateSettings(updated);
    final policy = WebViewSecurityPolicy(
      portalUrl: WebViewSecurityPolicy.parsePortalUrl(updated.portalUrl),
      additionalHosts: updated.additionalAllowedHosts,
    );
    _gateway.webController.bind(_controller, policy);
    _gateway.recordNavigationDecision(
      target: uri,
      allowed: true,
      reason: 'Host agregado manualmente por el usuario.',
    );
    await _controller.loadRequest(uri);
  }

  Future<void> _handlePopup(String rawUrl) async {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null || uri.scheme != 'https') return;
    _gateway.webController.popupRequested();
    if (_gateway.webController.mayNavigate(uri)) {
      await _controller.loadRequest(uri);
      return;
    }
    if (!mounted) return;
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Popup externo bloqueado'),
        content: Text(
          'El host ${uri.host} no está autorizado. ¿Deseas abrirlo externamente?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Abrir externamente'),
          ),
        ],
      ),
    );
    if (approved == true) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _configure() async {
    final settings = ref.read(appControllerProvider).settings;
    final policy = WebViewSecurityPolicy(
      portalUrl: WebViewSecurityPolicy.parsePortalUrl(settings.portalUrl),
      additionalHosts: settings.additionalAllowedHosts,
    );
    try {
      if (_controller.platform is AndroidWebViewController) {
        final android = _controller.platform as AndroidWebViewController;
        await android.setAllowFileAccess(false);
        await android.setAllowContentAccess(true);
        await android.setGeolocationEnabled(false);
        await android.setOnShowFileSelector(_gateway.pickFilesForWeb);
      }
      _gateway.webController.bind(_controller, policy);
      if (policy.isConfigured) await _gateway.openConfiguredPortal();
      if (mounted) setState(() => _ready = true);
    } catch (error) {
      if (mounted) setState(() => _setupError = '$error');
    }
  }

  Future<void> _refreshDiagnosticsSilently() async {
    try {
      await _gateway.refreshDiagnostics();
    } catch (_) {
      // El error visible se publica mediante NavigationDelegate/diagnóstico.
    }
  }

  Future<void> _showLog() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => ValueListenableBuilder(
        valueListenable: _gateway.diagnosticLog,
        builder: (context, entries, _) {
          return SafeArea(
            top: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              children: [
                Text('Bitácora', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                if (entries.isEmpty)
                  const Text('Aún no hay eventos de automatización.')
                else
                  ...entries.map(
                    (entry) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.circle_outlined, size: 18),
                      title: Text(entry.event),
                      subtitle: Text(entry.timestamp.toLocal().toString()),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _goBack() async {
    if (await _controller.canGoBack()) await _controller.goBack();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _loadTimer?.cancel();
    unawaited(_gateway.portalClosed());
    _gateway.webController.unbind();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _gateway.appPaused();
    } else if (state == AppLifecycleState.resumed) {
      unawaited(_gateway.appResumed());
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appControllerProvider);
    final settings = appState.settings;
    if (!settings.hasPortalConfiguration) {
      return Scaffold(
        appBar: AppBar(title: const Text('Automy integrado')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 48),
                const SizedBox(height: 12),
                const Text(
                  'Configura la URL HTTPS del portal Automy antes de abrir el WebView.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => context.go('/settings'),
                  child: const Text('Ir a ajustes'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: ValueListenableBuilder<PortalDiagnostics>(
          valueListenable: _gateway.diagnostics,
          builder: (context, data, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(data.page.label),
              Text(
                WebViewSecurityPolicy.displayUrl(data.url),
                style: Theme.of(context).textTheme.labelSmall,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Atrás',
            onPressed: _goBack,
            icon: const Icon(Icons.arrow_back),
          ),
          IconButton(
            tooltip: 'Recargar',
            onPressed: _controller.reload,
            icon: const Icon(Icons.refresh),
          ),
          if (settings.developerMode)
            IconButton(
              tooltip: 'Inspector Web',
              onPressed: () => context.push('/validation'),
              icon: const Icon(Icons.monitor_heart_outlined),
            ),
          IconButton(
            tooltip: 'Bitácora',
            onPressed: _showLog,
            icon: const Icon(Icons.article_outlined),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            ValueListenableBuilder<PortalDiagnostics>(
              valueListenable: _gateway.diagnostics,
              builder: (context, data, _) => Column(
                children: [
                  if (data.isLoading)
                    LinearProgressIndicator(value: data.loadingProgress / 100),
                  if (data.lastError != null)
                    MaterialBanner(
                      content: Text(data.lastError!),
                      actions: [
                        TextButton(
                          onPressed: _controller.reload,
                          child: const Text('Recargar'),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            Expanded(
              child: _setupError != null
                  ? Center(
                      child: Text('No se pudo preparar WebView: $_setupError'),
                    )
                  : !_ready
                  ? const Center(child: CircularProgressIndicator())
                  : WebViewWidget(controller: _controller),
            ),
            Material(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Login, navegación y envío son manuales. La app no envía pedidos.',
                      ),
                    ),
                    if (settings.developerMode)
                      TextButton.icon(
                        key: const Key('portal-web-inspector'),
                        onPressed: () => context.push('/validation'),
                        icon: const Icon(Icons.troubleshoot_outlined),
                        label: const Text('Inspector'),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _ExternalNavigationDecision { cancel, authorize, external }

extension on PortalPage {
  String get label => switch (this) {
    PortalPage.unknown => 'Automy',
    PortalPage.login => 'Inicio de sesión',
    PortalPage.home => 'Inicio',
    PortalPage.processList => 'Lista de procesos',
    PortalPage.clientForm => 'Formulario de cliente',
    PortalPage.productForm => 'Formulario de productos',
    PortalPage.review => 'Revisión',
    PortalPage.success => 'Resultado',
    PortalPage.error => 'Error de portal',
    PortalPage.sessionExpired => 'Sesión expirada',
    PortalPage.blockedBySecurity => 'Bloqueado por seguridad',
    PortalPage.unsupportedStructure => 'Estructura no reconocida',
  };
}
