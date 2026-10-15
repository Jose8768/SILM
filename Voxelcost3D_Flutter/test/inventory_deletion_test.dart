import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voxelcost3d/controllers.dart';
import 'package:voxelcost3d/database.dart';
import 'package:voxelcost3d/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  test('Deleting a print restores inventory and persists both changes',
      () async {
    final db = AppDatabase();
    const color = 0xFF111111;
    final inventoryItem = InventoryItem(
      id: 'delete-record-atomicity-test',
      material: 'PLA',
      color: 'Negro',
      colorHex: '#111111',
      stockActual: 900,
      stockInicial: 1000,
    );
    await db.insertItem(inventoryItem);
    final record = PrintRecord(
      pieceType: 'Test print record',
      figureCategory: 'Test',
      date: DateTime.now().millisecondsSinceEpoch,
      materials: [
        MaterialData(
          type: 'PLA',
          grams: 50,
          color: color,
          colorName: 'Negro',
        ),
      ],
    );
    await db.insertRecord(record);
    final inventoryVm = InventoryViewModel(db);
    addTearDown(inventoryVm.dispose);
    await inventoryVm.refresh();

    final restored = await inventoryVm.deletePrintRecord(
      record,
      returnToStock: true,
    );

    expect(restored, 50);
    expect(
      (await db.inventory())
          .singleWhere((item) => item.id == inventoryItem.id)
          .stockActual,
      950,
    );
    expect(
      (await db.records()).any((item) => item.id == record.id),
      isFalse,
    );
  });
}
