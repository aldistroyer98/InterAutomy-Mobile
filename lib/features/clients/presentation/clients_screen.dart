import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../automation/upload/file_picker_service.dart';
import '../../../domain/entities/catalog_readiness.dart';
import '../../../domain/entities/client.dart';
import '../../../domain/entities/institution.dart';
import '../../../domain/entities/order_profile.dart';
import '../../../state/app_controller.dart';
import '../../../state/app_state.dart';

class ClientsScreen extends ConsumerStatefulWidget {
  const ClientsScreen({super.key});

  @override
  ConsumerState<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends ConsumerState<ClientsScreen> {
  static const _newClientValue = '__new_client__';
  static const _newInstitutionValue = '__new_institution__';
  static const _uuid = Uuid();
  final _formKey = GlobalKey<FormState>();
  final _filePicker = FilePickerService();
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
    'unidad',
    'servicio',
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

  void _sync(Client? client, {bool force = false}) {
    if (client == null || (!force && client.id == _loadedClientId)) return;
    _loadedClientId = client.id;
    final values = <String, String>{
      'nombre': client.nombre,
      'nroOc': client.nroOc,
      'unidad': client.unidad,
      'servicio': client.servicio,
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
            unidad: _controller('unidad').text,
            servicio: _controller('servicio').text,
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

  Future<void> _pickPurchaseOrderFile() async {
    final client = ref.read(appControllerProvider).selectedClient;
    if (client == null) return;
    try {
      final document = await _filePicker.pickPurchaseOrderFile();
      if (document == null) return;
      ref
          .read(appControllerProvider.notifier)
          .updateClient(
            client.copyWith(
              archivoOc: document.uri,
              archivoOcNombre: document.displayName,
              archivoOcMimeType: document.mimeType,
            ),
          );
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo seleccionar el archivo OC.')),
      );
    }
  }

  Future<void> _openPurchaseOrderFile(Client client) async {
    try {
      await _filePicker.openDocument(
        uri: client.archivoOc,
        mimeType: client.archivoOcMimeType,
      );
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el archivo OC.')),
      );
    }
  }

  Future<void> _editInstitution([Institution? existing]) async {
    final client = ref.read(appControllerProvider).selectedClient;
    if (client == null) return;
    final institution = await showDialog<Institution>(
      context: context,
      builder: (context) => _InstitutionEditorDialog(
        institution:
            existing ??
            Institution(
              id: _uuid.v4(),
              nombre: client.institucion,
              departamento: client.departamento,
              provincia: client.provincia,
              distrito: client.distrito,
              direccion: client.direccion,
              contacto: client.contacto,
              telefono: client.telefono,
            ),
      ),
    );
    if (institution == null) return;
    final saved = await ref
        .read(appControllerProvider.notifier)
        .saveInstitution(institution);
    if (!mounted) return;
    if (!saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo guardar la institución.')),
      );
      return;
    }
    _sync(ref.read(appControllerProvider).selectedClient, force: true);
  }

