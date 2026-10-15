import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class AppDatabase {
  static const _storageKey = 'voxelcost3d_database_v1';
  static Future<void>? _ready;
  static final _records = <PrintRecord>[];
  static final _inventory = <InventoryItem>[];
  static final _materials = <MaterialCatalogItem>[];
  static final _colors = <ColorCatalogItem>[];
  static int _nextRecordId = 1;

  static Future<void> _ensureReady() => _ready ??= _load();

  static Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) return;

    final data = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    final rawRecords = _decodeList(data['records']);
    _records.addAll(rawRecords.map(PrintRecord.fromMap));
    _inventory
        .addAll(_decodeList(data['inventory']).map(InventoryItem.fromMap));
    _materials.addAll(_decodeList(data['materials']).map((item) =>
        MaterialCatalogItem(
            item['nombre'] as String, (item['esPersonalizado'] as int) == 1)));
    _colors.addAll(_decodeList(data['colors']).map((item) => ColorCatalogItem(
        item['nombre'] as String,
        item['hex'] as String,
        (item['esPersonalizado'] as int) == 1)));

    // Migración automática: asegurar cantidad >= 1 para registros legados y persistir
    var needsMigrationSave = false;
    for (final r in _records) {
      if (r.cantidad < 1) {
        r.cantidad = 1;
        needsMigrationSave = true;
      }
    }
    if (rawRecords.any((m) => !m.containsKey('cantidad'))) {
      needsMigrationSave = true;
    }
    if (needsMigrationSave) {
      await _save();
    }

    if (_records.isNotEmpty) {
      _nextRecordId =
          _records.map((record) => record.id).reduce((a, b) => a > b ? a : b) +
              1;
    }
  }

  static List<Map<String, dynamic>> _decodeList(dynamic value) {
    if (value is! List) return [];
    return value.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  static Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = await prefs.setString(
      _storageKey,
      jsonEncode({
        'records': _records.map((item) => item.toMap()).toList(),
        'inventory': _inventory.map((item) => item.toMap()).toList(),
        'materials': _materials.map((item) => item.toMap()).toList(),
        'colors': _colors.map((item) => item.toMap()).toList(),
      }),
    );
    if (!saved) {
      throw StateError('El almacenamiento rechazó los cambios.');
    }
  }

  Future<List<PrintRecord>> records() async {
    await _ensureReady();
    return [..._records]..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<int> insertRecord(PrintRecord record) async {
    await _ensureReady();
    record.id = _nextRecordId++;
    _records.add(record);
    await _save();
    return record.id;
  }

  Future<int> updateRecord(PrintRecord record) async {
    await _ensureReady();
    final index = _records.indexWhere((item) => item.id == record.id);
    if (index < 0) return 0;
    _records[index] = record;
    await _save();
    return 1;
  }

  Future<int> deleteRecord(
    PrintRecord record, {
    List<InventoryItem> inventoryUpdates = const [],
  }) async {
    await _ensureReady();
    final recordIndex = _records.indexWhere((item) => item.id == record.id);
    if (recordIndex < 0) return 0;

    final removedRecord = _records.removeAt(recordIndex);
    final previousInventory = <int, InventoryItem>{};
    for (final updatedItem in inventoryUpdates) {
      final index =
          _inventory.indexWhere((item) => item.id == updatedItem.id);
      if (index < 0) continue;
      previousInventory[index] = _inventory[index];
      _inventory[index] = updatedItem;
    }

    try {
      await _save();
    } catch (_) {
      _records.insert(recordIndex, removedRecord);
      for (final entry in previousInventory.entries) {
        _inventory[entry.key] = entry.value;
      }
      rethrow;
    }
    return 1;
  }

  Future<List<InventoryItem>> inventory() async {
    await _ensureReady();
    return [..._inventory];
  }

  Future<void> insertItem(InventoryItem item) async {
    await _ensureReady();
    _inventory.removeWhere((current) => current.id == item.id);
    _inventory.add(item);
    await _save();
  }

  Future<void> updateItem(InventoryItem item) => insertItem(item);

  Future<void> deleteItem(InventoryItem item) async {
    await _ensureReady();
    _inventory.removeWhere((current) => current.id == item.id);
    await _save();
  }

  Future<List<MaterialCatalogItem>> materialCatalog() async {
    await _ensureReady();
    return [..._materials];
  }

  Future<List<ColorCatalogItem>> colorCatalog() async {
    await _ensureReady();
    return [..._colors];
  }

  Future<void> insertMaterial(MaterialCatalogItem item) async {
    await _ensureReady();
    if (!_materials.any((current) => current.nombre == item.nombre)) {
      _materials.add(item);
      await _save();
    }
  }

  Future<void> insertColor(ColorCatalogItem item) async {
    await _ensureReady();
    if (!_colors.any((current) => current.nombre == item.nombre)) {
      _colors.add(item);
      await _save();
    }
  }

  Future<void> ensureDefaultCatalog({
    required List<MaterialCatalogItem> materials,
    required List<ColorCatalogItem> colors,
  }) async {
    await _ensureReady();
    var changed = false;
    for (final item in materials) {
      if (_materials.any((current) => current.nombre == item.nombre)) continue;
      _materials.add(item);
      changed = true;
    }
    for (final item in colors) {
      if (_colors.any((current) => current.nombre == item.nombre)) continue;
      _colors.add(item);
      changed = true;
    }
    if (changed) await _save();
  }
}
