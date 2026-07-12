import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/app_config.dart';
import '../automation/webview_automation_gateway.dart';
import '../core/security/webview_security_policy.dart';
import '../data/demo/demo_automation_gateway.dart';
import '../data/repositories/demo_client_repository.dart';
import '../data/repositories/demo_execution_repository.dart';
import '../data/repositories/demo_history_repository.dart';
import '../data/repositories/demo_product_repository.dart';
import '../data/repositories/local_settings_repository.dart';
import '../domain/repositories/client_repository.dart';
import '../domain/repositories/execution_repository.dart';
import '../domain/repositories/history_repository.dart';
import '../domain/repositories/product_repository.dart';
import '../domain/repositories/settings_repository.dart';
import '../domain/services/automation_gateway.dart';
import 'app_controller.dart';

final clientRepositoryProvider = Provider<ClientRepository>(
  (ref) => DemoClientRepository(),
);
final productRepositoryProvider = Provider<ProductRepository>(
  (ref) => DemoProductRepository(),
);
final executionRepositoryProvider = Provider<ExecutionRepository>(
  (ref) => DemoExecutionRepository(),
);
final historyRepositoryProvider = Provider<HistoryRepository>(
  (ref) => DemoHistoryRepository(),
);
final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) =>
      LocalSettingsRepository(defaultPortalUrl: AppConfig.defaultPortalUrl),
);
final demoAutomationGatewayProvider = Provider<DemoAutomationGateway>(
  (ref) => DemoAutomationGateway(stepDuration: AppConfig.demoStepDuration),
);
final webViewAutomationGatewayProvider = Provider<WebViewAutomationGateway>((
  ref,
) {
  final gateway = WebViewAutomationGateway(
    policyReader: () {
      final settings = ref.read(appControllerProvider).settings;
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
    appControllerProvider.select((state) => state.settings.demoMode),
  );
  return demoMode
      ? ref.watch(demoAutomationGatewayProvider)
      : ref.watch(webViewAutomationGatewayProvider);
});
