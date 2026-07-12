import 'package:flutter/services.dart';

final class ScriptRepository {
  ScriptRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  final Map<String, String> _cache = {};

  Future<String> load(String scriptName) {
    final cached = _cache[scriptName];
    return cached == null ? _load(scriptName) : Future.value(cached);
  }

  Future<String> _load(String scriptName) async {
    final script = await _bundle.loadString('assets/automation/$scriptName.js');
    _cache[scriptName] = script;
    return script;
  }
}
