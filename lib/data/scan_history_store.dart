import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

enum ScanHistoryEntryType {
  scanned,
  generated,
}

class ScanHistoryEntry {
  final String id;
  final ScanHistoryEntryType type;
  final String value;
  final DateTime createdAt;
  final bool isFavorite;

  const ScanHistoryEntry({
    required this.id,
    required this.type,
    required this.value,
    required this.createdAt,
    required this.isFavorite,
  });

  ScanHistoryEntry copyWith({
    String? id,
    ScanHistoryEntryType? type,
    String? value,
    DateTime? createdAt,
    bool? isFavorite,
  }) {
    return ScanHistoryEntry(
      id: id ?? this.id,
      type: type ?? this.type,
      value: value ?? this.value,
      createdAt: createdAt ?? this.createdAt,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'type': type.name,
      'value': value,
      'createdAt': createdAt.toIso8601String(),
      'isFavorite': isFavorite,
    };
  }

  static ScanHistoryEntry fromJson(Map<String, Object?> json) {
    final typeRaw = json['type'];
    final createdAtRaw = json['createdAt'];

    return ScanHistoryEntry(
      id: (json['id'] as String?) ?? UniqueKey().toString(),
      type: ScanHistoryEntryType.values.firstWhere(
        (t) => t.name == typeRaw,
        orElse: () => ScanHistoryEntryType.scanned,
      ),
      value: (json['value'] as String?) ?? '',
      createdAt: DateTime.tryParse(createdAtRaw?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      isFavorite: (json['isFavorite'] as bool?) ?? false,
    );
  }
}

class ScanHistoryStore extends ChangeNotifier {
  static const String _fileName = 'scan_history.json';

  final List<ScanHistoryEntry> _entries = [];
  bool _loaded = false;
  bool _saving = false;

  List<ScanHistoryEntry> get entries => List.unmodifiable(_entries);

  List<ScanHistoryEntry> get favorites {
    return List.unmodifiable(_entries.where((e) => e.isFavorite));
  }

  bool get loaded => _loaded;

  Future<void> load() async {
    if (_loaded) return;

    try {
      final file = await _getFile();
      if (!await file.exists()) {
        _loaded = true;
        notifyListeners();
        return;
      }

      final raw = await file.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        _loaded = true;
        notifyListeners();
        return;
      }

      _entries
        ..clear()
        ..addAll(
          decoded
              .whereType<Map<dynamic, dynamic>>()
              .map((e) => Map<String, Object?>.from(e))
              .map(ScanHistoryEntry.fromJson)
              .where((e) => e.value.trim().isNotEmpty),
        );

      _entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      _loaded = true;
      notifyListeners();
    } catch (_) {
      _loaded = true;
      notifyListeners();
    }
  }

  Future<void> addScanned(String value) async {
    await _add(
      type: ScanHistoryEntryType.scanned,
      value: value,
    );
  }

  Future<void> addGenerated(String value) async {
    await _add(
      type: ScanHistoryEntryType.generated,
      value: value,
    );
  }

  Future<void> _add({
    required ScanHistoryEntryType type,
    required String value,
  }) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;

    if (_entries.isNotEmpty) {
      final latest = _entries.first;
      if (latest.value == trimmed && latest.type == type) {
        return;
      }
    }

    final entry = ScanHistoryEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      type: type,
      value: trimmed,
      createdAt: DateTime.now(),
      isFavorite: false,
    );

    _entries.insert(0, entry);
    notifyListeners();
    await _save();
  }

  Future<void> toggleFavorite(String id) async {
    final index = _entries.indexWhere((e) => e.id == id);
    if (index < 0) return;

    _entries[index] = _entries[index].copyWith(
      isFavorite: !_entries[index].isFavorite,
    );

    notifyListeners();
    await _save();
  }

  Future<void> remove(String id) async {
    _entries.removeWhere((e) => e.id == id);
    notifyListeners();
    await _save();
  }

  Future<void> clear() async {
    _entries.clear();
    notifyListeners();
    await _save();
  }

  Future<void> _save() async {
    if (_saving) return;

    _saving = true;
    try {
      final file = await _getFile();
      final encoded = jsonEncode(_entries.map((e) => e.toJson()).toList());
      await file.writeAsString(encoded);
    } catch (_) {
    } finally {
      _saving = false;
    }
  }

  Future<File> _getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }
}

class ScanHistoryProvider extends InheritedNotifier<ScanHistoryStore> {
  const ScanHistoryProvider({
    required ScanHistoryStore store,
    required super.child,
    super.key,
  }) : super(notifier: store);

  static ScanHistoryStore of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<ScanHistoryProvider>();
    if (provider == null) {
      throw StateError('ScanHistoryProvider not found in widget tree');
    }

    final store = provider.notifier;
    if (store == null) {
      throw StateError('ScanHistoryStore is null');
    }

    return store;
  }
}
