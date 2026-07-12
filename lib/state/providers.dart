import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/app_config.dart';
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
  (ref) => LocalSettingsRepository(defaultApiUrl: AppConfig.defaultApiUrl),
);
final automationGatewayProvider = Provider<AutomationGateway>(
  (ref) => DemoAutomationGateway(stepDuration: AppConfig.demoStepDuration),
);
