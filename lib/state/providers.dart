import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/app_config.dart';
import '../automation/webview_automation_gateway.dart';
import '../core/security/webview_security_policy.dart';
import '../data/catalogs/asset_catalog_loader.dart';
import '../data/demo/demo_automation_gateway.dart';
import '../data/repositories/asset_catalog_repositories.dart';
import '../data/repositories/demo_client_repository.dart';
import '../data/repositories/demo_execution_repository.dart';
import '../data/repositories/demo_product_repository.dart';
import '../data/repositories/local_domain_repositories.dart';
import '../data/local/local_domain_store.dart';
import '../domain/entities/catalog_source.dart';
import '../domain/repositories/client_repository.dart';
import '../domain/repositories/execution_repository.dart';
import '../domain/repositories/history_repository.dart';
import '../domain/repositories/institution_repository.dart';
import '../domain/repositories/profile_repository.dart';
import '../domain/repositories/product_repository.dart';
import '../domain/services/automation_gateway.dart';
import 'settings_controller.dart';

export 'settings_controller.dart'
    show
        SettingsController,
        settingsControllerProvider,
        settingsRepositoryProvider;

final demoClientRepositoryProvider = Provider<ClientRepository>(
  (ref) => DemoClientRepository(),
);
final demoProductRepositoryProvider = Provider<ProductRepository>(
  (ref) => DemoProductRepository(),
);
final localDomainStoreProvider = Provider<LocalDomainStore>(
  (ref) => LocalDomainStore.applicationDocuments(),
);
final assetCatalogLoaderProvider = Provider<AssetCatalogLoader>(
  (ref) => AssetCatalogLoader(),
);
final ia1ClientRepositoryProvider = Provider<ClientRepository>(
  (ref) => AssetClientRepository(ref.watch(assetCatalogLoaderProvider)),
);
final ia1ProductRepositoryProvider = Provider<ProductRepository>(
  (ref) => AssetProductRepository(ref.watch(assetCatalogLoaderProvider)),
);
final ia1InstitutionRepositoryProvider = Provider<AssetInstitutionRepository>(
  (ref) => AssetInstitutionRepository(ref.watch(assetCatalogLoaderProvider)),
);
final ia1CommercialLineRepositoryProvider =
    Provider<AssetCommercialLineRepository>(
      (ref) =>
          AssetCommercialLineRepository(ref.watch(assetCatalogLoaderProvider)),
    );
final ia1ComodatoRepositoryProvider = Provider<AssetComodatoRepository>(
  (ref) => AssetComodatoRepository(ref.watch(assetCatalogLoaderProvider)),
);
final baseClientRepositoryProvider = Provider<ClientRepository>((ref) {
  final source = ref.watch(
    settingsControllerProvider.select((settings) => settings.catalogSource),
  );
  return source == CatalogSource.ia1
      ? ref.watch(ia1ClientRepositoryProvider)
      : ref.watch(demoClientRepositoryProvider);
});
final clientRepositoryProvider = Provider<ClientRepository>(
  (ref) => OverlayClientRepository(
    ref.watch(baseClientRepositoryProvider),
    ref.watch(localDomainStoreProvider),
  ),
);
final baseInstitutionRepositoryProvider = Provider<InstitutionRepository>((
  ref,
) {
  final source = ref.watch(
    settingsControllerProvider.select((settings) => settings.catalogSource),
  );
  return source == CatalogSource.ia1
      ? ref.watch(ia1InstitutionRepositoryProvider)
      : const EmptyInstitutionRepository();
});
final institutionRepositoryProvider = Provider<InstitutionRepository>(
  (ref) => OverlayInstitutionRepository(
    ref.watch(baseInstitutionRepositoryProvider),
    ref.watch(localDomainStoreProvider),
  ),
);
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final source = ref.watch(
    settingsControllerProvider.select((settings) => settings.catalogSource),
  );
  return source == CatalogSource.ia1
      ? ref.watch(ia1ProductRepositoryProvider)
      : ref.watch(demoProductRepositoryProvider);
});
final executionRepositoryProvider = Provider<ExecutionRepository>(
  (ref) => DemoExecutionRepository(),
);
final historyRepositoryProvider = Provider<HistoryRepository>(
  (ref) => PersistentHistoryRepository(ref.watch(localDomainStoreProvider)),
);
final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => PersistentProfileRepository(ref.watch(localDomainStoreProvider)),
);
final demoAutomationGatewayProvider = Provider<DemoAutomationGateway>(
  (ref) => DemoAutomationGateway(stepDuration: AppConfig.demoStepDuration),
);
final webViewAutomationGatewayProvider = Provider<WebViewAutomationGateway>((
  ref,
) {
  final gateway = WebViewAutomationGateway(
    persistSessionReader: () =>
        ref.read(settingsControllerProvider).persistSession,
    loadTimeoutReader: () => Duration(
      seconds: ref.read(settingsControllerProvider).loadTimeoutSeconds,
    ),
    selectorTimeoutReader: () => Duration(
      seconds: ref.read(settingsControllerProvider).selectorTimeoutSeconds,
    ),
    policyReader: () {
      final settings = ref.read(settingsControllerProvider);
      return WebViewSecurityPolicy(
        portalUrl: WebViewSecurityPolicy.parsePortalUrl(settings.portalUrl),
        additionalHosts: settings.additionalAllowedHosts,
      );
    },
  );
  ref.onDispose(gateway.dispose);
  return gateway;
});
final automationGatewayProvider = Provider<AutomationGateway>((ref) {
  final demoMode = ref.watch(
    settingsControllerProvider.select((settings) => settings.demoMode),
  );
  return demoMode
      ? ref.watch(demoAutomationGatewayProvider)
      : ref.watch(webViewAutomationGatewayProvider);
});
