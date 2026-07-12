import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../../../app/app_config.dart';
import '../../../automation/detection/page_detector.dart';
import '../../../automation/webview/portal_diagnostics.dart';
import '../../../automation/webview_automation_gateway.dart';
import '../../../core/security/webview_security_policy.dart';
import '../../../domain/entities/execution.dart';
import '../../../state/app_controller.dart';
import '../../../state/providers.dart';

class PortalScreen extends ConsumerStatefulWidget {
  const PortalScreen({super.key});

  @override
  ConsumerState<PortalScreen> createState() => _PortalScreenState();
}

class _PortalScreenState extends ConsumerState<PortalScreen> {
  late final WebViewAutomationGateway _gateway;
  late final WebViewController _controller;
  bool _ready = false;
  String? _setupError;

  @override
  void initState() {
    super.initState();
    _gateway = ref.read(webViewAutomationGatewayProvider);
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: _onNavigationRequest,
          onPageStarted: (url) => _gateway.webController.pageStarted(url),
          onPageFinished: (url) {
            _gateway.webController.pageFinished(url);
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
            }
          },
          onHttpError: (error) => _gateway.webController.webError(
            'HTTP ${error.response?.statusCode ?? 'desconocido'}',
          ),
        ),
      );
    Future<void>.microtask(_configure);
  }

  Future<NavigationDecision> _onNavigationRequest(
    NavigationRequest request,
  ) async {
    final uri = Uri.tryParse(request.url);
    if (uri != null && _gateway.webController.mayNavigate(uri)) {
      return NavigationDecision.navigate;
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Enlace bloqueado: el host no está autorizado para Automy.',
          ),
        ),
      );
    }
    return NavigationDecision.prevent;
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

  Future<void> _openDiagnostics() async {
    try {
      await _gateway.refreshDiagnostics();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo actualizar el diagnóstico: $error'),
          ),
        );
      }
    }
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => ValueListenableBuilder<PortalDiagnostics>(
        valueListenable: _gateway.diagnostics,
        builder: (context, data, _) => _DiagnosticSheet(data: data),
      ),
    );
  }

  Future<void> _showLog() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final entries =
              ref.watch(appControllerProvider).execution?.bitacora ?? const [];
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
                      title: Text(entry.message),
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

  Future<void> _prepareOrder() async {
    final issues = await ref
        .read(appControllerProvider.notifier)
        .startExecution();
    if (!mounted || issues.isEmpty) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Validación requerida'),
        content: Text(issues.join('\n')),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Future<void> _checkResult() async {
    final confirmed = await ref
        .read(appControllerProvider.notifier)
        .confirmBrowserClosed();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          confirmed
              ? 'Producto enviado.'
              : 'Resultado no confirmado; continúe la revisión.',
        ),
      ),
    );
  }

  @override
  void dispose() {
    _gateway.webController.unbind();
    super.dispose();
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
    final execution = appState.execution;
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
          IconButton(
            tooltip: 'Diagnóstico',
            onPressed: _openDiagnostics,
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
            _ReviewPanel(
              execution: execution,
              allowAutomaticSubmission: AppConfig.allowAutomaticSubmission,
              onPrepare: _prepareOrder,
              onCancel: () =>
                  ref.read(appControllerProvider.notifier).cancelExecution(),
              onCheckResult: _checkResult,
            ),
          ],
        ),
      ),
    );
  }
}

extension on PortalPage {
  String get label => switch (this) {
    PortalPage.unknown => 'Automy',
    PortalPage.login => 'Inicio de sesión',
    PortalPage.home => 'Inicio',
    PortalPage.clientForm => 'Formulario de cliente',
    PortalPage.productForm => 'Formulario de productos',
    PortalPage.review => 'Revisión',
    PortalPage.success => 'Resultado',
    PortalPage.error => 'Error de portal',
    PortalPage.sessionExpired => 'Sesión expirada',
  };
}

class _ReviewPanel extends StatelessWidget {
  const _ReviewPanel({
    required this.execution,
    required this.allowAutomaticSubmission,
    required this.onPrepare,
    required this.onCancel,
    required this.onCheckResult,
  });

  final Execution? execution;
  final bool allowAutomaticSubmission;
  final VoidCallback onPrepare;
  final VoidCallback onCancel;
  final VoidCallback onCheckResult;

  @override
  Widget build(BuildContext context) {
    final waitingReview = execution?.estado == ExecutionStatus.waitingForReview;
    final running =
        execution != null && !execution!.estado.isTerminal && !waitingReview;
    return Material(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (execution != null) ...[
              Text(execution!.estado.label),
              const SizedBox(height: 4),
              LinearProgressIndicator(value: execution!.progreso),
              const SizedBox(height: 8),
            ],
            if (waitingReview)
              const Text('Revise toda la información con paciencia y detalle.'),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                if (running)
                  OutlinedButton.icon(
                    onPressed: onCancel,
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Cancelar'),
                  ),
                if (waitingReview)
                  OutlinedButton.icon(
                    onPressed: onCheckResult,
                    icon: const Icon(Icons.fact_check_outlined),
                    label: const Text('Detectar resultado'),
                  ),
                FilledButton.icon(
                  onPressed: running ? null : onPrepare,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Preparar pedido'),
                ),
              ],
            ),
            if (!allowAutomaticSubmission)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'El envío automático está desactivado. Confirme el envío dentro de Automy.',
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DiagnosticSheet extends StatelessWidget {
  const _DiagnosticSheet({required this.data});

  final PortalDiagnostics data;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[
      ('URL', WebViewSecurityPolicy.displayUrl(data.url)),
      ('Host', data.host),
      ('Título', data.title),
      ('Carga', '${data.loadingProgress}%'),
      ('JavaScript', data.javascriptAvailable ? 'Activo' : 'Sin confirmar'),
      (
        'Cookies',
        data.cookiesAvailable ? 'Disponibles para el portal' : 'Sin confirmar',
      ),
      ('Iframes', '${data.iframeCount}'),
      ('Solicitudes de archivo', '${data.fileInputCount}'),
      ('Posibles popups', '${data.popupLinkCount}'),
      ('Página detectada', data.page.label),
      ('Fingerprint', '${AppConfig.fingerprintVersion}:${data.fingerprint}'),
      ('Motor', data.engineVersion),
      ('Versión de selectores', AppConfig.selectorVersion),
      ('Último error', data.lastError ?? 'Ninguno'),
    ];
    return SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        children: [
          Text(
            'Diagnóstico protegido',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'No se muestran cookies, credenciales, tokens ni contenido de formularios.',
          ),
          const SizedBox(height: 12),
          ...rows.map(
            (row) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(row.$1),
              subtitle: Text(row.$2),
            ),
          ),
        ],
      ),
    );
  }
}
