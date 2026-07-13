import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../automation/logging/automation_log_sanitizer.dart';
import '../domain/entities/client.dart';
import '../domain/entities/commercial_line.dart';
import '../domain/entities/comodato.dart';
import '../domain/entities/execution.dart';
import '../domain/entities/history_record.dart';
import '../domain/entities/institution.dart';
import '../domain/entities/order.dart';
import '../domain/entities/order_profile.dart';
import '../domain/entities/product.dart';
import '../domain/services/automation_gateway.dart';
import '../domain/services/comodato_resolution_service.dart';
import '../domain/services/order_validation_service.dart';
import '../domain/validation/validation_result.dart';
import '../features/history/application/restore_mode.dart';
import 'app_state.dart';
import 'providers.dart';

final appControllerProvider = NotifierProvider<AppController, AppState>(
  AppController.new,
);

/// Coordina el pedido y la ejecucion, pero no es fuente de configuracion.
///
/// Los gateways dependen exclusivamente de [SettingsController]. Esta direccion
/// evita que la ejecucion tenga que volver a leer este controlador.
final class AppController extends Notifier<AppState> {
  static const _uuid = Uuid();
  static const _orderValidation = OrderValidationService();

  @override
  AppState build() => const AppState();

  Future<void> initialize() async {
    if (state.initialized || state.loading) return;
    state = state.copyWith(loading: true, clearError: true);
    try {
      await ref.read(settingsControllerProvider.notifier).initialize();
      final results = await Future.wait([
        ref.read(clientRepositoryProvider).getAll(),
        ref.read(productRepositoryProvider).getLines(),
        ref.read(productRepositoryProvider).getProducts(),
        ref.read(historyRepositoryProvider).search(),
        ref.read(institutionRepositoryProvider).getAll(),
        ref.read(profileRepositoryProvider).getAll(),
      ]);
      final clients = results[0] as List<Client>;
      state = state.copyWith(
        initialized: true,
        loading: false,
        clients: clients,
        lines: results[1] as List<CommercialLine>,
        catalog: results[2] as List<CatalogProduct>,
        history: results[3] as List<HistoryRecord>,
        institutions: results[4] as List<Institution>,
        profiles: results[5] as List<OrderProfile>,
        selectedClient: clients.isEmpty ? null : clients.first,
      );
    } catch (error, stackTrace) {
      state = state.copyWith(
        initialized: true,
        loading: false,
        errorCode: 'APP_INITIALIZATION_FAILED',
        errorMessage: 'No se pudo iniciar la aplicacion. Intentalo nuevamente.',
        developerErrorDetails: _developerDetails(error, stackTrace),
      );
    }
  }

