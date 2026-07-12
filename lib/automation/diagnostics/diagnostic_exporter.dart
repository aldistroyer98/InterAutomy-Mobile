import 'dart:convert';
import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../../app/app_config.dart';
import 'diagnostic_models.dart';

final class DiagnosticExporter {
  const DiagnosticExporter();

  Future<String> export(WebDiagnosticSnapshot snapshot) async {
    final directory = await getApplicationDocumentsDirectory();
    final now = DateTime.now();
    final stamp =
        '${_pad(now.year, 4)}${_pad(now.month)}${_pad(now.day)}_'
        '${_pad(now.hour)}${_pad(now.minute)}${_pad(now.second)}';
    final package = await PackageInfo.fromPlatform();
    final payload = <String, Object?>{
      'appVersion': '${package.version}+${package.buildNumber}',
      'flutterVersion': '3.44.6',
      'androidVersion': Platform.operatingSystemVersion,
      'workflowVersion': AppConfig.workflowVersion,
      'selectorVersion': AppConfig.selectorVersion,
      'diagnostic': snapshot.toJson(),
      'exportedAt': now.toUtc().toIso8601String(),
    };
    final path =
        '${directory.path}${Platform.pathSeparator}'
        'interautomy_diagnostic_$stamp.json';
    await File(path).writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
      flush: true,
    );
    return path;
  }

  static String _pad(int value, [int width = 2]) =>
      value.toString().padLeft(width, '0');
}
