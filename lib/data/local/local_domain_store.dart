import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/client.dart';
import '../../domain/entities/commercial_line.dart';
import '../../domain/entities/comodato.dart';
import '../../domain/entities/execution.dart';
import '../../domain/entities/history_record.dart';
import '../../domain/entities/institution.dart';
import '../../domain/entities/order_profile.dart';
import '../../domain/entities/product.dart';

/// Backend inyectable para que el almacenamiento local se pruebe sin canales
/// de plataforma ni archivos reales.
abstract interface class LocalDomainStoreBackend {
  Future<String?> read();
  Future<String?> readBackup();
  Future<void> write(String contents);
  Future<void> restore(String contents);
}

final class InMemoryLocalDomainStoreBackend implements LocalDomainStoreBackend {
  InMemoryLocalDomainStoreBackend({this.primaryContents, this.backupContents});

  String? primaryContents;
  String? backupContents;

  @override
  Future<String?> read() async => primaryContents;

  @override
  Future<String?> readBackup() async => backupContents;

  @override
  Future<void> write(String contents) async {
    backupContents = primaryContents;
    primaryContents = contents;
  }

  @override
  Future<void> restore(String contents) async {
    primaryContents = contents;
  }
}

/// Guarda un único documento JSON privado de la aplicación. Se usa el
/// directorio de documentos de la app usando un archivo temporal antes del
/// reemplazo; no se utiliza SharedPreferences para colecciones complejas.
final class ApplicationDocumentsLocalDomainStoreBackend
    implements LocalDomainStoreBackend {
  ApplicationDocumentsLocalDomainStoreBackend({
    Future<Directory> Function()? directoryResolver,
  }) : _directoryResolver =
           directoryResolver ?? getApplicationDocumentsDirectory;

  final Future<Directory> Function() _directoryResolver;

  Future<File> _file() async {
    final directory = await _directoryResolver();
    return File(
      '${directory.path}${Platform.pathSeparator}interautomy_data.json',
    );
  }

  Future<File> _backupFile() async {
    final file = await _file();
    return File('${file.path}.bak');
  }

  @override
  Future<String?> read() async {
    final file = await _file();
    if (!await file.exists()) return null;
    return file.readAsString();
  }

  @override
  Future<String?> readBackup() async {
    final backup = await _backupFile();
    if (!await backup.exists()) return null;
    return backup.readAsString();
  }

  @override
  Future<void> write(String contents) async {
    final file = await _file();
    final backup = await _backupFile();
    await file.parent.create(recursive: true);
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsString(contents, flush: true);
    if (await file.exists()) {
      if (await backup.exists()) await backup.delete();
      await file.rename(backup.path);
    }
    try {
      await temporary.rename(file.path);
    } on Object {
      if (!await file.exists() && await backup.exists()) {
        await backup.copy(file.path);
      }
      rethrow;
    }
  }

  @override
  Future<void> restore(String contents) async {
    final file = await _file();
    await file.parent.create(recursive: true);
    final temporary = File('${file.path}.recovery.tmp');
    final corrupt = File('${file.path}.corrupt');
    await temporary.writeAsString(contents, flush: true);
    if (await corrupt.exists()) await corrupt.delete();
    if (await file.exists()) await file.rename(corrupt.path);
    try {
      await temporary.rename(file.path);
      if (await corrupt.exists()) await corrupt.delete();
    } on Object {
      if (!await file.exists() && await corrupt.exists()) {
        await corrupt.rename(file.path);
      }
      rethrow;
    }
  }
}

final class LocalDomainStoreException implements Exception {
  const LocalDomainStoreException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => '$code: $message';
}

/// Almacenamiento local estructurado, con migración explícita de esquema.
///
/// El documento actual es `schemaVersion: 2` e incluye checksum SHA-256. Las
/// migraciones v0 y v1 permiten abrir documentos anteriores; toda escritura
/// posterior los guarda en el formato actual.
final class LocalDomainStore {
  LocalDomainStore({required this.backend});