  Future<void> reloadCatalogs() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final results = await Future.wait([
        ref.read(clientRepositoryProvider).getAll(),
        ref.read(productRepositoryProvider).getLines(),
        ref.read(productRepositoryProvider).getProducts(),
        ref.read(institutionRepositoryProvider).getAll(),
      ]);
      final clients = results[0] as List<Client>;
      state = state.copyWith(
        loading: false,
        clients: clients,
        lines: results[1] as List<CommercialLine>,
        catalog: results[2] as List<CatalogProduct>,
        institutions: results[3] as List<Institution>,
        selectedClient: clients.isEmpty ? null : clients.first,
        selectedProducts: const [],
      );
    } catch (error, stackTrace) {
      state = state.copyWith(
        loading: false,
        errorCode: 'CATALOG_LOAD_FAILED',
        errorMessage: 'Catalogo IA1 no disponible.',
        developerErrorDetails: _developerDetails(error, stackTrace),
      );
    }
  }

  void selectClient(Client client) {
    state = state.copyWith(selectedClient: client, clearError: true);
  }

  /// IA1 conserva las condiciones comerciales y el comentario al crear un
  /// cliente nuevo. Solo se reinician los datos que dependen del cliente.
  void createNewClientDraft() {
    final previous = state.selectedClient;
    final draft = Client(
      id: _uuid.v4(),
      nombre: '',
      comentarioFinal: previous?.comentarioFinal ?? '',
      direccionNueva: previous?.direccionNueva ?? false,
      contactoNuevo: previous?.contactoNuevo ?? false,
      horaInicio: previous?.horaInicio ?? '09:00',
      horaFin: previous?.horaFin ?? '10:00',
      igv: previous?.igv ?? false,
      moneda: previous?.moneda ?? 'Soles',
      adelanto: previous?.adelanto ?? false,
      motivo: previous?.motivo ?? 'SIN OC',
    );
    state = state.copyWith(selectedClient: draft, clearError: true);
  }

  void updateClient(Client client) {
    state = state.copyWith(selectedClient: client, clearError: true);
  }

  void discardClientChanges() {
    final selected = state.selectedClient;
    if (selected == null) return;
    final saved = state.clients.where((client) => client.id == selected.id);
    state = state.copyWith(
      selectedClient: saved.isEmpty ? null : saved.first,
      clearSelectedClient: saved.isEmpty,
      clearError: true,
    );
  }

  void selectInstitution(Institution institution) {
    final client = state.selectedClient;
    if (client == null) return;
    state = state.copyWith(
      selectedClient: client.copyWith(
        institutionId: institution.id,
        institucion: institution.nombre,
        departamento: institution.departamento,
        provincia: institution.provincia,
        distrito: institution.distrito,
        direccion: institution.direccion,
        contacto: institution.contacto,
        telefono: institution.telefono,
      ),
      clearError: true,
    );
  }

  Future<bool> saveInstitution(Institution institution) async {
    if (institution.nombre.trim().isEmpty) {
      state = state.copyWith(
        errorCode: 'INSTITUTION_NAME_REQUIRED',
        errorMessage: 'Escribe el nombre de la institución.',
      );
      return false;
    }
    try {
      final saved = await ref
          .read(institutionRepositoryProvider)
          .save(institution.copyWith(nombre: institution.nombre.trim()));
      final institutions = [...state.institutions];
      final index = institutions.indexWhere((item) => item.id == saved.id);
      if (index < 0) {
        institutions.add(saved);
      } else {
        institutions[index] = saved;
      }
      state = state.copyWith(
        institutions: List.unmodifiable(institutions),
        clearError: true,
      );
      selectInstitution(saved);
      return true;
    } catch (error, stackTrace) {
      state = state.copyWith(
        errorCode: 'INSTITUTION_SAVE_FAILED',
        errorMessage:
            'No se pudo guardar la institución. Inténtalo nuevamente.',
        developerErrorDetails: _developerDetails(error, stackTrace),
      );
      return false;
    }
  }

  void clearPurchaseOrderAttachment() {
    final client = state.selectedClient;
    if (client == null) return;
    updateClient(
      client.copyWith(
        archivoOc: '',
        archivoOcNombre: '',
        archivoOcMimeType: '',
      ),
    );
  }

  Future<bool> saveClient() async {
    final client = state.selectedClient;
    if (client == null || client.nombre.trim().isEmpty) {
      state = state.copyWith(
        errorCode: 'CLIENT_NAME_REQUIRED',
        errorMessage: 'Escribe el nombre del cliente.',
      );
      return false;
    }
    try {
      final saved = await ref.read(clientRepositoryProvider).save(client);
      final clients = [...state.clients];
      final index = clients.indexWhere((item) => item.id == saved.id);
      if (index == -1) {
        clients.add(saved);
      } else {
        clients[index] = saved;
      }
      state = state.copyWith(
        clients: List.unmodifiable(clients),
        selectedClient: saved,
        clearError: true,
      );
      return true;
    } catch (error, stackTrace) {
      state = state.copyWith(
        errorCode: 'CLIENT_SAVE_FAILED',
        errorMessage: 'No se pudo guardar el cliente. Intentalo nuevamente.',
        developerErrorDetails: _developerDetails(error, stackTrace),
      );
      return false;
    }
  }

  Future<bool> saveProfile(String name, {String? profileId}) async {
    final client = state.selectedClient;
    if (client == null || name.trim().isEmpty) {
      state = state.copyWith(
        errorCode: 'PROFILE_NAME_REQUIRED',
        errorMessage:
            'Escribe un nombre y selecciona un cliente para el perfil.',
      );
      return false;
    }
    final existing = profileId == null
        ? null
        : state.profiles
              .where((profile) => profile.id == profileId)
              .firstOrNull;
    final now = DateTime.now();
    final profile = OrderProfile(
      id: existing?.id ?? _uuid.v4(),
      name: name.trim(),
      client: client,
      products: List.unmodifiable(state.selectedProducts),
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    try {
      final saved = await ref.read(profileRepositoryProvider).save(profile);
      final profiles = [...state.profiles];
      final index = profiles.indexWhere((item) => item.id == saved.id);
      if (index < 0) {
        profiles.add(saved);
      } else {
        profiles[index] = saved;
      }
      state = state.copyWith(
        profiles: List.unmodifiable(profiles),
        clearError: true,
      );
      return true;
    } catch (error, stackTrace) {
      state = state.copyWith(
        errorCode: 'PROFILE_SAVE_FAILED',
        errorMessage: 'No se pudo guardar el perfil. Inténtalo nuevamente.',
        developerErrorDetails: _developerDetails(error, stackTrace),
      );
      return false;
    }
  }

  Future<bool> deleteProfile(String id) async {
    try {
      await ref.read(profileRepositoryProvider).delete(id);
      state = state.copyWith(
        profiles: List.unmodifiable(
          state.profiles.where((profile) => profile.id != id),
        ),
        clearError: true,
      );
      return true;
    } catch (error, stackTrace) {
      state = state.copyWith(
        errorCode: 'PROFILE_DELETE_FAILED',
        errorMessage: 'No se pudo eliminar el perfil. Inténtalo nuevamente.',
        developerErrorDetails: _developerDetails(error, stackTrace),
      );
      return false;
    }
  }

  void loadProfile(OrderProfile profile) {
    final clients = [...state.clients];
    if (clients.every((client) => client.id != profile.client.id)) {
      clients.add(profile.client);
    }
    state = state.copyWith(
      clients: List.unmodifiable(clients),
      selectedClient: profile.client,
      selectedProducts: List.unmodifiable(profile.products),
      clearValidation: true,
      clearError: true,
    );
  }

  void addCatalogProduct(
    CatalogProduct product, {
    int quantity = 1,
    Comodato? explicitComodato,
    bool forceNoComodato = false,
  }) {
    final client = state.selectedClient;
    final resolution = client == null
        ? ComodatoResolution(
            source: explicitComodato == null
                ? ComodatoResolutionSource.none
                : ComodatoResolutionSource.explicit,
            comodato: forceNoComodato ? null : explicitComodato,
          )
        : ComodatoResolutionService.resolve(
            client: client,
            lineId: product.linea.id,
            explicit: explicitComodato,
            forceNone: forceNoComodato,
          );
    final selected = SelectedProduct.fromCatalog(
      product,
      id: _uuid.v4(),
      cantidad: quantity,
      comodato: resolution.comodato,
      comodatoValid: resolution.valid,
      sinComodato: forceNoComodato,
    );
    final products = [...state.selectedProducts];
    final duplicateIndex = products.indexWhere(
      (item) => item.duplicateKey == selected.duplicateKey,
    );
    if (duplicateIndex >= 0) {
      final current = products[duplicateIndex];
      products[duplicateIndex] = current.copyWith(
        cantidad: current.cantidad + quantity,
      );
    } else {
      products.add(selected);
    }
    state = state.copyWith(
      selectedProducts: List.unmodifiable(products),
      clearError: true,
    );
  }

  void updateProduct(SelectedProduct product) {
    final products = [...state.selectedProducts];
    final index = products.indexWhere((item) => item.id == product.id);
    if (index < 0) return;
    products[index] = product;
    state = state.copyWith(selectedProducts: List.unmodifiable(products));
  }

  void changeQuantity(String id, int delta) {
    final product = state.selectedProducts
        .where((item) => item.id == id)
        .firstOrNull;
    if (product == null) return;
    final quantity = product.cantidad + delta;
    if (quantity <= 0) {
      removeProduct(id);
    } else {
      updateProduct(product.copyWith(cantidad: quantity));
    }
  }

  void duplicateProduct(String id) {
    final product = state.selectedProducts
        .where((item) => item.id == id)
        .firstOrNull;
    if (product == null) return;
    updateProduct(product.copyWith(cantidad: product.cantidad + 1));
  }

  void removeProduct(String id) {
    state = state.copyWith(
      selectedProducts: List.unmodifiable(
        state.selectedProducts.where((item) => item.id != id),
      ),
    );
  }

  ValidationResult validateCurrentOrder() {
    final result = _orderValidation.validate(
      client: state.selectedClient,
      products: state.selectedProducts,
    );
    state = state.copyWith(validation: result, clearError: true);
    return result;
  }

  Future<ValidationResult> startExecution() async {
    final validation = validateCurrentOrder();
    if (!validation.valid) return validation;
    final settings = ref.read(settingsControllerProvider);
    if (!settings.demoMode && !settings.hasPortalConfiguration) {
      return _executionValidationFailure(
        'PORTAL_CONFIGURATION_REQUIRED',
        'Configura la URL HTTPS de Automy antes de usar el modo WebView.',
        'Guarda la configuración del portal en Ajustes.',
      );
    }
    final client = state.selectedClient!;
    final order = Order(
      id: _uuid.v4(),
      client: client,
      products: List.unmodifiable(state.selectedProducts),
      createdAt: DateTime.now(),
    );

    state = state.copyWith(loading: true, clearError: true);
    final gateway = _readGateway();
    if (gateway == null) {
      return _executionValidationFailure(
        'EXECUTION_GATEWAY_INIT',
        'No se pudo preparar el motor de ejecucion.',
        'Revisa la configuracion e intentalo nuevamente.',
      );
    }
    try {
      await for (final execution in gateway.execute(order)) {
        await ref.read(executionRepositoryProvider).save(execution);
        final history = execution.estado == ExecutionStatus.completed
            ? await _saveCompletedExecution(execution)
            : state.history;
        state = state.copyWith(
          execution: execution,
          history: history,
          loading: false,
          clearError: true,
        );
      }
    } catch (error, stackTrace) {
      state = state.copyWith(
        loading: false,
        errorCode: 'EXECUTION_FAILED',
        errorMessage: 'La ejecucion no pudo continuar. Intentalo nuevamente.',
        developerErrorDetails: _developerDetails(error, stackTrace),
      );
    }
    return validation;
  }

  ValidationResult _executionValidationFailure(
    String code,
    String message,
    String action,
  ) {
    final result = ValidationResult([
      ValidationIssue(
        code: code,
        field: 'execution',
        message: message,
        severity: ValidationSeverity.error,
        correctiveAction: action,
      ),
    ]);
    state = state.copyWith(validation: result);
    return result;
  }

  Future<bool> confirmBrowserClosed() async {
    final current = state.execution;
    if (current == null) return false;
    state = state.copyWith(loading: true, clearError: true);
    final gateway = _readGateway();
    if (gateway == null) return false;
    try {
      final completed = await gateway.confirmBrowserClosed(current.id);
      await ref.read(executionRepositoryProvider).save(completed);
      final history = completed.estado == ExecutionStatus.completed
          ? await _saveCompletedExecution(completed)
          : state.history;
      state = state.copyWith(
        loading: false,
        execution: completed,
        history: history,
        clearError: true,
      );
      return true;
    } catch (error, stackTrace) {
      state = state.copyWith(
        loading: false,
        errorCode: 'EXECUTION_CONFIRM_FAILED',
        errorMessage:
            'No se pudo confirmar la ejecucion. Intentalo nuevamente.',
        developerErrorDetails: _developerDetails(error, stackTrace),
      );
      return false;
    }
  }

  Future<List<HistoryRecord>> _saveCompletedExecution(
    Execution completed,
  ) async {
    final settings = ref.read(settingsControllerProvider);
    final record = HistoryRecord.fromExecution(
      completed,
      executionMode: settings.demoMode ? 'Demo' : 'WebView',
    );
    await ref.read(historyRepositoryProvider).save(record);
    return ref.read(historyRepositoryProvider).search();
  }

  Future<bool> deleteHistory(String executionId) async {
    try {
      await ref.read(historyRepositoryProvider).delete(executionId);
      state = state.copyWith(
        history: List.unmodifiable(
          state.history.where((record) => record.executionId != executionId),
        ),
        clearError: true,
      );
      return true;
    } catch (error, stackTrace) {
      state = state.copyWith(
        errorCode: 'HISTORY_DELETE_FAILED',
        errorMessage: 'No se pudo eliminar el registro. Inténtalo nuevamente.',
        developerErrorDetails: _developerDetails(error, stackTrace),
      );
      return false;
    }
  }

  Future<void> cancelExecution() async {
    final current = state.execution;
    if (current == null || current.estado.isTerminal) return;
    final gateway = _readGateway();
    if (gateway == null) return;
    try {
      await gateway.cancel(current.id);
    } catch (error, stackTrace) {
      state = state.copyWith(
        errorCode: 'EXECUTION_CANCEL_FAILED',
        errorMessage: 'No se pudo cancelar la ejecucion. Intentalo nuevamente.',
        developerErrorDetails: _developerDetails(error, stackTrace),
      );
    }
  }

  int restoreFromHistory(
    HistoryRecord record, {
    required RestoreMode mode,
    String? lineName,
  }) {
    final incoming = record.products
        .where(
          (product) => lineName == null || product.linea.nombre == lineName,
        )
        .toList(growable: false);
    if (incoming.isEmpty) return 0;

    List<SelectedProduct> restored;
    if (mode == RestoreMode.replace) {
      restored = List.of(incoming);
    } else {
      restored = List.of(state.selectedProducts);
      for (final product in incoming) {
        final index = restored.indexWhere(
          (current) => current.duplicateKey == product.duplicateKey,
        );
        if (index < 0) {
          restored.add(product.copyWith(id: _uuid.v4()));
        } else {
          final current = restored[index];
          restored[index] = current.copyWith(
            cantidad: current.cantidad + product.cantidad,
          );
        }
      }
    }

    final historicalClients = state.clients.where(
      (item) => item.id == record.clientId,
    );
    final restoredClient = historicalClients.isNotEmpty
        ? historicalClients.first
        : record.clientSnapshot;
    final clients = [...state.clients];
    if (restoredClient != null &&
        clients.every((item) => item.id != restoredClient.id)) {
      clients.add(restoredClient);
    }
    state = state.copyWith(
      clients: List.unmodifiable(clients),
      selectedClient: restoredClient ?? state.selectedClient,
      selectedProducts: List.unmodifiable(restored),
      clearError: true,
    );
    return incoming.length;
  }

  AutomationGateway? _readGateway() {
    try {
      return ref.read(automationGatewayProvider);
    } catch (error, stackTrace) {
      state = state.copyWith(
        loading: false,
        errorCode: 'EXECUTION_GATEWAY_INIT',
        errorMessage:
            'No se pudo preparar el motor de ejecucion. Revise la configuracion e intentalo nuevamente.',
        developerErrorDetails: _developerDetails(error, stackTrace),
      );
      return null;
    }
  }

  String? _developerDetails(Object error, StackTrace stackTrace) {
    if (!ref.read(settingsControllerProvider).developerMode) return null;
    final detail = AutomationLogSanitizer.sanitize(
      'Provider: automationGatewayProvider\n$error\n$stackTrace',
    );
    return detail.length <= 4000 ? detail : detail.substring(0, 4000);
  }

  void clearError() => state = state.copyWith(clearError: true);
}
