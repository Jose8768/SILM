import 'package:flutter/foundation.dart';
import 'database.dart';
import 'models.dart';
import 'theme.dart';

class AuthViewModel extends ChangeNotifier {
  String? error;
  bool login(String email, String password) {
    final cleanEmail = email.trim().toLowerCase();
    if ((cleanEmail == 'admin' || cleanEmail == 'admin@voxel.com') &&
        password.trim() == 'admin123') {
      error = null;
      return true;
    }
    error = 'Credenciales incorrectas. Usa admin/admin123';
    notifyListeners();
    return false;
  }
}

class PrintViewModel extends ChangeNotifier {
  final AppDatabase db;
  List<PrintRecord> allRecords = [];
  PrintRecord? selectedRecord;
  String? error;
  bool _disposed = false;
  PrintViewModel(this.db) {
    refresh();
  }
  Future<void> refresh() async {
    try {
      final records = await db.records();
      if (_disposed) return;
      error = null;
      allRecords = records;
      notifyListeners();
    } catch (exception) {
      if (_disposed) return;
      error = 'No se pudieron cargar los registros: $exception';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  int get totalPrints => allRecords.length;
  int get totalPieces => allRecords.fold(0, (sum, r) => sum + r.cantidad);
  double get totalGrams => allRecords.fold(0.0, (sum, r) => sum + r.totalGrams);
  double get totalPlaGrams => allRecords.fold(
      0.0,
      (sum, r) =>
          sum +
          r.materials
              .where((m) => m.type.toUpperCase() == 'PLA')
              .fold(0.0, (s, m) => s + (m.grams * r.cantidad)));
  double get totalPetgGrams => allRecords.fold(
      0.0,
      (sum, r) =>
          sum +
          r.materials
              .where((m) => m.type.toUpperCase() == 'PETG')
              .fold(0.0, (s, m) => s + (m.grams * r.cantidad)));

  PrintRecord? get latestRecord => allRecords.isEmpty ? null : allRecords.first;

  /// Retorna un rango continuo de meses (rellena con 0 los meses intermedios como JUN, JUL, AGO)
  List<MonthlyStats> get monthlyAnalytics {
    final now = DateTime.now();
    DateTime start;
    DateTime end = DateTime(now.year, now.month, 1);

    if (allRecords.isEmpty) {
      // Si no hay registros, mostramos los últimos 6 meses en cero
      start = DateTime(now.year, now.month - 5, 1);
    } else {
      final sortedDates = allRecords
          .map((r) => DateTime.fromMillisecondsSinceEpoch(r.date))
          .toList()
        ..sort();
      final earliest = sortedDates.first;
      final latest = sortedDates.last;
      start = DateTime(earliest.year, earliest.month, 1);
      final latestMonth = DateTime(latest.year, latest.month, 1);
      if (latestMonth.isAfter(end)) end = latestMonth;

      // Asegurar al menos 6 meses de rango para una gráfica visualmente balanceada
      final monthDiff = (end.year - start.year) * 12 + end.month - start.month;
      if (monthDiff < 5) {
        start = DateTime(end.year, end.month - 5, 1);
      }
    }

    final grouped = <String, List<PrintRecord>>{};
    for (final record in allRecords) {
      final date = DateTime.fromMillisecondsSinceEpoch(record.date);
      final key = '${date.year}-${date.month}';
      grouped.putIfAbsent(key, () => []).add(record);
    }

    final result = <MonthlyStats>[];
    var current = DateTime(start.year, start.month, 1);
    while (!current.isAfter(end)) {
      final key = '${current.year}-${current.month}';
      final recordsInMonth = grouped[key] ?? [];
      final grams = recordsInMonth.fold(
          0.0,
          (sum, r) =>
              sum +
              r.materials.fold(0.0, (s, m) => s + (m.grams * r.cantidad)));
      final pieces = recordsInMonth.fold(0, (sum, r) => sum + r.cantidad);
      result.add(MonthlyStats(
        _month(current.month),
        grams,
        pieces, // Suma de cantidades producidas
        current.millisecondsSinceEpoch,
      ));
      current = DateTime(current.year, current.month + 1, 1);
    }

    return result;
  }

  /// Desglose de consumo por material (gramos totales = gramos × cantidad)
  Map<String, double> get materialBreakdown {
    final map = <String, double>{};
    for (final r in allRecords) {
      for (final m in r.materials) {
        final key = m.type.trim().toUpperCase();
        map[key] = (map[key] ?? 0.0) + (m.grams * r.cantidad);
      }
    }
    return map;
  }

  /// Desglose de consumo por color (nombre del color y gramos totales = gramos × cantidad)
  Map<String, double> get colorBreakdown {
    final map = <String, double>{};
    for (final r in allRecords) {
      for (final m in r.materials) {
        final colorObj = findVoxelColor(value: m.color, name: m.colorName);
        final key = colorObj.name;
        map[key] = (map[key] ?? 0.0) + (m.grams * r.cantidad);
      }
    }
    return map;
  }

  String _month(int month) => const [
        'ENE',
        'FEB',
        'MAR',
        'ABR',
        'MAY',
        'JUN',
        'JUL',
        'AGO',
        'SEP',
        'OCT',
        'NOV',
        'DIC'
      ][month - 1];

  void selectRecord(PrintRecord? record) {
    selectedRecord = record;
    notifyListeners();
  }

  Future<void> saveRecord(PrintRecord record) async {
    if (record.id == 0) {
      await db.insertRecord(record);
    } else {
      await db.updateRecord(record);
    }
    await refresh();
  }

  Future<void> deleteRecord(PrintRecord record) async {
    final deleted = await db.deleteRecord(record);
    if (deleted != 1) {
      throw StateError('El registro de impresión ya no existe.');
    }
    await refresh();
  }
}

class InventoryViewModel extends ChangeNotifier {
  final AppDatabase db;
  List<InventoryItem> inventoryItems = [];
  List<MaterialCatalogItem> materialCatalog = [];
  List<ColorCatalogItem> colorCatalog = [];
  String? error;
  bool _disposed = false;

  InventoryViewModel(this.db) {
    _init();
  }

  Future<void> _init() async {
    try {
      const materials = [
        'PLA',
        'PETG',
        'ABS',
        'TPU',
        'ASA',
        'Nylon',
        'Carbon Fiber',
        'Resina'
      ];
      await db.ensureDefaultCatalog(
        materials:
            materials.map((item) => MaterialCatalogItem(item, false)).toList(),
        colors: voxelColorPalette
            .map((item) => ColorCatalogItem(item.name, item.hex, false))
            .toList(),
      );
      await refresh();
    } catch (exception) {
      if (_disposed) return;
      error = 'No se pudo iniciar el inventario: $exception';
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    try {
      final items = await db.inventory();
      final materials = await db.materialCatalog();
      final colors = await db.colorCatalog();
      if (_disposed) return;
      error = null;
      inventoryItems = items;
      materialCatalog = materials;
      colorCatalog = colors;
      notifyListeners();
    } catch (exception) {
      if (_disposed) return;
      error = 'No se pudo cargar el inventario: $exception';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  int get lowStockCount => inventoryItems
      .where(
          (i) => i.stockInicial > 0 && (i.stockActual / i.stockInicial) <= 0.2)
      .length;

  List<InventoryItem> get lowStockItems => inventoryItems
      .where(
          (i) => i.stockInicial > 0 && (i.stockActual / i.stockInicial) <= 0.2)
      .toList();

  InventoryItem? findMatchingItem(
    String material, {
    String? colorName,
    String? colorHex,
    int? colorValue,
  }) {
    final matClean = material.trim().toLowerCase();
    final targetColor =
        findVoxelColor(value: colorValue, name: colorName, hex: colorHex);

    for (final item in inventoryItems) {
      if (item.material.trim().toLowerCase() == matClean) {
        if (item.color.trim().toLowerCase() == targetColor.name.toLowerCase() ||
            item.colorHex.replaceAll('#', '').toUpperCase() ==
                targetColor.hex.replaceAll('#', '').toUpperCase()) {
          return item;
        }
      }
    }
    return null;
  }

  double getAvailableStock(
    String material, {
    String? colorName,
    String? colorHex,
    int? colorValue,
  }) {
    final item = findMatchingItem(
      material,
      colorName: colorName,
      colorHex: colorHex,
      colorValue: colorValue,
    );
    return item?.stockActual ?? 0.0;
  }

  /// Descuenta gramos del inventario. Retorna verdadero si la bobina quedó en estado de bajo stock (<= 20%).
  Future<bool> deductGrams(
    String material,
    double grams, {
    String? colorName,
    String? colorHex,
    int? colorValue,
  }) async {
    final item = findMatchingItem(
      material,
      colorName: colorName,
      colorHex: colorHex,
      colorValue: colorValue,
    );
    if (item == null) return false;

    item.stockActual = (item.stockActual - grams).clamp(0.0, double.infinity);
    await db.updateItem(item);
    await refresh();

    final isLow =
        item.stockInicial > 0 && (item.stockActual / item.stockInicial) <= 0.2;
    return isLow;
  }

  /// Devuelve gramos al inventario (ej. al eliminar o reducir una impresión).
  Future<void> restoreGrams(
    String material,
    double grams, {
    String? colorName,
    String? colorHex,
    int? colorValue,
  }) async {
    final item = findMatchingItem(
      material,
      colorName: colorName,
      colorHex: colorHex,
      colorValue: colorValue,
    );
    if (item == null) return;

    item.stockActual =
        (item.stockActual + grams).clamp(0.0, item.stockInicial * 2);
    await db.updateItem(item);
    await refresh();
  }

  Future<double> deletePrintRecord(
    PrintRecord record, {
    required bool returnToStock,
  }) async {
    final updatedItems = <String, InventoryItem>{};
    var restoredGrams = 0.0;

    if (returnToStock) {
      for (final material in record.materials) {
        final item = findMatchingItem(
          material.type,
          colorName: material.colorName,
          colorValue: material.color,
        );
        if (item == null) continue;

        final current = updatedItems[item.id] ?? item;
        final newStock =
            (current.stockActual + material.grams * record.cantidad)
                .clamp(0.0, current.stockInicial * 2)
                .toDouble();
        restoredGrams += newStock - current.stockActual;
        updatedItems[item.id] = current.copyWith(stockActual: newStock);
      }
    }

    final deleted = await db.deleteRecord(
      record,
      inventoryUpdates: updatedItems.values.toList(),
    );
    if (deleted != 1) {
      throw StateError('El registro de impresión ya no existe.');
    }
    await refresh();
    return restoredGrams;
  }

  static const List<String> defaultBrands = [
    'eSun',
    'Sunlu',
    'Polymaker',
    'Creality',
    'Bambu Lab',
    'Overture',
    'Prusament',
    'Anycubic',
    'Flashforge',
    'Printalot',
    'GST3D',
    'Hatchbox',
    'Kingroon',
    'Genérica',
  ];

  static const List<String> defaultFinishes = [
    'Estándar',
    'Silk (Seda)',
    'Mate',
    'Glitter / Brillante',
    'Fibra de Carbono',
    'Transparente',
    'Madera / Wood',
    'Mármol / Marble',
    'Glow in Dark',
  ];

  double get totalGramsInStock =>
      inventoryItems.fold(0.0, (sum, i) => sum + i.stockActual);

  double get totalKgInStock => totalGramsInStock / 1000.0;

  double get totalInventoryValue =>
      inventoryItems.fold(0.0, (sum, i) => sum + i.currentEstimatedValue);

  int get activeSpoolsCount =>
      inventoryItems.where((i) => !i.isDepleted).length;

  int get depletedStockCount =>
      inventoryItems.where((i) => i.isDepleted).length;

  List<String> get allBrands {
    final set = <String>{...defaultBrands};
    for (final item in inventoryItems) {
      if (item.brand.trim().isNotEmpty) set.add(item.brand.trim());
    }
    return set.toList();
  }

  Future<void> setExactStock(InventoryItem item, double newStock) async {
    item.stockActual = newStock.clamp(0.0, double.infinity);
    await db.updateItem(item);
    await refresh();
  }

  Future<void> addItem(InventoryItem item) async {
    await db.insertItem(item);
    await db.insertMaterial(MaterialCatalogItem(item.material));
    await db.insertColor(ColorCatalogItem(item.color, item.colorHex));
    await refresh();
  }

  Future<void> updateItem(InventoryItem item) async {
    await db.updateItem(item);
    await db.insertMaterial(MaterialCatalogItem(item.material));
    await db.insertColor(ColorCatalogItem(item.color, item.colorHex));
    await refresh();
  }

  Future<void> duplicateItem(InventoryItem item) async {
    final copy = item.copyWith(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      stockActual: item.stockInicial,
    );
    await addItem(copy);
  }

  Future<void> updateStock(InventoryItem item, double delta) async {
    item.stockActual =
        (item.stockActual + delta).clamp(0.0, item.stockInicial * 2).toDouble();
    await db.updateItem(item);
    await refresh();
  }

  Future<void> deleteItem(InventoryItem item) async {
    await db.deleteItem(item);
    await refresh();
  }
}