  factory LocalDomainStore.applicationDocuments() =>
      LocalDomainStore(backend: ApplicationDocumentsLocalDomainStoreBackend());

  static const schemaVersion = 2;

  final LocalDomainStoreBackend backend;
  _LocalDomainData? _data;
  Future<_LocalDomainData>? _loading;
  Future<void> _writeQueue = Future<void>.value();

  Future<List<Client>> getClients() async =>
      List.unmodifiable((await _load()).clients.values.toList(growable: false));

  Future<Client> saveClient(Client client) async {
    await _update((data) => data.clients[client.id] = client);
    return client;
  }

  Future<List<Institution>> getInstitutions() async => List.unmodifiable(
    (await _load()).institutions.values.toList(growable: false),
  );

  Future<Institution> saveInstitution(Institution institution) async {
    await _update((data) => data.institutions[institution.id] = institution);
    return institution;
  }

  Future<List<HistoryRecord>> getHistory() async {
    final values = (await _load()).history.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(values);
  }

  Future<HistoryRecord?> getHistoryByExecutionId(String executionId) async =>
      (await _load()).history[executionId];

  Future<void> saveHistory(HistoryRecord record) =>
      _update((data) => data.history[record.executionId] = record);

  Future<void> deleteHistory(String executionId) =>
      _update((data) => data.history.remove(executionId));

  Future<List<OrderProfile>> getProfiles() async {
    final values = (await _load()).profiles.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return List.unmodifiable(values);
  }

  Future<OrderProfile?> getProfileById(String id) async =>
      (await _load()).profiles[id];

  Future<OrderProfile> saveProfile(OrderProfile profile) async {
    await _update((data) => data.profiles[profile.id] = profile);
    return profile;
  }

  Future<void> deleteProfile(String id) =>
      _update((data) => data.profiles.remove(id));

  Future<_LocalDomainData> _load() async {
    final cached = _data;
    if (cached != null) return cached;
    return _loading ??= _loadUncached().whenComplete(() => _loading = null);
  }

  Future<_LocalDomainData> _loadUncached() async {
    final primary = await backend.read();
    LocalDomainStoreException? primaryFailure;
    if (primary != null && primary.trim().isNotEmpty) {
      try {
        return _data = _decode(primary);
      } on LocalDomainStoreException catch (error) {
        primaryFailure = error;
      }
    }

    final backup = await backend.readBackup();
    if (backup != null && backup.trim().isNotEmpty) {
      try {
        final recovered = _decode(backup);
        await backend.restore(backup);
        return _data = recovered;
      } on LocalDomainStoreException catch (backupFailure) {
        throw LocalDomainStoreException(
          'LOCAL_STORE_RECOVERY_FAILED',
          'El documento principal y su copia de respaldo no son válidos. '
              'Principal: ${primaryFailure?.code ?? 'ausente'}; '
              'respaldo: ${backupFailure.code}.',
        );
      }
    }

    if (primaryFailure != null) throw primaryFailure;
    return _data = _LocalDomainData.empty();
  }

  _LocalDomainData _decode(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, Object?>) {
        throw const FormatException('La raíz debe ser un objeto JSON.');
      }
      return _LocalDomainData.fromJson(decoded);
    } on LocalDomainStoreException {
      rethrow;
    } on Object catch (error) {
      throw LocalDomainStoreException(
        'LOCAL_STORE_CORRUPTED',
        'No se pudo leer la información local estructurada: $error',
      );
    }
  }

  Future<void> _update(void Function(_LocalDomainData data) operation) {
    final pending = _writeQueue.then((_) async {
      final current = await _load();
      final next = current.copy();
      operation(next);
      await backend.write(jsonEncode(next.toJson()));
      _data = next;
    });
    _writeQueue = pending.catchError((_) {});
    return pending;
  }
}

final class _LocalDomainData {
  _LocalDomainData({
    required this.clients,
    required this.institutions,
    required this.history,
    required this.profiles,
  });

