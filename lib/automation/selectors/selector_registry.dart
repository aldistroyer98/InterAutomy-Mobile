import '../../app/app_config.dart';
import 'selector_definition.dart';

/// Única fuente de selectores. Ningún script conoce selectores de Automy.
final class SelectorRegistry {
  const SelectorRegistry._();

  static const version = AppConfig.selectorVersion;

  static const definitions = <String, SelectorDefinition>{
    'loginPassword': SelectorDefinition(
      key: 'loginPassword',
      alternatives: ['input[type="password"]', 'input[name="password"]'],
      description:
          'Contraseña de inicio de sesión; se usa solo para detectar login.',
      expectedPage: 'login',
      required: false,
      version: version,
    ),
    'processMenu': SelectorDefinition(
      key: 'processMenu',
      alternatives: [
        '.ant-menu-title-content',
        '[data-testid="processes-menu"]',
      ],
      description: 'Acceso al menú Procesos.',
      expectedPage: 'home',
      required: false,
      version: version,
    ),
    'orderNumber': SelectorDefinition(
      key: 'orderNumber',
      alternatives: [
        '#form_field_groups_nro_oc',
        'input[name="nro_oc"]',
        '[data-field="nro_oc"] input',
      ],
      description: 'Número de orden de compra.',
      expectedPage: 'clientForm',
      required: true,
      version: version,
    ),
    'institution': SelectorDefinition(
      key: 'institution',
      alternatives: [
        '#form_field_groups_cliente',
        'input[name="cliente"]',
        '[data-field="cliente"] input',
      ],
      description: 'Institución o cliente.',
      expectedPage: 'clientForm',
      required: true,
      version: version,
    ),
    'purchaseOrderFile': SelectorDefinition(
      key: 'purchaseOrderFile',
      alternatives: ['input[type="file"][accept*="pdf"]', 'input[type="file"]'],
      description: 'Adjunto de orden de compra.',
      expectedPage: 'clientForm',
      required: false,
      version: version,
    ),
    'completeOrder': SelectorDefinition(
      key: 'completeOrder',
      alternatives: [
        'button.ant-btn.ant-btn-primary.antd-pro-pages-applications-continue-style-complete',
        '[data-testid="complete-order"]',
      ],
      description: 'Acción final de completar pedido.',
      expectedPage: 'review',
      required: false,
      version: version,
    ),
  };

  static SelectorDefinition byKey(String key) {
    final definition = definitions[key];
    if (definition == null) {
      throw ArgumentError.value(key, 'key', 'Selector lógico no registrado.');
    }
    return definition;
  }
}
