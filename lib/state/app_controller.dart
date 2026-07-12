import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../domain/entities/app_settings.dart';
import '../domain/entities/client.dart';
import '../domain/entities/commercial_line.dart';
import '../domain/entities/comodato.dart';
import '../domain/entities/history_record.dart';
import '../domain/entities/product.dart';
import '../domain/services/comodato_resolver.dart';
import 'app_state.dart';
import 'providers.dart';

final appControllerProvider = NotifierProvider<AppController, AppState>(
  AppController.new,
);

final class AppController extends Notifier<AppState> {
  static const _uuid = Uuid();

  @override
  AppState build() => const AppState();

  Future<void> initialize() async {
    if (state.initialized || state.loading) return;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final results = await Future.wait([
        ref.read(clientRepositoryProvider).getAll(),
        ref.read(productRepositoryProvider).getLines(),
        ref.read(productRepositoryProvider).getProducts(),
        ref.read(historyRepositoryProvider).search(),
        ref.read(settingsRepositoryProvider).load(),
      ]);
      final clients = results[0] as List<Client>;
      state = state.copyWith(
        initialized: true,
        loading: false,
        clients: clients,
        lines: results[1] as List<CommercialLine>,
        catalog: results[2] as List<CatalogProduct>,
        history: results[3] as List<HistoryRecord>,
        settings: results[4] as AppSettings,
        selectedClient: clients.isEmpty ? null : clients.first,
      );
    } catch (error) {
      state = state.copyWith(
        initialized: true,
        loading: false,
        errorMessage: 'No se pudo iniciar la aplicación: $error',
      );
    }
  }

  void selectClient(Client client) {
    state = state.copyWith(selectedClient: client, clearError: true);
  }

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

  Future<bool> saveClient() async {
    final client = state.selectedClient;
    if (client == null || client.nombre.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Escribe el nombre del cliente.');
      return false;
    }
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
  }

  void addCatalogProduct(
    CatalogProduct product, {
    int quantity = 1,
    Comodato? explicitComodato,
  }) {
    final client = state.selectedClient;
    final resolved = client == null
        ? explicitComodato
        : ComodatoResolver.resolve(
            client: client,
            lineId: product.linea.id,
            explicit: explicitComodato,
          );
    final selected = SelectedProduct.fromCatalog(
      product,
      id: _uuid.v4(),
      cantidad: quantity,
      comodato: resolved,
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

  Future<void> updateSettings(AppSettings settings) async {
    await ref.read(settingsRepositoryProvider).save(settings);
    state = state.copyWith(settings: settings, clearError: true);
  }

  void clearError() => state = state.copyWith(clearError: true);
}
