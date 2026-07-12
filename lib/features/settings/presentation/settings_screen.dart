import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../domain/entities/app_settings.dart';
import '../../../state/app_controller.dart';
import '../../../state/providers.dart';

enum _ConnectionState { idle, testing, reachable, unreachable }

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiController = TextEditingController();
  late final Future<PackageInfo> _packageInfo;
  String? _loadedUrl;
  _ConnectionState _connection = _ConnectionState.idle;

  @override
  void initState() {
    super.initState();
    _packageInfo = PackageInfo.fromPlatform();
  }

  @override
  void dispose() {
    _apiController.dispose();
    super.dispose();
  }

  void _syncUrl(String value) {
    if (_loadedUrl == value) return;
    _loadedUrl = value;
    _apiController.text = value;
  }

  String? _validateUrl(String? value) {
    final uri = Uri.tryParse(value?.trim() ?? '');
    if (uri == null ||
        !uri.hasAuthority ||
        !{'http', 'https'}.contains(uri.scheme)) {
      return 'Ingresa una URL HTTP o HTTPS válida.';
    }
    return null;
  }

  Future<void> _saveApiUrl(AppSettings settings) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final value = _apiController.text.trim().replaceFirst(RegExp(r'/+$'), '');
    await ref
        .read(appControllerProvider.notifier)
        .updateSettings(settings.copyWith(apiUrl: value));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('URL de API guardada.')));
  }

  Future<void> _testConnection(AppSettings settings) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _connection = _ConnectionState.testing);
    final reachable = await ref
        .read(connectivityServiceProvider)
        .canReach(_apiController.text.trim());
    if (!mounted) return;
    setState(
      () => _connection = reachable
          ? _ConnectionState.reachable
          : _ConnectionState.unreachable,
    );
  }

  Future<void> _toggleDemo(AppSettings settings, bool enabled) async {
    if (!enabled) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Desactivar modo demostración'),
          content: const Text(
            'Los repositorios remotos aún están desactivados. Podrás probar la conexión, '
            'pero no ejecutar pedidos hasta publicar la API.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Desactivar'),
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

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appControllerProvider).settings;
    _syncUrl(settings.apiUrl);
    final connectionIcon = switch (_connection) {
      _ConnectionState.idle => Icons.cloud_outlined,
      _ConnectionState.testing => Icons.sync,
      _ConnectionState.reachable => Icons.cloud_done_outlined,
      _ConnectionState.unreachable => Icons.cloud_off_outlined,
    };
    final connectionText = switch (_connection) {
      _ConnectionState.idle => 'Conectividad no comprobada',
      _ConnectionState.testing => 'Probando conexión…',
      _ConnectionState.reachable => 'Servidor accesible',
      _ConnectionState.unreachable => 'No se pudo acceder al servidor',
    };

    return Form(
      key: _formKey,
      child: ListView(
        key: const PageStorageKey('settings-scroll'),
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: SwitchListTile(
              key: const Key('demo-mode-switch'),
              secondary: const Icon(Icons.science_outlined),
              title: const Text('Modo demostración'),
              subtitle: const Text(
                'Usa clientes, catálogo y ejecución simulados en el dispositivo.',
              ),
              value: settings.demoMode,
              onChanged: (value) => _toggleDemo(settings, value),
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
                    'API futura',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'La URL se conserva localmente. Los repositorios remotos permanecerán '
                    'desactivados hasta que exista un contrato de servidor validado.',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('api-url-field'),
                    controller: _apiController,
                    decoration: const InputDecoration(
                      labelText: 'URL de API',
                      prefixIcon: Icon(Icons.link),
                    ),
                    keyboardType: TextInputType.url,
                    autocorrect: false,
                    validator: _validateUrl,
                    onChanged: (_) =>
                        setState(() => _connection = _ConnectionState.idle),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: _connection == _ConnectionState.testing
                        ? const SizedBox.square(
                            dimension: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(connectionIcon),
                    title: Text(connectionText),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _connection == _ConnectionState.testing
                            ? null
                            : () => _testConnection(settings),
                        icon: const Icon(Icons.network_check),
                        label: const Text('Probar conexión'),
                      ),
                      FilledButton.icon(
                        onPressed: () => _saveApiUrl(settings),
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Guardar URL'),
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
              leading: Icon(Icons.desktop_windows_outlined),
              title: Text('Agente Windows requerido'),
              subtitle: Text(
                'La automatización real se ejecutará en un agente Windows autorizado. '
                'Esta aplicación móvil nunca ejecuta Selenium ni ChromeDriver.',
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
                      ? '${snapshot.data!.version} (${snapshot.data!.buildNumber})'
                      : 'Consultando versión…',
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No se almacenan contraseñas ni secretos reales. El almacenamiento seguro está '
            'reservado para futuros tokens emitidos por la API.',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