  factory _LocalDomainData.empty() => _LocalDomainData(
    clients: <String, Client>{},
    institutions: <String, Institution>{},
    history: <String, HistoryRecord>{},
    profiles: <String, OrderProfile>{},
  );

  factory _LocalDomainData.fromJson(Map<String, Object?> json) {
    final version = _int(json['schemaVersion']) ?? 0;
    if (version > LocalDomainStore.schemaVersion) {
      throw LocalDomainStoreException(
        'LOCAL_STORE_SCHEMA_UNSUPPORTED',
        'El almacenamiento local requiere una versión más reciente de la app.',
      );
    }
    final migrated = switch (version) {
      0 => _migrateV0(json),
      1 => _migrateV1(json),
      LocalDomainStore.schemaVersion => json,
      _ => throw LocalDomainStoreException(
        'LOCAL_STORE_SCHEMA_UNSUPPORTED',
        'No existe una migración para el esquema local $version.',
      ),
    };
    if (version == LocalDomainStore.schemaVersion) {
      _validateChecksum(migrated);
    }
    return _LocalDomainData(
      clients: _indexed<Client>(migrated['clients'], _clientFromJson),
      institutions: _indexed<Institution>(
        migrated['institutions'],
        _institutionFromJson,
      ),
      history: _indexed<HistoryRecord>(migrated['history'], _historyFromJson),
      profiles: _indexed<OrderProfile>(migrated['profiles'], _profileFromJson),
    );
  }

  final Map<String, Client> clients;
  final Map<String, Institution> institutions;
  final Map<String, HistoryRecord> history;
  final Map<String, OrderProfile> profiles;

  _LocalDomainData copy() => _LocalDomainData(
    clients: Map.of(clients),
    institutions: Map.of(institutions),
    history: Map.of(history),
    profiles: Map.of(profiles),
  );

  Map<String, Object?> toJson() {
    final payload = <String, Object?>{
      'schemaVersion': LocalDomainStore.schemaVersion,
      'clients': clients.values.map(_clientToJson).toList(growable: false),
      'institutions': institutions.values
          .map(_institutionToJson)
          .toList(growable: false),
      'history': history.values.map(_historyToJson).toList(growable: false),
      'profiles': profiles.values.map(_profileToJson).toList(growable: false),
    };
    return {...payload, 'checksum': _documentChecksum(payload)};
  }

  static Map<String, Object?> _migrateV0(Map<String, Object?> json) => {
    'schemaVersion': LocalDomainStore.schemaVersion,
    'clients': json['clients'] ?? const [],
    'institutions': json['institutions'] ?? const [],
    'history': json['history'] ?? const [],
    'profiles': json['profiles'] ?? const [],
  };

  static Map<String, Object?> _migrateV1(Map<String, Object?> json) =>
      _migrateV0(json);

  static void _validateChecksum(Map<String, Object?> json) {
    final checksum = _text(json, 'checksum');
    final payload = Map<String, Object?>.of(json)..remove('checksum');
    if (checksum.isEmpty || checksum != _documentChecksum(payload)) {
      throw const LocalDomainStoreException(
        'LOCAL_STORE_CHECKSUM_INVALID',
        'El checksum del almacenamiento local no coincide con su contenido.',
      );
    }
  }
}

String _documentChecksum(Map<String, Object?> payload) =>
    sha256.convert(utf8.encode(jsonEncode(_canonicalize(payload)))).toString();

Object? _canonicalize(Object? value) {
  if (value is Map<String, Object?>) {
    final keys = value.keys.toList(growable: false)..sort();
    return <String, Object?>{
      for (final key in keys) key: _canonicalize(value[key]),
    };
  }
  if (value is List<Object?>) {
    return value.map(_canonicalize).toList(growable: false);
  }
  return value;
}

