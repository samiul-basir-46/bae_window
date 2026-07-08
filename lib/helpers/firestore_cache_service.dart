import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_storage/get_storage.dart';

class FirestoreCacheService {
  FirestoreCacheService._();

  static final FirestoreCacheService instance = FirestoreCacheService._();

  final GetStorage _storage = GetStorage();

  static const Duration defaultTtl = Duration(hours: 6);
  static const String _prefix = 'firestore_cache_';
  static const String _timestampKey = '__cachedAt';
  static const String _dataKey = 'data';
  static const String _docIdKey = 'id';
  static const String _timestampType = '__timestamp';

  Stream<Map<String, dynamic>?> watchDocumentCacheFirst({
    required DocumentReference<Map<String, dynamic>> ref,
    required String cacheKey,
    Duration ttl = defaultTtl,
  }) async* {
    final cached = _read<Map<String, dynamic>>(cacheKey, null);
    if (cached != null) yield cached;

    try {
      await for (final snapshot in ref.snapshots()) {
        if (!snapshot.exists || snapshot.data() == null) {
          await remove(cacheKey);
          yield null;
          continue;
        }

        final data = snapshot.data()!;
        await write(cacheKey, data);
        yield data;
      }
    } catch (_) {
      yield null;
    }
  }

  Stream<List<Map<String, dynamic>>> watchCollectionCacheFirst({
    required Query<Map<String, dynamic>> query,
    required String cacheKey,
    Duration ttl = defaultTtl,
  }) async* {
    final cached = _read<List<dynamic>>(cacheKey, null)
            ?.whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList() ??
        <Map<String, dynamic>>[];
    if (cached.isNotEmpty) yield cached;

    try {
      await for (final snapshot in query.snapshots()) {
        final docs = snapshot.docs.map((doc) {
          return {
            _docIdKey: doc.id,
            ...doc.data(),
          };
        }).toList();
        await write(cacheKey, docs);
        yield docs;
      }
    } catch (_) {}
  }

  Future<Map<String, dynamic>?> getDocument({
    required DocumentReference<Map<String, dynamic>> ref,
    required String cacheKey,
    Duration ttl = defaultTtl,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = _read<Map<String, dynamic>>(cacheKey, ttl);
      if (cached != null) return cached;
    }

    try {
      final snapshot = await ref.get(const GetOptions(source: Source.server));
      if (!snapshot.exists || snapshot.data() == null) {
        await remove(cacheKey);
        return null;
      }
      final data = snapshot.data()!;
      await write(cacheKey, data);
      return data;
    } catch (_) {
      return _read<Map<String, dynamic>>(cacheKey, null);
    }
  }

  Future<List<Map<String, dynamic>>> getCollection({
    required Query<Map<String, dynamic>> query,
    required String cacheKey,
    Duration ttl = defaultTtl,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = _read<List<dynamic>>(cacheKey, ttl);
      if (cached != null) {
        return cached
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
    }

    try {
      final snapshot = await query.get(const GetOptions(source: Source.server));
      final docs = snapshot.docs.map((doc) {
        return {
          _docIdKey: doc.id,
          ...doc.data(),
        };
      }).toList();
      await write(cacheKey, docs);
      return docs;
    } catch (_) {
      final cached = _read<List<dynamic>>(cacheKey, null);
      return cached
              ?.whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList() ??
          <Map<String, dynamic>>[];
    }
  }

  Future<void> write(String cacheKey, Object? data) async {
    await _storage.write('$_prefix$cacheKey', {
      _timestampKey: DateTime.now().millisecondsSinceEpoch,
      _dataKey: _encode(data),
    });
  }

  Future<void> remove(String cacheKey) {
    return _storage.remove('$_prefix$cacheKey');
  }

  T? _read<T>(String cacheKey, Duration? ttl) {
    final cached = _storage.read<Map>('$_prefix$cacheKey');
    if (cached == null) return null;

    final cachedAtMs = cached[_timestampKey] as int?;
    if (ttl != null && cachedAtMs != null) {
      final cachedAt = DateTime.fromMillisecondsSinceEpoch(cachedAtMs);
      if (DateTime.now().difference(cachedAt) > ttl) return null;
    }

    final decoded = _decode(cached[_dataKey]);
    if (decoded is T) return decoded;
    return null;
  }

  Object? _encode(Object? value) {
    if (value is Timestamp) {
      return {
        _timestampType: true,
        'milliseconds': value.millisecondsSinceEpoch,
      };
    }
    if (value is DateTime) {
      return value.toIso8601String();
    }
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), _encode(item)));
    }
    if (value is Iterable) {
      return value.map(_encode).toList();
    }
    return value;
  }

  Object? _decode(Object? value) {
    if (value is Map) {
      if (value[_timestampType] == true) {
        final milliseconds = value['milliseconds'];
        if (milliseconds is int) {
          return Timestamp.fromMillisecondsSinceEpoch(milliseconds);
        }
      }
      return value.map((key, item) => MapEntry(key.toString(), _decode(item)));
    }
    if (value is List) {
      return value.map(_decode).toList();
    }
    return value;
  }
}
