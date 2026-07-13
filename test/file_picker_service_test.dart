import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interautomy_mobile/automation/upload/file_picker_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('interautomy/file_picker');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('selector OC devuelve solo URI y metadatos seguros', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'pickPurchaseOrderFile');
          expect(call.arguments['acceptTypes'], contains('application/pdf'));
          return {
            'uri': 'content://documents/oc-1',
            'displayName': 'orden-compra.pdf',
            'mimeType': 'application/pdf',
          };
        });

    final document = await FilePickerService(
      channel: channel,
    ).pickPurchaseOrderFile();
    expect(document?.uri, 'content://documents/oc-1');
    expect(document?.displayName, 'orden-compra.pdf');
    expect(document?.mimeType, 'application/pdf');
  });

  test('abrir OC delega la URI al canal nativo sin leer el archivo', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'openDocument');
          expect(call.arguments['uri'], 'content://documents/oc-1');
          expect(call.arguments['mimeType'], 'application/pdf');
          return null;
        });

    await FilePickerService(channel: channel).openDocument(
      uri: 'content://documents/oc-1',
      mimeType: 'application/pdf',
    );
  });
}