Map<String, T> _indexed<T>(
  Object? value,
  T Function(Map<String, Object?> json) decode,
) {
  if (value == null) return <String, T>{};
  if (value is! List<Object?>) {
    throw const FormatException('Una colección local debe ser una lista.');
  }
  final result = <String, T>{};
  for (final item in value) {
    if (item is! Map<String, Object?>) {
      throw const FormatException('Un elemento local debe ser un objeto.');
    }
    final decoded = decode(item);
    final id = switch (decoded) {
      Client value => value.id,
      Institution value => value.id,
      HistoryRecord value => value.executionId,
      OrderProfile value => value.id,
      _ => throw StateError('Entidad local no indexable.'),
    };
    if (id.trim().isEmpty || result.containsKey(id)) {
      throw const FormatException('Existe un ID local vacío o duplicado.');
    }
    result[id] = decoded;
  }
  return result;
}

Map<String, Object?> _clientToJson(Client value) => {
  'id': value.id,
  'name': value.nombre,
  'purchaseOrderNumber': value.nroOc,
  'purchaseOrderUri': value.archivoOc,
  'purchaseOrderDisplayName': value.archivoOcNombre,
  'purchaseOrderMimeType': value.archivoOcMimeType,
  'unit': value.unidad,
  'service': value.servicio,
  'institutionId': value.institutionId,
  'institution': value.institucion,
  'department': value.departamento,
  'province': value.provincia,
  'district': value.distrito,
  'address': value.direccion,
  'contact': value.contacto,
  'phone': value.telefono,
  'finalComment': value.comentarioFinal,
  'newAddress': value.direccionNueva,
  'newContact': value.contactoNuevo,
  'startTime': value.horaInicio,
  'endTime': value.horaFin,
  'igv': value.igv,
  'currency': value.moneda,
  'advance': value.adelanto,
  'reason': value.motivo,
  'comodatosByLine': {
    for (final entry in value.comodatosPorLinea.entries)
      entry.key: entry.value.map(_comodatoToJson).toList(growable: false),
  },
};

Client _clientFromJson(Map<String, Object?> json) => Client(
  id: _requiredText(json, 'id'),
  nombre: _requiredText(json, 'name'),
  nroOc: _text(json, 'purchaseOrderNumber'),
  archivoOc: _text(json, 'purchaseOrderUri'),
  archivoOcNombre: _text(json, 'purchaseOrderDisplayName'),
  archivoOcMimeType: _text(json, 'purchaseOrderMimeType'),
  unidad: _text(json, 'unit'),
  servicio: _text(json, 'service'),
  institutionId: _text(json, 'institutionId'),
  institucion: _text(json, 'institution'),
  departamento: _text(json, 'department'),
  provincia: _text(json, 'province'),
  distrito: _text(json, 'district'),
  direccion: _text(json, 'address'),
  contacto: _text(json, 'contact'),
  telefono: _text(json, 'phone'),
  comentarioFinal: _text(json, 'finalComment'),
  direccionNueva: _bool(json, 'newAddress'),
  contactoNuevo: _bool(json, 'newContact'),
  horaInicio: _text(json, 'startTime', fallback: '09:00'),
  horaFin: _text(json, 'endTime', fallback: '10:00'),
  igv: _bool(json, 'igv'),
  moneda: _text(json, 'currency', fallback: 'Soles'),
  adelanto: _bool(json, 'advance'),
  motivo: _text(json, 'reason', fallback: 'SIN OC'),
  comodatosPorLinea: _comodatosByLine(json['comodatosByLine']),
);

Map<String, Object?> _institutionToJson(Institution value) => {
  'id': value.id,
  'name': value.nombre,
  'clientIds': value.clientIds,
  'department': value.departamento,
  'province': value.provincia,
  'district': value.distrito,
  'address': value.direccion,
  'contact': value.contacto,
  'phone': value.telefono,
};

