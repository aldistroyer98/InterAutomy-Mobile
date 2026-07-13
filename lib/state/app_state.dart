import '../domain/entities/client.dart';
import '../domain/entities/commercial_line.dart';
import '../domain/entities/execution.dart';
import '../domain/entities/history_record.dart';
import '../domain/entities/institution.dart';
import '../domain/entities/order_profile.dart';
import '../domain/entities/product.dart';
import '../domain/validation/validation_result.dart';

final class AppState {
  const AppState({
    this.initialized = false,
    this.loading = false,
    this.clients = const [],
    this.institutions = const [],
    this.lines = const [],
    this.catalog = const [],
    this.selectedClient,
    this.selectedProducts = const [],
    this.execution,
    this.history = const [],
    this.profiles = const [],
    this.errorMessage,
    this.errorCode,
    this.developerErrorDetails,
    this.validation,
  });

  final bool initialized;
  final bool loading;
  final List<Client> clients;
  final List<Institution> institutions;
  final List<CommercialLine> lines;
  final List<CatalogProduct> catalog;
  final Client? selectedClient;
  final List<SelectedProduct> selectedProducts;
  final Execution? execution;
  final List<HistoryRecord> history;
  final List<OrderProfile> profiles;
  final String? errorMessage;
  final String? errorCode;
  final String? developerErrorDetails;
  final ValidationResult? validation;

  double get total =>
      selectedProducts.fold(0, (sum, item) => sum + item.subtotal);

  AppState copyWith({
    bool? initialized,
    bool? loading,
    List<Client>? clients,
    List<Institution>? institutions,
    List<CommercialLine>? lines,
    List<CatalogProduct>? catalog,
    Client? selectedClient,
    List<SelectedProduct>? selectedProducts,
    Execution? execution,
    List<HistoryRecord>? history,
    List<OrderProfile>? profiles,
    String? errorMessage,
    String? errorCode,
    String? developerErrorDetails,
    ValidationResult? validation,
    bool clearError = false,
    bool clearSelectedClient = false,
    bool clearValidation = false,
  }) => AppState(
    initialized: initialized ?? this.initialized,
    loading: loading ?? this.loading,
    clients: clients ?? this.clients,
    institutions: institutions ?? this.institutions,
    lines: lines ?? this.lines,
    catalog: catalog ?? this.catalog,
    selectedClient: clearSelectedClient
        ? null
        : selectedClient ?? this.selectedClient,
    selectedProducts: selectedProducts ?? this.selectedProducts,
    execution: execution ?? this.execution,
    history: history ?? this.history,
    profiles: profiles ?? this.profiles,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    errorCode: clearError ? null : errorCode ?? this.errorCode,
    developerErrorDetails: clearError
        ? null
        : developerErrorDetails ?? this.developerErrorDetails,
    validation: clearValidation ? null : validation ?? this.validation,
  );
}
