import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../app/app_config.dart';
import '../../../core/security/webview_security_policy.dart';
import '../../../domain/entities/app_settings.dart';
import '../../../state/app_controller.dart';
import '../../../state/providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _portalController = TextEditingController();
  final _hostsController = TextEditingController();
  late final Future<PackageInfo> _packageInfo;
  String? _loadedPortalUrl;

  @override
  void initState() {
    super.initState();
    _packageInfo = PackageInfo.fromPlatform();
  }

  @override
  void dispose() {
    _portalController.dispose();
    _hostsController.dispose();
    super.dispose();
  }

  void _sync(AppSettings settings) {
    if (_loadedPortalUrl == settings.portalUrl) return;
    _loadedPortalUrl = settings.portalUrl;
    _portalController.text = settings.portalUrl;
    _hostsController.text = settings.additionalAllowedHosts.join(', ');
  }

  String? _validatePortalUrl(String? value) {
    if ((value ?? '').trim().isEmpty) return null;
    if (WebViewSecurityPolicy.parsePortalUrl(value!) == null) {
      return 'Usa una URL HTTPS sin usuario ni contraseña.';
    }
    return null;
  }

  String? _validateHosts(String? value) =>
      WebViewSecurityPolicy.parseAdditionalHosts(value ?? '') == null
      ? 'Escribe hosts separados por coma, sin rutas ni protocolos.'
      : null;

  Future<bool> _savePortal(AppSettings settings) async {
    if (!(_formKey.currentState?.validate() ?? false)) return false;
    final rawPortal = _portalController.text.trim();
    final portal = rawPortal.isEmpty
        ? ''
        : WebViewSecurityPolicy.parsePortalUrl(rawPortal)!.toString();
    final hosts = WebViewSecurityPolicy.parseAdditionalHosts(
      _hostsController.text,
    )!;
    await ref
        .read(appControllerProvider.notifier)
        .updateSettings(
          settings.copyWith(portalUrl: portal, additionalAllowedHosts: hosts),
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configuración de Automy guardada.')),
      );
    }
    return true;
  }

  Future<void> _toggleDemo(AppSettings settings, bool enabled) async {
    if (!enabled && !settings.hasPortalConfiguration) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Guarda primero una URL HTTPS de Automy.'),
        ),
      );
      return;
    }
    if (!enabled) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Activar navegador integrado'),
          content: const Text(
            'Automy se abrirá dentro de la aplicación. El inicio de sesión y el envío final siguen siendo manuales.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Activar'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    await ref
        .read(appControllerProvider.notifier)
        .updateSettings(settings.copyWith(demoMode: enabled));
  }

  Future<void> _clearSession() async {
    await ref.read(webViewAutomationGatewayProvider).clearSession();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cookies, caché y almacenamiento web eliminados.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appControllerProvider).settings;
    _sync(settings);
    return Form(
      key: _formKey,
      child: ListView(
        key: const PageStorageKey('settings-scroll'),
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Modo del portal',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<bool>(
                    key: const Key('portal-mode-selector'),
                    segments: const [
                      ButtonSegment(
                        value: true,
                        icon: Icon(Icons.science_outlined),
                        label: Text('Demo'),
                      ),
                      ButtonSegment(
                        value: false,
                        icon: Icon(Icons.web_outlined),
                        label: Text('Automy WebView'),
                      ),
                    ],
                    selected: {settings.demoMode},
                    onSelectionChanged: (value) =>
                        _toggleDemo(settings, value.first),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    settings.demoMode
                        ? 'Clientes, catálogo y ejecución simulados en el dispositivo.'
                        : 'Login, navegación y envío manuales dentro del WebView protegido.',
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
                    'Portal Automy',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'La aplicación solo permite HTTPS y ejecuta scripts locales únicamente en estos hosts. No se usa API, servidor ni PC intermediaria.',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('portal-url-field'),
                    controller: _portalController,
                    decoration: const InputDecoration(
                      labelText: 'URL HTTPS de Automy',
                      hintText: 'https://portal.ejemplo.pe',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    keyboardType: TextInputType.url,
                    autocorrect: false,
                    validator: _validatePortalUrl,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('additional-hosts-field'),
                    controller: _hostsController,
                    decoration: const InputDecoration(
                      labelText: 'Hosts de autenticación adicionales',
                      helperText:
                          'Opcional; separados por coma y sin https://.',
                      prefixIcon: Icon(Icons.account_tree_outlined),
                    ),
                    autocorrect: false,
                    validator: _validateHosts,
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: () => _savePortal(settings),
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Guardar portal'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout_outlined),
              title: const Text('Cerrar sesión de Automy'),
              subtitle: const Text(
                'Elimina cookies, caché y almacenamiento web local.',
              ),
              trailing: OutlinedButton(
                onPressed: _clearSession,
                child: const Text('Limpiar sesión'),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  key: const Key('developer-mode-switch'),
                  secondary: const Icon(Icons.developer_mode_outlined),
                  title: const Text('Modo desarrollador'),
                  subtitle: const Text(
                    'Habilita Inspector Web y la prueba manual de NRO OC.',
                  ),
                  value: settings.developerMode,
                  onChanged: (value) => ref
                      .read(appControllerProvider.notifier)
                      .updateSettings(
                        settings.copyWith(
                          developerMode: value,
                          diagnosticMode: value
                              ? settings.diagnosticMode
                              : false,
                        ),
                      ),
                ),
                if (settings.developerMode) ...[
                  const Divider(height: 1),
                  SwitchListTile(
                    key: const Key('diagnostic-mode-switch'),
                    secondary: const Icon(Icons.monitor_heart_outlined),
                    title: const Text('Modo diagnóstico'),
                    subtitle: const Text(
                      'Muestra señales técnicas sanitizadas del portal.',
                    ),
                    value: settings.diagnosticMode,
                    onChanged: (value) => ref
                        .read(appControllerProvider.notifier)
                        .updateSettings(
                          settings.copyWith(diagnosticMode: value),
                        ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    key: const Key('open-web-inspector'),
                    leading: const Icon(Icons.troubleshoot_outlined),
                    title: const Text('Inspector Web'),
                    subtitle: const Text(
                      'Disponible con el portal abierto para diagnóstico y NRO OC.',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/inspector'),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Tema', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  SegmentedButton<AppThemePreference>(
                    key: const Key('theme-selector'),
                    segments: AppThemePreference.values
                        .map(
                          (theme) => ButtonSegment(
                            value: theme,
                            label: Text(theme.label),
                            icon: Icon(switch (theme) {
                              AppThemePreference.system =>
                                Icons.brightness_auto,
                              AppThemePreference.light =>
                                Icons.light_mode_outlined,
                              AppThemePreference.dark =>
                                Icons.dark_mode_outlined,
                            }),
                          ),
                        )
                        .toList(growable: false),
                    selected: {settings.theme},
                    onSelectionChanged: (selection) => ref
                        .read(appControllerProvider.notifier)
                        .updateSettings(
                          settings.copyWith(theme: selection.first),
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: const ListTile(
              leading: Icon(Icons.shield_outlined),
              title: Text('Envío automático desactivado'),
              subtitle: Text(
                'La confirmación final siempre se realiza manualmente dentro de Automy.',
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: FutureBuilder<PackageInfo>(
              future: _packageInfo,
              builder: (context, snapshot) => ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Versión de InterAutomy'),
                subtitle: Text(
                  snapshot.hasData
                      ? '${snapshot.data!.version} (${snapshot.data!.buildNumber}) · ${AppConfig.workflowVersion}'
                      : 'Consultando versión…',
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No se almacenan contraseñas, cookies legibles ni secretos. El motor no usa Selenium, ChromeDriver, accesibilidad ni automatización por coordenadas.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