Institution _institutionFromJson(Map<String, Object?> json) => Institution(
  id: _requiredText(json, 'id'),
  nombre: _requiredText(json, 'name'),
  clientIds: _strings(json['clientIds']),
  departamento: _text(json, 'department'),
  provincia: _text(json, 'province'),
  distrito: _text(json, 'district'),
  direccion: _text(json, 'address'),
  contacto: _text(json, 'contact'),
  telefono: _text(json, 'phone'),
);

Map<String, Object?> _historyToJson(HistoryRecord value) => {
  'id': value.id,
  'executionId': value.executionId,
  'clientId': value.clientId,
  'clientName': value.clientName,
  'lineNames': value.lineNames,
  'createdAt': value.createdAt.toUtc().toIso8601String(),
  'status': value.status.name,
  'products': value.products
      .map(_selectedProductToJson)
      .toList(growable: false),
  'clientSnapshot': value.clientSnapshot == null
      ? null
      : _clientToJson(value.clientSnapshot!),
  'executionMode': value.executionMode,
  'result': value.result,
  'totalSnapshot': value.totalSnapshot,
};

HistoryRecord _historyFromJson(Map<String, Object?> json) => HistoryRecord(
  id: _requiredText(json, 'id'),
  executionId: _requiredText(json, 'executionId'),
  clientId: _requiredText(json, 'clientId'),
  clientName: _requiredText(json, 'clientName'),
  lineNames: _strings(json['lineNames']),
  createdAt: _date(json['createdAt']),
  status: _executionStatus(_requiredText(json, 'status')),
  products: _maps(
    json['products'],
  ).map(_selectedProductFromJson).toList(growable: false),
  clientSnapshot: json['clientSnapshot'] == null
      ? null
      : _clientFromJson(_map(json['clientSnapshot'], 'clientSnapshot')),
  executionMode: _text(json, 'executionMode', fallback: 'Demo'),
  result: _text(json, 'result'),
  totalSnapshot: json['totalSnapshot'] == null
      ? null
      : _double(json['totalSnapshot']),
);

Map<String, Object?> _profileToJson(OrderProfile value) => {
  'id': value.id,
  'name': value.name,
  'client': _clientToJson(value.client),
  'products': value.products
      .map(_selectedProductToJson)
      .toList(growable: false),
  'createdAt': value.createdAt.toUtc().toIso8601String(),
  'updatedAt': value.updatedAt.toUtc().toIso8601String(),
};

OrderProfile _profileFromJson(Map<String, Object?> json) => OrderProfile(
  id: _requiredText(json, 'id'),
  name: _requiredText(json, 'name'),
  client: _clientFromJson(_map(json['client'], 'client')),
  products: _maps(
    json['products'],
  ).map(_selectedProductFromJson).toList(growable: false),
  createdAt: _date(json['createdAt']),
  updatedAt: _date(json['updatedAt']),
);

Map<String, Object?> _selectedProductToJson(SelectedProduct value) => {
  'id': value.id,
  'code': value.codigo,
  'name': value.nombre,
  'description': value.descripcion,
  'line': _lineToJson(value.linea),
  'presentation': value.presentacion,
  'price': value.precio,
  'quantity': value.cantidad,
  'category': value.categoria,
  'comodato': value.comodato == null ? null : _comodatoToJson(value.comodato!),
  'expiration': value.expiracion?.toUtc().toIso8601String(),
  'requiresComodato': value.requiereComodato,
  'hasVerifiedCode': value.hasVerifiedCode,
  'hasVerifiedPrice': value.hasVerifiedPrice,
  'hasVerifiedPresentation': value.hasVerifiedPresentation,
  'hasVerifiedCategory': value.hasVerifiedCategory,
  'comodatoValid': value.comodatoValid,
  'withoutComodato': value.sinComodato,
};