  Future<String?> _promptProfileName({String initialValue = ''}) {
    final controller = TextEditingController(text: initialValue);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nombre del perfil'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(labelText: 'Perfil'),
          onSubmitted: (value) => Navigator.pop(context, value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
  }

  Future<void> _saveProfile({
    String? profileId,
    String initialName = '',
  }) async {
    _commitTextFields();
    final name = await _promptProfileName(initialValue: initialName);
    if (name == null || name.isEmpty) return;
    final saved = await ref
        .read(appControllerProvider.notifier)
        .saveProfile(name, profileId: profileId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved ? 'Perfil guardado.' : 'No se pudo guardar el perfil.',
        ),
      ),
    );
  }

  Future<void> _confirmDeleteProfile(OrderProfile profile) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar perfil'),
        content: Text('¿Eliminar el perfil "${profile.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (approved != true) return;
    final deleted = await ref
        .read(appControllerProvider.notifier)
        .deleteProfile(profile.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          deleted ? 'Perfil eliminado.' : 'No se pudo eliminar el perfil.',
        ),
      ),
    );
  }

  Future<void> _showProfileManager() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Consumer(
          builder: (context, ref, child) {
            final profiles = ref.watch(appControllerProvider).profiles;
            return SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.72,
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Perfiles locales'),
                    subtitle: const Text(
                      'Incluyen cliente, condiciones, comodatos y productos; nunca credenciales.',
                    ),
                    trailing: FilledButton.icon(
                      onPressed: _saveProfile,
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Guardar actual'),
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: profiles.isEmpty
                        ? const Center(
                            child: Text('Aún no hay perfiles guardados.'),
                          )
                        : ListView.separated(
                            itemCount: profiles.length,
                            separatorBuilder: (context, index) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final profile = profiles[index];
                              return ListTile(
                                title: Text(profile.name),
                                subtitle: Text(
                                  '${profile.client.nombre} · ${profile.products.length} producto(s)',
                                ),
                                onTap: () {
                                  ref
                                      .read(appControllerProvider.notifier)
                                      .loadProfile(profile);
                                  _sync(
                                    ref
                                        .read(appControllerProvider)
                                        .selectedClient,
                                    force: true,
                                  );
                                  Navigator.pop(sheetContext);
                                },
                                trailing: PopupMenuButton<String>(
                                  onSelected: (action) async {
                                    switch (action) {
                                      case 'rename':
                                        await _saveProfile(
                                          profileId: profile.id,
                                          initialName: profile.name,
                                        );
                                      case 'duplicate':
                                        await _saveProfile(
                                          initialName: '${profile.name} copia',
                                        );
                                      case 'delete':
                                        await _confirmDeleteProfile(profile);
                                    }
                                  },
                                  itemBuilder: (context) => const [
                                    PopupMenuItem(
                                      value: 'rename',
                                      child: Text('Renombrar'),
                                    ),
                                    PopupMenuItem(
                                      value: 'duplicate',
                                      child: Text('Duplicar actual'),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Eliminar'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
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
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
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
                          child: Text(
                            '${item.nombre} · ${item.readiness.statusLabel}',
                            overflow: TextOverflow.ellipsis,
                          ),
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
                  const SizedBox(height: 8),
                  if (client != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Tooltip(
                        message: client.readiness.reasonLabel,
                        child: Chip(
                          key: const Key('client-readiness'),
                          avatar: Icon(
                            client.readiness == CatalogReadiness.complete
                                ? Icons.check_circle_outline
                                : client.readiness ==
                                      CatalogReadiness.notExecutable
                                ? Icons.block_outlined
                                : Icons.warning_amber_outlined,
                            size: 18,
                          ),
                          label: Text(client.readiness.statusLabel),
                        ),
                      ),
                    ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      key: const Key('manage-profiles'),
                      onPressed: _showProfileManager,
                      icon: const Icon(Icons.bookmark_outline),
                      label: const Text('Perfiles'),
                    ),
                  ),
                ],
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
                      _purchaseOrderAttachment(client),
                    ],
                  ),
                  _institutionSection(context, appState, client),
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
                  SafeArea(
                    top: false,
                    child: Card(
                      margin: const EdgeInsets.only(top: 4),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  ref
                                      .read(appControllerProvider.notifier)
                                      .discardClientChanges();
                                  _sync(
                                    ref
                                        .read(appControllerProvider)
                                        .selectedClient,
                                    force: true,
                                  );
                                },
                                icon: const Icon(Icons.undo_outlined),
                                label: const Text('Descartar'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton.icon(
                                key: const Key('save-client'),
                                onPressed: _save,
                                icon: const Icon(Icons.save_outlined),
                                label: const Text('Guardar'),
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
        ],
      ),
    );
  }

  Widget _purchaseOrderAttachment(Client client) {
    if (!client.hasArchivoOc) {
      return OutlinedButton.icon(
        key: const Key('pick-purchase-order-file'),
        onPressed: _pickPurchaseOrderFile,
        icon: const Icon(Icons.attach_file_outlined),
        label: const Text('Seleccionar archivo OC'),
      );
    }
    final name = client.archivoOcNombre.trim().isEmpty
        ? 'Documento seleccionado'
        : client.archivoOcNombre;
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: const Icon(Icons.description_outlined),
        title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          client.archivoOcMimeType.trim().isEmpty
              ? 'Referencia local segura'
              : client.archivoOcMimeType,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Wrap(
          spacing: 0,
          children: [
            IconButton(
              tooltip: 'Abrir archivo OC',
              onPressed: () => _openPurchaseOrderFile(client),
              icon: const Icon(Icons.open_in_new_outlined),
            ),
            IconButton(
              tooltip: 'Cambiar archivo OC',
              onPressed: _pickPurchaseOrderFile,
              icon: const Icon(Icons.swap_horiz_outlined),
            ),
            IconButton(
              tooltip: 'Quitar archivo OC',
              onPressed: () => ref
                  .read(appControllerProvider.notifier)
                  .clearPurchaseOrderAttachment(),
              icon: const Icon(Icons.close_outlined),
            ),
          ],
        ),
      ),
    );
  }

  Widget _institutionSection(
    BuildContext context,
    AppState appState,
    Client client,
  ) {
    final institutions = appState.institutions;
    final selected = institutions
        .where((institution) => institution.id == client.institutionId)
        .firstOrNull;
    return _section(
      context,
      title: 'Institución y ubicación',
      icon: Icons.location_city_outlined,
      fields: [
        DropdownButtonFormField<String>(
          key: const Key('institution-selector'),
          initialValue: selected?.id,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Institución'),
          items: [
            ...institutions.map(
              (institution) => DropdownMenuItem(
                value: institution.id,
                child: Text(institution.nombre),
              ),
            ),
            const DropdownMenuItem(
              value: _newInstitutionValue,
              child: Text('Nueva institución'),
            ),
          ],
          onChanged: (value) async {
            if (value == _newInstitutionValue) {
              await _editInstitution();
              return;
            }
            final matches = institutions.where(
              (institution) => institution.id == value,
            );
            if (matches.isEmpty) return;
            ref
                .read(appControllerProvider.notifier)
                .selectInstitution(matches.first);
            _sync(ref.read(appControllerProvider).selectedClient, force: true);
          },
        ),
        if (selected == null && client.institucion.trim().isNotEmpty)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.info_outline),
            title: Text(client.institucion),
            subtitle: const Text('Institución heredada sin relación local'),
            trailing: IconButton(
              key: const Key('edit-institution'),
              tooltip: 'Convertir en institución local',
              onPressed: _editInstitution,
              icon: const Icon(Icons.edit_outlined),
            ),
          )
        else
          OutlinedButton.icon(
            key: const Key('edit-institution'),
            onPressed: selected == null
                ? _editInstitution
                : () => _editInstitution(selected),
            icon: const Icon(Icons.edit_outlined),
            label: Text(
              selected == null ? 'Crear institución' : 'Editar institución',
            ),
          ),
        _textField('departamento', 'Departamento'),
        _textField('provincia', 'Provincia'),
        _textField('distrito', 'Distrito'),
        _textField('direccion', 'Dirección'),
      ],
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
      child: ExpansionTile(
        key: PageStorageKey<String>('client-section-$title'),
        initiallyExpanded: true,
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _ResponsiveFields(children: fields),
          ),
        ],
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

