import '../app/app_config.dart';
import '../domain/entities/app_settings.dart';
import '../domain/entities/client.dart';
import '../domain/entities/commercial_line.dart';
import '../domain/entities/execution.dart';
import '../domain/entities/history_record.dart';
import '../domain/entities/product.dart';

final class AppState {
  const AppState({
    this.initialized = false,
    this.loading = false,
    this.clients = const [],
    this.lines = const [],
    this.catalog = const [],
    this.selectedClient,
    this.selectedProducts = const [],
    this.execution,
    this.history = const [],
    this.settings = const AppSettings(
      demoMode: true,
      apiUrl: AppConfig.defaultApiUrl,
      theme: AppThemePreference.system,
    ),
    this.errorMessage,
  });

  final bool initialized;
  final bool loading;
  final List<Client> clients;
  final List<CommercialLine> lines;
  final List<CatalogProduct> catalog;
  final Client? selectedClient;
  final List<SelectedProduct> selectedProducts;
  final Execution? execution;
  final List<HistoryRecord> history;
  final AppSettings settings;
  final String? errorMessage;

  double get total =>
      selectedProducts.fold(0, (sum, item) => sum + item.subtotal);

  AppState copyWith({
    bool? initialized,
    bool? loading,
    List<Client>? clients,
    List<CommercialLine>? lines,
    List<CatalogProduct>? catalog,
    Client? selectedClient,
    List<SelectedProduct>? selectedProducts,
    Execution? execution,
    List<HistoryRecord>? history,
    AppSettings? settings,
    String? errorMessage,
    bool clearError = false,
  }) => AppState(
    initialized: initialized ?? this.initialized,
    loading: loading ?? this.loading,
    clients: clients ?? this.clients,
    lines: lines ?? this.lines,
    catalog: catalog ?? this.catalog,
    selectedClient: selectedClient ?? this.selectedClient,
    selectedProducts: selectedProducts ?? this.selectedProducts,
    execution: execution ?? this.execution,
    history: history ?? this.history,
    settings: settings ?? this.settings,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
  );
}