SelectedProduct _selectedProductFromJson(Map<String, Object?> json) =>
    SelectedProduct(
      id: _requiredText(json, 'id'),
      codigo: _requiredText(json, 'code'),
      nombre: _requiredText(json, 'name'),
      descripcion: _text(json, 'description'),
      linea: _lineFromJson(_map(json['line'], 'line')),
      presentacion: _text(json, 'presentation'),
      precio: _double(json['price']),
      cantidad: _int(json['quantity']) ?? 0,
      categoria: _text(json, 'category'),
      comodato: json['comodato'] == null
          ? null
          : _comodatoFromJson(_map(json['comodato'], 'comodato')),
      expiracion: json['expiration'] == null ? null : _date(json['expiration']),
      requiereComodato: _bool(json, 'requiresComodato'),
      hasVerifiedCode: _bool(json, 'hasVerifiedCode', fallback: true),
      hasVerifiedPrice: _bool(json, 'hasVerifiedPrice', fallback: true),
      hasVerifiedPresentation: _bool(
        json,
        'hasVerifiedPresentation',
        fallback: true,
      ),
      hasVerifiedCategory: _bool(json, 'hasVerifiedCategory', fallback: true),
      comodatoValid: _bool(json, 'comodatoValid', fallback: true),
      sinComodato: _bool(json, 'withoutComodato'),
    );

Map<String, Object?> _lineToJson(CommercialLine value) => {
  'id': value.id,
  'name': value.nombre,
};

CommercialLine _lineFromJson(Map<String, Object?> json) => CommercialLine(
  id: _requiredText(json, 'id'),
  nombre: _requiredText(json, 'name'),
);

Map<String, Object?> _comodatoToJson(Comodato value) => {
  'id': value.id,
  'code': value.codigo,
  'name': value.nombre,
  'isGeneral': value.esGeneral,
};

Comodato _comodatoFromJson(Map<String, Object?> json) => Comodato(
  id: _requiredText(json, 'id'),
  codigo: _requiredText(json, 'code'),
  nombre: _requiredText(json, 'name'),
  esGeneral: _bool(json, 'isGeneral'),
);

Map<String, List<Comodato>> _comodatosByLine(Object? value) {
  if (value == null) return const {};
  if (value is! Map<String, Object?>) {
    throw const FormatException('Los comodatos deben agruparse por línea.');
  }
  return Map<String, List<Comodato>>.unmodifiable({
    for (final entry in value.entries)
      entry.key: List<Comodato>.unmodifiable(
        _maps(entry.value).map(_comodatoFromJson).toList(growable: false),
      ),
  });
}

Map<String, Object?> _map(Object? value, String name) {
  if (value is Map<String, Object?>) return value;
  throw FormatException('$name debe ser un objeto.');
}

List<Map<String, Object?>> _maps(Object? value) {
  if (value == null) return const [];
  if (value is! List<Object?>) {
    throw const FormatException('Una colección debe ser una lista.');
  }
  return value.map((item) => _map(item, 'elemento')).toList(growable: false);
}

List<String> _strings(Object? value) {
  if (value == null) return const [];
  if (value is! List<Object?> || value.any((item) => item is! String)) {
    throw const FormatException('Una colección de texto no es válida.');
  }
  return List.unmodifiable(value.cast<String>());
}

String _requiredText(Map<String, Object?> json, String key) {
  final value = _text(json, key);
  if (value.isEmpty) throw FormatException('Falta $key.');
  return value;
}

String _text(Map<String, Object?> json, String key, {String fallback = ''}) {
  final value = json[key];
  return value is String ? value : fallback;
}

bool _bool(Map<String, Object?> json, String key, {bool fallback = false}) {
  final value = json[key];
  return value is bool ? value : fallback;
}

int? _int(Object? value) => switch (value) {
  int value => value,
  num value => value.toInt(),
  _ => null,
};

double _double(Object? value) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

DateTime _date(Object? value) {
  if (value is! String) throw const FormatException('Fecha local no válida.');
  return DateTime.parse(value).toLocal();
}

ExecutionStatus _executionStatus(String value) =>
    ExecutionStatus.values
        .where((status) => status.name == value)
        .firstOrNull ??
    (throw FormatException('Estado de ejecución no válido: $value.'));