class _InstitutionEditorDialog extends StatefulWidget {
  const _InstitutionEditorDialog({required this.institution});

  final Institution institution;

  @override
  State<_InstitutionEditorDialog> createState() =>
      _InstitutionEditorDialogState();
}

class _InstitutionEditorDialogState extends State<_InstitutionEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _department;
  late final TextEditingController _province;
  late final TextEditingController _district;
  late final TextEditingController _address;
  late final TextEditingController _contact;
  late final TextEditingController _phone;

  @override
  void initState() {
    super.initState();
    final value = widget.institution;
    _name = TextEditingController(text: value.nombre);
    _department = TextEditingController(text: value.departamento);
    _province = TextEditingController(text: value.provincia);
    _district = TextEditingController(text: value.distrito);
    _address = TextEditingController(text: value.direccion);
    _contact = TextEditingController(text: value.contacto);
    _phone = TextEditingController(text: value.telefono);
  }

  @override
  void dispose() {
    _name.dispose();
    _department.dispose();
    _province.dispose();
    _district.dispose();
    _address.dispose();
    _contact.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Institución'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  key: const Key('institution-name'),
                  controller: _name,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'El nombre es obligatorio.'
                      : null,
                ),
                TextFormField(
                  controller: _department,
                  decoration: const InputDecoration(labelText: 'Departamento'),
                ),
                TextFormField(
                  controller: _province,
                  decoration: const InputDecoration(labelText: 'Provincia'),
                ),
                TextFormField(
                  controller: _district,
                  decoration: const InputDecoration(labelText: 'Distrito'),
                ),
                TextFormField(
                  controller: _address,
                  decoration: const InputDecoration(labelText: 'Dirección'),
                ),
                TextFormField(
                  controller: _contact,
                  decoration: const InputDecoration(labelText: 'Contacto'),
                ),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Teléfono'),
                  validator: (value) {
                    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
                    return digits.isNotEmpty && digits.length < 7
                        ? 'Ingresa un teléfono válido.'
                        : null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (!(_formKey.currentState?.validate() ?? false)) return;
            Navigator.pop(
              context,
              widget.institution.copyWith(
                nombre: _name.text,
                departamento: _department.text,
                provincia: _province.text,
                distrito: _district.text,
                direccion: _address.text,
                contacto: _contact.text,
                telefono: _phone.text,
              ),
            );
          },
          child: const Text('Guardar institución'),
        ),
      ],
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
