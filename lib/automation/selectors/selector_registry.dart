import '../../app/app_config.dart';
import 'selector_definition.dart';

/// Única fuente de selectores del portal. Los scripts reciben alternativas
/// como payload y solo devuelven clave lógica, índice y versión.
final class SelectorRegistry {
  const SelectorRegistry._();

  static const version = AppConfig.selectorVersion;

  static const definitions = <String, SelectorDefinition>{
    'purchaseOrderNumber': SelectorDefinition(
      key: 'purchaseOrderNumber',
      alternatives: [
        '[data-testid="nro-oc"]',
        '[data-field="nro_oc"]',
        'input[aria-label="NRO OC"]',
        'input[name="nro_oc"]',
        '#form_field_groups_nro_oc',
        '@associated-label:nro-oc',
        'form [data-section="purchase-order"] input[type="text"]',
        '.nro-oc input',
      ],
      description: 'Número de orden de compra; único campo modificable.',
      expectedPage: 'clientForm',
      required: true,
      version: version,
    ),
  };

  static SelectorDefinition byKey(String key) {
    final normalized = key == 'orderNumber' ? 'purchaseOrderNumber' : key;
    final definition = definitions[normalized];
    if (definition == null) {
      throw ArgumentError.value(key, 'key', 'Selector lógico no registrado.');
    }
    return definition;
  }
}
