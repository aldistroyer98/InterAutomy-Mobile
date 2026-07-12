import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/client.dart';
import '../../../state/app_controller.dart';

class ClientsScreen extends ConsumerStatefulWidget {
  const ClientsScreen({super.key});

  @override
  ConsumerState<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends ConsumerState<ClientsScreen> {
  static const _newClientValue = '__new_client__';
  final _formKey = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{};
  String? _loadedClientId;

  @override
  void initState() {
    super.initState();
    for (final key in _fieldKeys) {
      _controllers[key] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  static const _fieldKeys = [
    'nombre',
    'nroOc',
    'archivoOc',
    'unidad',
    'servicio',
    'institucion',
    'departamento',
    'provincia',
    'distrito',
    'direccion',
    'contacto',
    'telefono',
    'comentarioFinal',
    'horaInicio',
    'horaFin',
    'motivo',
  ];

  TextEditingController _controller(String key) => _controllers[key]!;

  void _sync(Client? client) {
    if (client == null || client.id == _loadedClientId) return;
    _loadedClientId = client.id;
    final values = <String, String>{
      'nombre': client.nombre,
      'nroOc': client.nroOc,
      'archivoOc': client.archivoOc,
      'unidad': client.unidad,
      'servicio': client.servicio,
      'institucion': client.institucion,
      'departamento': client.departamento,
      'provincia': client.provincia,
      'distrito': client.distrito,
      'direccion': client.direccion,
      'contacto': client.contacto,
      'telefono': client.telefono,
      'comentarioFinal': client.comentarioFinal,
      'horaInicio': client.horaInicio,
      'horaFin': client.horaFin,
      'motivo': client.motivo,
    };
    for (final entry in values.entries) {
      _controller(entry.key).text = entry.value;
    }
  }

  void _commitTextFields() {
    final client = ref.read(appControllerProvider).selectedClient;
    if (client == null) return;
    ref
        .read(appControllerProvider.notifier)
        .updateClient(
          client.copyWith(
            nombre: _controller('nombre').text,
            nroOc: _controller('nroOc').text,
            archivoOc: _controller('archivoOc').text,
            unidad: _controller('unidad').text,
            servicio: _controller('servicio').text,
            institucion: _controller('institucion').text,
            departamento: _controller('departamento').text,
            provincia: _controller('provincia').text,
            distrito: _controller('distrito').text,
            direccion: _controller('direccion').text,
            contacto: _controller('contacto').text,
            telefono: _controller('telefono').text,
            comentarioFinal: _controller('comentarioFinal').text,
            horaInicio: _controller('horaInicio').text,
            horaFin: _controller('horaFin').text,
            motivo: _controller('motivo').text,
          ),
        );
  }

  Future<void> _save() async {
    _commitTextFields();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final saved = await ref.read(appControllerProvider.notifier).saveClient();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved ? 'Cliente guardado.' : 'No se pudo guardar el cliente.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appControllerProvider);
    final client = appState.selectedClient;
    _sync(client);
    final isSaved =
        client != null && appState.clients.any((item) => item.id == client.id);
    final selectedValue = client == null
        ? null
        : (isSaved ? client.id : _newClientValue);

    return Form(
      key: _formKey,
      child: CustomScrollView(
        key: const PageStorageKey('clients-scroll'),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            sliver: SliverToBoxAdapter(
              child: DropdownButtonFormField<String>(
                key: const Key('client-selector'),
                initialValue: selectedValue,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Cliente',
                  prefixIcon: Icon(Icons.apartment),
                ),
                items: [
                  ...appState.clients.map(
                    (item) => DropdownMenuItem(
                      value: item.id,
                      child: Text(item.nombre),
                    ),
                  ),
                  const DropdownMenuItem(
                    value: _newClientValue,
                    child: Text('Nuevo cliente'),
                  ),
                ],
                onChanged: (value) {
                  if (value == _newClientValue) {
                    ref
                        .read(appControllerProvider.notifier)
                        .createNewClientDraft();
                    return;
                  }
                  final matches = appState.clients.where(
                    (item) => item.id == value,
                  );
                  if (matches.isNotEmpty) {
                    ref
                        .read(appControllerProvider.notifier)
                        .selectClient(matches.first);
                  }
                },
              ),
            ),
          ),
          if (client != null)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              sliver: SliverList.list(
                children: [
                  _section(
                    context,
                    title: 'Datos principales',
                    icon: Icons.badge_outlined,
                    fields: [
                      _textField(
                        'nombre',
                        'Nombre del cliente',
                        required: true,
                      ),
                      _textField('unidad', 'Unidad'),
                      _textField('servicio', 'Servicio'),
                    ],
                  ),
                  _section(
                    context,
                    title: 'Orden de compra',
                    icon: Icons.description_outlined,
                    fields: [
                      _textField('nroOc', 'NRO OC'),
                      _textField(
                        'archivoOc',
                        'Archivo OC',
                        hint: 'Referencia del archivo',
                      ),
                    ],
                  ),
                  _section(
                    context,
                    title: 'Institución y ubicación',
                    icon: Icons.location_city_outlined,
                    fields: [
                      _textField('institucion', 'Institución'),
                      _textField('departamento', 'Departamento'),
                      _textField('provincia', 'Provincia'),
                      _textField('distrito', 'Distrito'),
                      _textField('direccion', 'Dirección'),
                    ],
                  ),
                  _section(
                    context,
                    title: 'Contacto',
                    icon: Icons.contact_phone_outlined,
                    fields: [
                      _textField('contacto', 'Contacto'),
                      _textField(
                        'telefono',
                        'Teléfono',
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          final digits = (value ?? '').replaceAll(
                            RegExp(r'\D'),
                            '',
                          );
                          if (digits.isNotEmpty && digits.length < 7) {
                            return 'Ingresa un teléfono válido.';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                  _commercialSection(context, client),
                  _section(
                    context,
                    title: 'Comentario final',
                    icon: Icons.notes_outlined,
                    fields: [
                      _textField(
                        'comentarioFinal',
                        'Comentario final',
                        maxLines: 4,
                      ),
                    ],
                  ),
                  FilledButton.icon(
                    key: const Key('save-client'),
                    onPressed: _save,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Guardar cliente'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _commercialSection(BuildContext context, Client client) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle(
              icon: Icons.payments_outlined,
              text: 'Condiciones comerciales',
            ),
            const SizedBox(height: 16),
            _ResponsiveFields(
              children: [
                _textField('horaInicio', 'Hora de inicio'),
                _textField('horaFin', 'Hora de fin'),
                DropdownButtonFormField<String>(
                  initialValue: client.moneda,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Moneda'),
                  items: const [
                    DropdownMenuItem(value: 'Soles', child: Text('Soles')),
                    DropdownMenuItem(value: 'Dólares', child: Text('Dólares')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      ref
                          .read(appControllerProvider.notifier)
                          .updateClient(client.copyWith(moneda: value));
                    }
                  },
                ),
                _textField('motivo', 'Motivo'),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Aplicar IGV'),
              value: client.igv,
              onChanged: (value) => ref
                  .read(appControllerProvider.notifier)
                  .updateClient(client.copyWith(igv: value)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Regularizar adelanto'),
              value: client.adelanto,
              onChanged: (value) => ref
                  .read(appControllerProvider.notifier)
                  .updateClient(client.copyWith(adelanto: value)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Dirección nueva'),
              value: client.direccionNueva,
              onChanged: (value) => ref
                  .read(appControllerProvider.notifier)
                  .updateClient(client.copyWith(direccionNueva: value)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Contacto nuevo'),
              value: client.contactoNuevo,
              onChanged: (value) => ref
                  .read(appControllerProvider.notifier)
                  .updateClient(client.copyWith(contactoNuevo: value)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> fields,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(icon: icon, text: title),
            const SizedBox(height: 16),
            _ResponsiveFields(children: fields),
          ],
        ),
      ),
    );
  }

  Widget _textField(
    String key,
    String label, {
    bool required = false,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      key: Key('client-$key'),
      controller: _controller(key),
      decoration: InputDecoration(labelText: label, hintText: hint),
      maxLines: maxLines,
      keyboardType: keyboardType,
      textInputAction: maxLines > 1
          ? TextInputAction.newline
          : TextInputAction.next,
      onChanged: (_) => _commitTextFields(),
      validator:
          validator ??
          (required
              ? (value) => (value == null || value.trim().isEmpty)
                    ? 'Este campo es obligatorio.'
                    : null
              : null),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.titleMedium),
        ),
      ],
    );
  }
}

class _ResponsiveFields extends StatelessWidget {
  const _ResponsiveFields({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 700 ? 2 : 1;
        final width = columns == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: children
              .map((child) => SizedBox(width: width, child: child))
              .toList(),
        );
      },
    );
  }
}
