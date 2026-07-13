import 'package:flutter/services.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

/// Selector Android basado en Storage Access Framework; no solicita permisos
/// de almacenamiento amplios ni copia los archivos al almacenamiento de la app.
final class FilePickerService {
  FilePickerService({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('interautomy/file_picker');

  final MethodChannel _channel;

  Future<List<String>> pickForWeb(FileSelectorParams params) async {
    final selected = await _channel.invokeListMethod<String>('pickFiles', {
      'acceptTypes': params.acceptTypes,
      'allowMultiple': params.mode == FileSelectorMode.openMultiple,
    });
    return selected ?? const [];
  }

  /// Selecciona la referencia de una OC para el pedido móvil. Es independiente
  /// del selector de WebView y devuelve solo una URI SAF persistible y sus
  /// metadatos visibles; nunca lee ni copia el contenido del archivo.
  Future<SelectedLocalDocument?> pickPurchaseOrderFile() async {
    final selected = await _channel.invokeMapMethod<String, dynamic>(
      'pickPurchaseOrderFile',
      {
        'acceptTypes': const [
          'application/pdf',
          'image/*',
          'application/msword',
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        ],
      },
    );
    if (selected == null) return null;
    final uri = selected['uri'];
    final displayName = selected['displayName'];
    if (uri is! String || uri.trim().isEmpty || displayName is! String) {
      throw PlatformException(
        code: 'PICKER_INVALID_RESULT',
        message: 'El selector no devolvió un documento válido.',
      );
    }
    return SelectedLocalDocument(
      uri: uri,
      displayName: displayName,
      mimeType: selected['mimeType'] is String
          ? selected['mimeType'] as String
          : '',
    );
  }

  Future<void> openDocument({required String uri, String mimeType = ''}) async {
    if (uri.trim().isEmpty) return;
    await _channel.invokeMethod<void>('openDocument', {
      'uri': uri,
      'mimeType': mimeType,
    });
  }
}

final class SelectedLocalDocument {
  const SelectedLocalDocument({
    required this.uri,
    required this.displayName,
    required this.mimeType,
  });

  final String uri;
  final String displayName;
  final String mimeType;
}
