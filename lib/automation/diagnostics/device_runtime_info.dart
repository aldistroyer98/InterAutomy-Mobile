import 'package:flutter/services.dart';

final class DeviceRuntimeInfo {
  const DeviceRuntimeInfo({
    this.manufacturer = 'unknown',
    this.model = 'unknown',
    this.androidVersion = 'unknown',
    this.androidSdk = 0,
    this.webViewVersion = 'unknown',
    this.webViewPackage = 'unknown',
  });

  final String manufacturer;
  final String model;
  final String androidVersion;
  final int androidSdk;
  final String webViewVersion;
  final String webViewPackage;

  factory DeviceRuntimeInfo.fromMap(Map<Object?, Object?> map) =>
      DeviceRuntimeInfo(
        manufacturer: _safe(map['manufacturer']),
        model: _safe(map['model']),
        androidVersion: _safe(map['androidVersion']),
        androidSdk: map['androidSdk'] is num
            ? (map['androidSdk'] as num).toInt()
            : 0,
        webViewVersion: _safe(map['webViewVersion']),
        webViewPackage: _safe(map['webViewPackage']),
      );

  Map<String, Object?> toJson() => {
    'manufacturer': manufacturer,
    'model': model,
    'androidVersion': androidVersion,
    'androidSdk': androidSdk,
    'webViewVersion': webViewVersion,
    'webViewPackage': webViewPackage,
  };

  static String _safe(Object? value) {
    final text = value?.toString().trim() ?? 'unknown';
    return text.length <= 80 ? text : text.substring(0, 80);
  }
}

final class DeviceRuntimeInfoService {
  const DeviceRuntimeInfoService();

  static const _channel = MethodChannel('interautomy/device_info');

  Future<DeviceRuntimeInfo> read() async {
    try {
      final value = await _channel.invokeMapMethod<Object?, Object?>(
        'getRuntimeInfo',
      );
      return DeviceRuntimeInfo.fromMap(value ?? const {});
    } on MissingPluginException {
      return const DeviceRuntimeInfo();
    } on PlatformException {
      return const DeviceRuntimeInfo();
    }
  }
}
