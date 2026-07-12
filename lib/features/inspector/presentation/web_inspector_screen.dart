import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_config.dart';
import '../../../automation/nro_oc/nro_oc_automation_service.dart';
import '../../../automation/logging/automation_log_sanitizer.dart';
import '../../../automation/webview/portal_diagnostics.dart';
import '../../../automation/webview_automation_gateway.dart';
import '../../../core/security/webview_security_policy.dart';
import '../../../state/app_controller.dart';
import '../../../state/providers.dart';

class WebInspectorScreen extends ConsumerStatefulWidget {
  const WebInspectorScreen({super.key});

  @override
  ConsumerState<WebInspectorScreen> createState() => _WebInspectorScreenState();
}

class _WebInspectorScreenState extends ConsumerState<WebInspectorScreen> {
  final _valueController = TextEditingController();
  bool _busy = false;
  String _result = 'Sin prueba ejecutada';

  WebViewAutomationGateway get _gateway =>
      ref.read(webViewAutomationGatewayProvider);

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  Future<void> _run(Future<String> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final result = await action();
      if (mounted) setState(() => _result = result);
    } catch (error) {
      if (mounted) setState(() => _result = 'ERROR: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _automationMessage(NroOcAutomationResult result) =>
      '${result.code}: ${result.message}';

  @override
  Widget build(BuildContext context) {
    final gateway = ref.watch(webViewAutomationGatewayProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Validación Automy')),
      body: ValueListenableBuilder<PortalDiagnostics>(
        valueListenable: gateway.diagnostics,
        builder: (context, data, _) => ListView(
          key: const Key('web-inspector-list'),
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    FilledButton.icon(
                      key: const Key('open-real-portal'),
                      onPressed: () {
                        final settings = ref
                            .read(appControllerProvider)
                            .settings;
                        if (!settings.hasPortalConfiguration) {
                          context.go('/settings');
                        } else {
                          context.push('/portal');
                        }
                      },
                      icon: const Icon(Icons.open_in_browser_outlined),
                      label: const Text('Abrir portal'),
                    ),
                    const Chip(
                      avatar: Icon(Icons.block_outlined, size: 18),
                      label: Text('Envío desactivado'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            ValueListenableBuilder(
              valueListenable: gateway.sessionValidation,
              builder: (context, session, _) => Card(
                key: const Key('session-validation-card'),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sesión real',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Detectada: ${session.sessionDetected ? 'Sí' : 'No'}',
                      ),
                      Text(
                        'Tras cerrar Portal: ${session.persistedAfterPortalClose ? 'Sí' : 'No probado'}',
                      ),
                      Text(
                        'Tras segundo plano: ${session.persistedAfterBackground ? 'Sí' : 'No probado'}',
                      ),
                      Text(
                        'Tras reiniciar app: ${session.persistedAfterAppRestart ? 'Sí' : 'No probado'}',
                      ),
                      Text('Expirada: ${session.expired ? 'Sí' : 'No'}'),
                      Text(
                        'Cookies limpiadas: ${session.cookiesCleared ? 'Sí' : 'No'}',
                      ),
                      if (session.notes.isNotEmpty) Text(session.notes),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          key: const Key('mark-logout-verified'),
                          onPressed: _gateway.markLogoutVerified,
                          child: const Text('Marcar logout verificado'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _StatusCard(data: data),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Diagnóstico protegido',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'No extrae cookies, credenciales, valores, HTML ni texto completo del portal.',
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          key: const Key('refresh-web-diagnostic'),
                          onPressed: _busy
                              ? null
                              : () => _run(() async {
                                  await _gateway.refreshDiagnostics();
                                  return 'DIAGNOSTIC_COMPLETED';
                                }),
                          icon: const Icon(Icons.monitor_heart_outlined),
                          label: const Text('Ejecutar diagnóstico'),
                        ),
                        OutlinedButton.icon(
                          key: const Key('export-web-diagnostic'),
                          onPressed: _busy || data.url == null
                              ? null
                              : () => _run(() async {
                                  final path = await _gateway
                                      .exportDiagnostics();
                                  return 'Diagnóstico exportado: $path';
                                }),
                          icon: const Icon(Icons.file_download_outlined),
                          label: const Text('Exportar JSON'),
                        ),
                        OutlinedButton.icon(
                          key: const Key('clear-real-session'),
                          onPressed: _busy
                              ? null
                              : () => _run(() async {
                                  await _gateway.clearSession();
                                  return 'SESSION_CLEARED';
                                }),
                          icon: const Icon(Icons.logout_outlined),
                          label: const Text('Limpiar sesión'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Prueba manual NRO OC',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Solo modifica NRO OC. No completa otros campos y no envía el formulario.',
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const Key('nro-oc-test-value'),
                      controller: _valueController,
                      decoration: const InputDecoration(
                        labelText: 'Valor de prueba',
                        border: OutlineInputBorder(),
                      ),
                      autocorrect: false,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton(
                          key: const Key('detect-nro-oc'),
                          onPressed: _busy
                              ? null
                              : () => _run(() async {
                                  final probe = await _gateway.detectNroOc();
                                  return probe.code;
                                }),
                          child: const Text('Detectar campo'),
                        ),
                        FilledButton(
                          key: const Key('complete-nro-oc'),
                          onPressed: _busy
                              ? null
                              : () => _run(() async {
                                  final result = await _gateway.completeNroOc(
                                    _valueController.text,
                                  );
                                  return _automationMessage(result);
                                }),
                          child: const Text('Completar NRO OC'),
                        ),
                        OutlinedButton(
                          key: const Key('verify-nro-oc'),
                          onPressed: _busy
                              ? null
                              : () => _run(() async {
                                  final result = await _gateway.verifyNroOc(
                                    _valueController.text,
                                  );
                                  return _automationMessage(result);
                                }),
                          child: const Text('Verificar valor'),
                        ),
                        TextButton(
                          key: const Key('clear-nro-oc'),
                          onPressed: _busy
                              ? null
                              : () => _run(() async {
                                  final result = await _gateway
                                      .clearNroOcTest();
                                  if (result.success) _valueController.clear();
                                  return _automationMessage(result);
                                }),
                          child: const Text('Limpiar prueba'),
                        ),
                        if (_busy)
                          TextButton.icon(
                            onPressed: _gateway.cancelNroOcTest,
                            icon: const Icon(Icons.cancel_outlined),
                            label: const Text('Cancelar'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_busy) const LinearProgressIndicator(),
                    Text(_result, key: const Key('nro-oc-result')),
                    const SizedBox(height: 8),
                    Text(
                      'Valor en bitácora: ${AutomationLogSanitizer.maskValue(_valueController.text)}',
                    ),
                    Text(
                      'Selector lógico: ${data.selectorProbe.logicalKey}\n'
                      'Alternativa: ${data.selectorProbe.alternativeIndex ?? '-'}\n'
                      'Tiempo: ${data.selectorProbe.elapsedMilliseconds} ms · '
                      'Reintentos: ${data.selectorProbe.retries}',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            ValueListenableBuilder(
              valueListenable: gateway.navigationLog,
              builder: (context, events, _) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Navegación sanitizada',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      if (events.isEmpty)
                        const Text('Sin eventos de navegación.')
                      else
                        ...events.reversed
                            .take(10)
                            .map(
                              (event) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                title: Text(
                                  '${event.type.name} · ${event.decision}',
                                ),
                                subtitle: Text(
                                  '${event.toHost}${event.toUrl.isEmpty ? '' : ' · ${event.toUrl}'}\n${event.reason}',
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.data});

  final PortalDiagnostics data;

  @override
  Widget build(BuildContext context) {
    final structure = data.structure;
    final rows = <(String, String)>[
      (
        'Estado de carga',
        data.isLoading
            ? 'Cargando ${data.loadingProgress}%'
            : '${data.loadingProgress}%',
      ),
      ('URL sanitizada', WebViewSecurityPolicy.displayUrl(data.url)),
      ('Host', data.host),
      ('Esquema', data.scheme),
      ('Puerto', data.port),
      ('Título', data.title),
      ('Página detectada', data.page.name),
      (
        'Fingerprint',
        '${data.portalFingerprint.version}:${data.fingerprint.isEmpty ? 'Sin calcular' : data.fingerprint}',
      ),
      (
        'Estructura reconocida',
        data.portalFingerprint.recognized ? 'Sí' : 'No',
      ),
      (
        'Framework',
        '${data.framework.name} (${(data.framework.confidence * 100).round()}%)',
      ),
      ('JavaScript', data.javascriptAvailable ? 'Disponible' : 'Sin confirmar'),
      (
        'Iframes',
        '${data.frames.total} (${data.frames.crossOrigin} cross-origin)',
      ),
      ('Formularios', '${structure.forms}'),
      ('Inputs', '${structure.inputs}'),
      ('Selects', '${structure.selects}'),
      ('Botones', '${structure.buttons}'),
      ('Tablas', '${structure.tables}'),
      ('Inputs file', '${structure.fileInputs}'),
      ('Shadow Roots abiertos', '${data.shadowDom.count}'),
      ('Popup detectado', data.popup.detected ? 'Sí' : 'No'),
      (
        'sessionStorage',
        data.storage.sessionStorage ? 'Disponible' : 'No disponible',
      ),
      (
        'localStorage',
        data.storage.localStorage ? 'Disponible' : 'No disponible',
      ),
      ('Cookies', data.storage.cookies ? 'Disponibles' : 'No disponibles'),
      ('Último selector lógico', data.lastSelectorLogical ?? 'Ninguno'),
      (
        'Tipo/tag selector',
        '${data.selectorProbe.elementType}/${data.selectorProbe.tag}',
      ),
      ('Dentro de iframe', data.selectorProbe.insideIframe ? 'Sí' : 'No'),
      (
        'Dentro de Shadow DOM',
        data.selectorProbe.insideShadowDom ? 'Sí' : 'No',
      ),
      (
        'Validación del campo',
        data.selectorProbe.validationError
            ? 'Error: ${data.selectorProbe.validationSignal}'
            : 'Sin error detectado',
      ),
      ('Último paso', data.lastStep ?? 'Ninguno'),
      ('Último error sanitizado', data.lastError ?? 'Ninguno'),
      ('Workflow', AppConfig.workflowVersion),
      ('Selectores', AppConfig.selectorVersion),
      ('Scripts', AppConfig.scriptVersion),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Estado del portal',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            ...rows.map(
              (row) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.$1,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    SelectableText(row.$2),
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
