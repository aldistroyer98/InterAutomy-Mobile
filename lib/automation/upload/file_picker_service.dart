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
}
