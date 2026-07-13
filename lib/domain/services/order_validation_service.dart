import '../entities/client.dart';
import '../entities/product.dart';
import '../validation/validation_result.dart';

/// Reglas de pedido adaptadas de IA1 y concentradas fuera de widgets.
final class OrderValidationService {
  const OrderValidationService();

  ValidationResult validate({
    required Client? client,
    required List<SelectedProduct> products,
  }) {
    final issues = <ValidationIssue>[];
    void error(String code, String field, String message, String action) {
      issues.add(
        ValidationIssue(
          code: code,
          field: field,
          message: message,
          severity: ValidationSeverity.error,
          correctiveAction: action,
        ),
      );
    }

    if (client == null ||
        client.id.trim().isEmpty ||
        client.nombre.trim().isEmpty) {
      error(
        'CLIENT_REQUIRED',
        'client',
        'Selecciona un cliente válido.',
        'Selecciona o crea un cliente antes de continuar.',
      );
    } else {
      _require(
        client.institucion,
        'INSTITUTION_REQUIRED',
        'institution',
        'Selecciona una institucion.',
        'Asocia una institucion al cliente.',
        error,
      );
      for (final field in <(String, String, String)>[
        ('departamento', client.departamento, 'Departamento'),
        ('provincia', client.provincia, 'Provincia'),
        ('distrito', client.distrito, 'Distrito'),
        ('direccion', client.direccion, 'Direccion'),
      ]) {
        _require(
          field.$2,
          'LOCATION_REQUIRED',
          field.$1,
          '${field.$3}: ubicacion obligatoria.',
          'Completa la ubicacion de la institucion.',
          error,
        );
      }
      _require(
        client.contacto,
        'CONTACT_REQUIRED',
        'contact',
        'Ingresa un contacto.',
        'Completa el contacto responsable.',
        error,
      );
      final phoneDigits = client.telefono.replaceAll(RegExp(r'\D'), '');
      if (phoneDigits.length < 7) {
        error(
          'PHONE_INVALID',
          'phone',
          'Ingresa un telefono valido.',
          'Registra al menos siete digitos de telefono.',
        );
      }
      if (client.nroOc.trim().isEmpty && client.motivo.trim().isEmpty) {
        error(
          'PURCHASE_ORDER_OR_REASON_REQUIRED',
          'purchaseOrder',
          'Registra NRO OC o un motivo coherente.',
          'Ingresa el NRO OC o explica por que no corresponde.',
        );
      }
      if (client.nroOc.trim().isNotEmpty && !client.hasArchivoOc) {
        error(
          'PURCHASE_ORDER_FILE_REQUIRED',
          'purchaseOrderFile',
          'Adjunta el archivo de la orden de compra.',
          'Selecciona el PDF, imagen o documento de la OC.',
        );
      }
      _require(
        client.unidad,
        'UNIT_REQUIRED',
        'unit',
        'Selecciona una unidad.',
        'Completa la unidad solicitante.',
        error,
      );
      _require(
        client.horaInicio,
        'START_TIME_REQUIRED',
        'startTime',
        'Completa la hora de inicio.',
        'Selecciona una hora de inicio.',
        error,
      );
      _require(
        client.horaFin,
        'END_TIME_REQUIRED',
        'endTime',
        'Completa la hora de fin.',
        'Selecciona una hora de fin.',
        error,
      );
      if (client.horaInicio.trim().isNotEmpty &&
          client.horaInicio.trim() == client.horaFin.trim()) {
        error(
          'SCHEDULE_INVALID',
          'schedule',
          'La hora de inicio y fin no pueden ser iguales.',
          'Selecciona una franja horaria valida.',
        );
      }
      _require(
        client.moneda,
        'CURRENCY_REQUIRED',
        'currency',
        'Selecciona una moneda.',
        'Completa las condiciones comerciales.',
        error,
      );
      _require(
        client.comentarioFinal,
        'FINAL_COMMENT_REQUIRED',
        'finalComment',
        'Completa el comentario final.',
        'Agrega la indicacion comercial o logistica.',
        error,
      );
    }

    if (products.isEmpty) {
      error(
        'PRODUCTS_REQUIRED',
        'products',
        'Agrega al menos un producto.',
        'Selecciona uno o mas productos.',
      );
    }
    for (var index = 0; index < products.length; index++) {
      final product = products[index];
      final row = index + 1;
      if (product.id.trim().isEmpty || product.nombre.trim().isEmpty) {
        error(
          'PRODUCT_INVALID',
          'products[$index].product',
          'Fila $row: selecciona un producto valido.',
          'Selecciona un producto del catalogo.',
        );
      }
      if (product.linea.id.trim().isEmpty) {
        error(
          'LINE_REQUIRED',
          'products[$index].line',
          'Fila $row: falta la linea comercial.',
          'Selecciona una linea valida.',
        );
      }
      if (product.cantidad <= 0) {
        error(
          'QUANTITY_INVALID',
          'products[$index].quantity',
          'Fila $row: la cantidad debe ser mayor que cero.',
          'Indica una cantidad positiva.',
        );
      }
      if (!product.hasVerifiedPrice || product.precio <= 0) {
        error(
          'PRICE_REQUIRED',
          'products[$index].price',
          'Fila $row: ingresa un precio valido.',
          'Registra el precio autorizado antes de ejecutar.',
        );
      }
      if (!product.hasVerifiedCode || product.codigo.trim().isEmpty) {
        error(
          'COMMERCIAL_CODE_REQUIRED',
          'products[$index].code',
          'Fila $row: falta un código comercial verificable.',
          'Registra el código desde una fuente comercial autorizada.',
        );
      }
      if (!product.hasVerifiedPresentation ||
          product.presentacion.trim().isEmpty) {
        error(
          'PRESENTATION_REQUIRED',
          'products[$index].presentation',
          'Fila $row: falta la presentación verificable.',
          'Registra la presentación desde una fuente autorizada.',
        );
      }
      if (!product.hasVerifiedCategory || product.categoria.trim().isEmpty) {
        error(
          'CATEGORY_REQUIRED',
          'products[$index].category',
          'Fila $row: falta la categoría verificable.',
          'Registra la categoría desde una fuente autorizada.',
        );
      }
      if (product.requiereComodato && product.comodato == null) {
        error(
          'COMODATO_REQUIRED',
          'products[$index].comodato',
          'Fila $row: selecciona un comodato.',
          'Resuelve o selecciona el comodato del producto.',
        );
      }
      if (!product.comodatoValid) {
        error(
          'COMODATO_NOT_ALLOWED',
          'products[$index].comodato',
          'Fila $row: el comodato no pertenece al cliente y línea seleccionados.',
          'Selecciona un comodato permitido o usa la resolución automática.',
        );
      }
    }
    return ValidationResult(List.unmodifiable(issues));
  }

  static void _require(
    String value,
    String code,
    String field,
    String message,
    String action,
    void Function(String, String, String, String) addError,
  ) {
    if (value.trim().isEmpty) addError(code, field, message, action);
  }
}
