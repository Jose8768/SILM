import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voxelcost3d/controllers.dart';
import 'package:voxelcost3d/database.dart';
import 'package:voxelcost3d/main.dart';
import 'package:voxelcost3d/theme.dart';
import 'package:voxelcost3d/models.dart';
import 'package:voxelcost3d/screens.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  testWidgets('Verifica el conmutador y el modo oscuro global',
      (WidgetTester tester) async {
    await tester.pumpWidget(const VoxelcostApp());

    expect(find.text('VOXELCOST3D'), findsOneWidget);
    expect(find.text('ACCEDER AL TALLER'), findsOneWidget);

    final textFields = find.byType(TextField);
    expect(textFields, findsNWidgets(2));
    await tester.enterText(textFields.at(0), 'admin');
    await tester.enterText(textFields.at(1), 'admin123');
    await tester.tap(find.text('ACCEDER AL TALLER'));
    await tester.pumpAndSettle();

    expect(find.text('¡BIENVENIDO!'), findsOneWidget);
    await tester.tap(find.byType(SidebarToggleIcon).first);
    await tester.pumpAndSettle();

    expect(find.text('OPERATIVO'), findsNothing);
    expect(find.byTooltip('Activar modo oscuro'), findsOneWidget);

    await tester.tap(find.byTooltip('Activar modo oscuro'));
    await tester.pumpAndSettle();
    expect(bgBase, const Color(0xFF111318));
    expect(surfaceCard, const Color(0xFF1B1E25));
    expect(textPrimary, const Color(0xFFF1F3F6));
    expect(voxelTheme().brightness, Brightness.dark);
    expect(find.byTooltip('Activar modo claro'), findsOneWidget);

    await tester.tap(find.text('Registro de Impresiones'));
    await tester.pumpAndSettle();
    expect(find.text('HISTORIAL TÉCNICO'), findsOneWidget);
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold).last).backgroundColor,
      const Color(0xFF111318),
    );
    await tester.tap(find.byType(SidebarToggleIcon).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Activar modo claro'));
    await tester.pumpAndSettle();
    expect(bgBase, const Color(0xFFF5F5F7));
  });

  testWidgets('Verifica tokens de color y tema industrial',
      (WidgetTester tester) async {
    final theme = voxelTheme();
    expect(theme.scaffoldBackgroundColor, bgBase);
    expect(theme.colorScheme.primary, accentPetrol);
    expect(theme.colorScheme.secondary, accentAmber);
    expect(theme.colorScheme.surface, surfaceCard);
  });

  testWidgets('El análisis de producción se adapta al ancho de pantalla',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final printVm = PrintViewModel(AppDatabase());
    final inventoryVm = InventoryViewModel(AppDatabase());
    addTearDown(printVm.dispose);
    addTearDown(inventoryVm.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: voxelTheme(),
        home: AnalyticsScreen(
          vm: printVm,
          inventoryVm: inventoryVm,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ANÁLISIS DE PRODUCCIÓN'), findsOneWidget);
    expect(find.text('MATERIAL CONSUMIDO'), findsOneWidget);
    expect(find.text('PIEZAS FABRICADAS'), findsOneWidget);
    expect(find.text('VALOR EN MATERIAL'), findsNothing);
    expect(find.text('CATEGORÍAS DE USO'), findsOneWidget);
    expect(find.text('IMPRESIONES CON MAYOR CONSUMO'), findsOneWidget);
    expect(find.text('MATERIALES Y COLORES'), findsOneWidget);
    expect(
      tester
          .getSize(find.byKey(const ValueKey('analytics_evolution_card')))
          .width,
      tester
          .getSize(find.byKey(const ValueKey('analytics_category_card')))
          .width,
    );
    expect(
      tester
          .getTopRight(find.byKey(const ValueKey('analytics_category_card')))
          .dx,
      1420,
    );
    expect(
      tester
          .getSize(find.byKey(const ValueKey('analytics_category_card')))
          .height,
      tester
          .getSize(find.byKey(const ValueKey('analytics_evolution_card')))
          .height,
    );
    expect(
      tester
          .getSize(find.byKey(const ValueKey('analytics_top_pieces_card')))
          .width,
      tester
          .getSize(find.byKey(const ValueKey('analytics_material_color_card')))
          .width,
    );
    expect(
      tester
          .getSize(find.byKey(const ValueKey('analytics_top_pieces_card')))
          .height,
      tester
          .getSize(find.byKey(const ValueKey('analytics_material_color_card')))
          .height,
    );
    expect(
      tester.getBottomRight(find.text('Sin datos').last).dy,
      lessThanOrEqualTo(720),
    );
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(900, 1000);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(1440, 1000);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Los datos de impresora quedan arriba de la pieza en todas las pantallas',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final printVm = PrintViewModel(AppDatabase());
    final inventoryVm = InventoryViewModel(AppDatabase());
    addTearDown(printVm.dispose);
    addTearDown(inventoryVm.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: voxelTheme(),
        home: PrintFormScreen(vm: printVm, inventoryVm: inventoryVm),
      ),
    );
    await tester.pumpAndSettle();

    final printerPanel = find.byKey(const ValueKey('printer_info_panel'));
    expect(
        find.byKey(const ValueKey('printer_select_dropdown')), findsOneWidget);
    expect(tester.getTopLeft(printerPanel).dx, lessThan(100));
    expect(
      tester.getTopLeft(find.text('DATOS DE LA IMPRESORA')).dy,
      lessThan(
        tester.getTopLeft(find.text('INFORMACIÓN DE LA PIEZA')).dy,
      ),
    );
    expect(
      tester.getTopLeft(find.text('INFORMACIÓN DE LA PIEZA')).dy,
      lessThan(
        tester.getTopLeft(find.text('MATERIALES UTILIZADOS')).dy,
      ),
    );
    expect(tester.takeException(), isNull);

    expect(
        find.byKey(const ValueKey('material_combination_card')), findsNothing);
    final combinationToggle =
        find.byKey(const ValueKey('material_combination_toggle'));

    final firstGrams = find.byKey(const ValueKey('material_grams_0'));
    await tester.ensureVisible(firstGrams);
    await tester.enterText(firstGrams, '12.5');
    await tester.pump();

    final addMaterialButton = find.text('AGREGAR OTRO MATERIAL');
    await tester.ensureVisible(addMaterialButton);
    await tester.tap(addMaterialButton);
    await tester.pumpAndSettle();
    final secondGrams = find.byKey(const ValueKey('material_grams_1'));
    await tester.ensureVisible(secondGrams);
    await tester.enterText(secondGrams, '7.5');
    await tester.pump();

    // Verificamos que no existe el campo de cantidad de piezas (eliminado por nuevo flujo)
    expect(find.byKey(const ValueKey('print_quantity_field')), findsNothing);

    // Verificamos el tope de 60 minutos en el tiempo de impresión
    final minutesField = find.byKey(const ValueKey('print_minutes_field'));
    await tester.ensureVisible(minutesField);
    await tester.enterText(minutesField, '75');
    await tester.pump();
    expect(find.text('60'), findsOneWidget);

    await tester.ensureVisible(combinationToggle);
    await tester.tap(combinationToggle);
    await tester.pumpAndSettle();
    expect(find.text('COMBINACIÓN DE MATERIAL Y COLORES'), findsOneWidget);
    expect(find.text('MATERIAL'), findsOneWidget);
    expect(find.text('COLOR'), findsOneWidget);
    expect(find.text('GRAMOS'), findsOneWidget);
    expect(find.text('12.5 g'), findsOneWidget);
    expect(find.text('7.5 g'), findsOneWidget);
    expect(find.text('20.0 g / pieza'), findsOneWidget);
    expect(find.text('1 impresión'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(combinationToggle);
    await tester.pumpAndSettle();
    expect(
        find.byKey(const ValueKey('material_combination_card')), findsNothing);

    await tester.drag(find.byType(ListView).last, const Offset(0, 2000));
    await tester.pumpAndSettle();
    tester.view.physicalSize = const Size(800, 1100);
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(printerPanel).dx, lessThan(100));
    expect(tester.takeException(), isNull);
  });

  testWidgets('El formulario de bobinas omite costos y ocupa todo el ancho',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final vm = InventoryViewModel(AppDatabase())
      ..materialCatalog = [MaterialCatalogItem('PLA', false)];
    addTearDown(vm.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: voxelTheme(),
        home: AddProductScreen(vm: vm),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('3. CAPACIDAD Y PESAJE'), findsOneWidget);
    expect(find.text('4. PARÁMETROS TÉCNICOS Y UBICACIÓN'), findsNothing);
    expect(find.text('5. PARÁMETROS TÉCNICOS Y UBICACIÓN'), findsNothing);
    expect(find.text('4. COSTOS Y PRECIOS'), findsNothing);
    expect(find.text('Precio de compra de la bobina'), findsNothing);
    expect(find.text('Costo unitario calculado:'), findsNothing);
    expect(tester.getSize(find.byType(ListView).last).width, 1200);

    final colorNameField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.hintText == 'Ej: Rojo Carmesí, Gris Galáctico...',
    );
    await tester.ensureVisible(colorNameField);
    await tester.enterText(colorNameField, 'Oro');
    await tester.pump();
    final preview = tester.widget<KeyedSubtree>(
      find.byKey(const ValueKey('product_color_preview')),
    );
    final previewCircle = preview.child as Container;
    expect(
      (previewCircle.decoration! as BoxDecoration).color,
      const Color(0xFFD4AF37),
    );
  });

  testWidgets(
      'El pedido conserva el inventario y despliega el formulario nuevo',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final vm = InventoryViewModel(AppDatabase());
    addTearDown(vm.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
        ),
        home: MaterialOrderScreen(
          inventoryVm: vm,
          onToggleMenu: () {},
          onHoverMenu: () {},
          isPinned: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    vm.inventoryItems = [
      InventoryItem(
        material: 'PLA',
        color: 'Negro',
        stockInicial: 1000,
        stockActual: 150,
      ),
      InventoryItem(
        material: 'PETG',
        color: 'Azul',
        stockInicial: 1000,
        stockActual: 0,
      ),
    ];
    vm.notifyListeners();
    await tester.pumpAndSettle();

    expect(find.text('MATERIALES POR PEDIR'), findsNothing);
    expect(find.text('PLA'), findsOneWidget);
    expect(find.text('PETG'), findsOneWidget);
    expect(find.text('15%'), findsOneWidget);
    expect(find.text('AGOTADO'), findsOneWidget);
    expect(find.text('Nuevo pedido'), findsOneWidget);
    expect(find.byType(SidebarToggleIcon), findsOneWidget);
    expect(find.text('Link de la página donde se encontró el material'),
        findsNothing);

    await tester.tap(find.text('Nuevo pedido'));
    await tester.pump();
    expect(find.text('Link de la página donde se encontró el material'),
        findsOneWidget);
    expect(find.text('Material'), findsOneWidget);
    expect(find.text('Color del filamento'), findsOneWidget);

    final firstOrderLink = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.key is ValueKey &&
          (widget.key! as ValueKey).value.toString().startsWith('order_link_'),
    );
    await tester.enterText(firstOrderLink, 'https://example.com/product');
    expect(find.text('Agregar otro pedido'), findsOneWidget);
    expect(find.text('Pedido 1'), findsOneWidget);
    final orderLinks = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.key is ValueKey &&
          (widget.key! as ValueKey).value.toString().startsWith('order_link_'),
    );
    expect(orderLinks, findsOneWidget);
    expect(find.byTooltip('Abrir página web'), findsOneWidget);
    expect(
      tester.widget<TextField>(orderLinks.first).controller!.text,
      'https://example.com/product',
    );

    expect(find.text('Urgencia en el laboratorio'), findsNWidgets(2));
    expect(find.text('Tipo de urgencia'), findsNothing);
    expect(find.text('Urgencia en texto'), findsNothing);
    expect(find.text('Peso usado (opcional)'), findsNothing);
    expect(find.text('Consumible y peso'), findsNothing);
    final spoolWeightY =
        tester.getTopLeft(find.text('Peso del carrete').first).dy;
    final urgencySectionY =
        tester.getTopLeft(find.text('Urgencia en el laboratorio').first).dy;
    final consumableSectionY =
        tester.getTopLeft(find.text('Consumibles').first).dy;
    expect(spoolWeightY, lessThan(urgencySectionY));
    expect(urgencySectionY, lessThan(consumableSectionY));

    final addConsumable = find.text('Agregar otro consumible').first;
    await tester.scrollUntilVisible(
      addConsumable,
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(addConsumable);
    await tester.pumpAndSettle();
    expect(find.text('Consumible 1'), findsOneWidget);
    expect(find.text('Consumible 2'), findsOneWidget);
    expect(find.byTooltip('Quitar consumible'), findsOneWidget);

    final secondConsumable = find.byWidgetPredicate((widget) {
      if (widget is! DropdownButtonFormField<String> ||
          widget.key is! ValueKey) {
        return false;
      }
      final key = (widget.key! as ValueKey).value.toString();
      return key.startsWith('consumable_dropdown_') && key.endsWith('_1');
    });
    await tester.ensureVisible(secondConsumable);
    await tester.tap(secondConsumable);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Otro (escribir)').last);
    await tester.pumpAndSettle();
    expect(find.text('Escribe el consumible'), findsOneWidget);

    final colorDropdown = find.byType(DropdownButtonFormField<String>).at(1);
    await tester.ensureVisible(colorDropdown);
    await tester.pumpAndSettle();
    await tester.tap(colorDropdown);
    await tester.pumpAndSettle();
    expect(find.text('Marrón Van Dyke'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('filament_palette_swatch_marrón van dyke')),
      findsOneWidget,
    );
    await tester.tap(find.text('Marrón Van Dyke'));
    await tester.pump();
    expect(
        find.byKey(const ValueKey('selected_filament_swatch')), findsOneWidget);

    await tester.ensureVisible(colorDropdown);
    await tester.pumpAndSettle();
    await tester.tap(colorDropdown);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Oro'),
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Oro'));
    await tester.pump();
    final goldSwatch = tester.widget<Container>(
      find.byKey(const ValueKey('selected_filament_swatch')),
    );
    expect(
      (goldSwatch.decoration! as BoxDecoration).color,
      const Color(0xFFD4AF37),
    );

    await tester.ensureVisible(colorDropdown);
    await tester.pumpAndSettle();
    await tester.tap(colorDropdown);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Silver'),
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Silver'));
    await tester.pump();
    final silverSwatch = tester.widget<Container>(
      find.byKey(const ValueKey('selected_filament_swatch')),
    );
    expect(
      (silverSwatch.decoration! as BoxDecoration).color,
      const Color(0xFFC0C0C0),
    );

    await tester.ensureVisible(colorDropdown);
    await tester.pumpAndSettle();
    await tester.tap(colorDropdown);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Agregar otro color'),
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Agregar otro color'));
    await tester.pump();
    final customColorField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.hintText == 'Ej. Azul marino o #123ABC',
    );
    await tester.ensureVisible(customColorField);
    await tester.enterText(customColorField, 'oro');
    await tester.pump();
    final namedColorPreview = tester.widget<Container>(
      find.byKey(const ValueKey('filament_preview_swatch')),
    );
    expect(
      (namedColorPreview.decoration! as BoxDecoration).color,
      const Color(0xFFD4AF37),
    );
    await tester.enterText(customColorField, '#123ABC');
    await tester.pump();
    final liveColorPreview = tester.widget<Container>(
      find.byKey(const ValueKey('filament_preview_swatch')),
    );
    expect(
      (liveColorPreview.decoration! as BoxDecoration).color,
      const Color(0xFF123ABC),
    );
    await tester.ensureVisible(colorDropdown);
    await tester.pumpAndSettle();
    await tester.tap(colorDropdown);
    await tester.pumpAndSettle();
    expect(find.text('#123ABC'), findsNWidgets(3));
    await tester.tap(find.text('#123ABC').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(
      find.byKey(const ValueKey('selected_filament_swatch')),
      findsOneWidget,
    );

    final urgencyDropdown = find.byType(DropdownButtonFormField<String>).at(2);
    await tester.ensureVisible(urgencyDropdown);
    await tester.pumpAndSettle();
    await tester.tap(urgencyDropdown);
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.text('Rojo').last).style?.color,
      Theme.of(tester.element(urgencyDropdown)).colorScheme.onSurface,
    );
    await tester.tap(find.text('Rojo').last);
    await tester.pump();
    expect(find.text('Tipo de urgencia'), findsOneWidget);
    expect(find.text('Urgencia en texto'), findsOneWidget);
    expect(
      tester
          .widget<DropdownButtonFormField<String>>(urgencyDropdown)
          .decoration
          .fillColor,
      const Color(0xFFDC2626),
    );

    await tester.tap(urgencyDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Amarillo').last);
    await tester.pump();
    expect(
      tester
          .widget<DropdownButtonFormField<String>>(urgencyDropdown)
          .decoration
          .fillColor,
      const Color(0xFFFACC15),
    );
    expect(
      tester
          .widget<Text>(
            find.descendant(
              of: urgencyDropdown,
              matching: find.text('Amarillo'),
            ),
          )
          .style
          ?.color,
      Colors.white,
    );

    await tester.tap(urgencyDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Verde').last);
    await tester.pump();
    expect(
      tester
          .widget<DropdownButtonFormField<String>>(urgencyDropdown)
          .decoration
          .fillColor,
      const Color(0xFF15803D),
    );

    final addAnotherOrder = find.byKey(const ValueKey('add_order_draft_0'));
    await tester.ensureVisible(addAnotherOrder);
    await tester.pumpAndSettle();
    await tester.tap(addAnotherOrder);
    await tester.pumpAndSettle();
    expect(find.text('Pedido 2'), findsOneWidget);
    expect(orderLinks, findsNWidgets(2));
    expect(find.byKey(const ValueKey('order_draft_template')), findsOneWidget);
    expect(find.text('Urgencia en el laboratorio'), findsNWidgets(2));
    expect(find.text('Consumibles'), findsOneWidget);
    expect(find.text('Costo del material'), findsOneWidget);
    expect(find.text('Agregar a la tabla'), findsOneWidget);
    expect(
      tester.widget<TextField>(orderLinks.first).controller!.text,
      'https://example.com/product',
    );

    final removeSecondOrder =
        find.byKey(const ValueKey('remove_order_draft_1'));
    expect(removeSecondOrder, findsOneWidget);
    expect(
      tester.widget<IconButton>(removeSecondOrder).tooltip,
      'Quitar pedido',
    );
    expect(
      tester.widget<IconButton>(removeSecondOrder).icon,
      isA<Icon>().having(
        (icon) => icon.icon,
        'icon',
        Icons.remove_circle_outline_rounded,
      ),
    );
    await tester.ensureVisible(removeSecondOrder);
    await tester.pumpAndSettle();
    await tester.tap(removeSecondOrder);
    await tester.pumpAndSettle();
    expect(find.text('Pedido 2'), findsNothing);
    expect(orderLinks, findsOneWidget);
    expect(find.byKey(const ValueKey('remove_order_draft_1')), findsNothing);

    final closeOrderForm = find.text('Cerrar formulario de pedido');
    await tester.ensureVisible(closeOrderForm);
    await tester.pumpAndSettle();
    await tester.tap(closeOrderForm);
    await tester.pump();
    expect(find.text('Link de la página donde se encontró el material'),
        findsNothing);
  });

  test('Verifica PrintRecord con soporte de cantidad y cálculo total de gramos',
      () {
    final record = PrintRecord(
      id: 1,
      date: DateTime.now().millisecondsSinceEpoch,
      pieceType: 'Soporte Engrane',
      figureCategory: 'Prototipo',
      materials: [
        MaterialData(
          type: 'PLA',
          colorName: 'Negro',
          color: 0xFF111111,
          grams: 30.0,
        ),
      ],
      printerName: 'Bambu Lab A1',
      printerCount: 3,
      hasMaterialCombination: true,
      cantidad: 10,
    );

    expect(record.cantidad, 10);
    expect(record.unitGrams, 30.0);
    expect(record.totalGrams, 300.0);

    // Verificación de serialización toMap y fromMap
    final map = record.toMap();
    expect(map['cantidad'], 10);
    expect(map['printerName'], 'Bambu Lab A1');
    expect(map['printerCount'], 3);
    expect(map['hasMaterialCombination'], isTrue);

    final fromMapRecord = PrintRecord.fromMap(map);
    expect(fromMapRecord.cantidad, 10);
    expect(fromMapRecord.printerName, 'Bambu Lab A1');
    expect(fromMapRecord.printerCount, 3);
    expect(fromMapRecord.hasMaterialCombination, isTrue);
    expect(fromMapRecord.totalGrams, 300.0);

    // Verificación de migración heredada (cantidad ausente o null)
    final legacyMap = Map<String, dynamic>.from(map);
    legacyMap.remove('cantidad');
    legacyMap.remove('printerName');
    legacyMap.remove('printerCount');
    legacyMap.remove('hasMaterialCombination');
    final migratedRecord = PrintRecord.fromMap(legacyMap);
    expect(migratedRecord.cantidad, 1);
    expect(migratedRecord.printerName, isNull);
    expect(migratedRecord.printerCount, 1);
    expect(migratedRecord.hasMaterialCombination, isFalse);
    expect(migratedRecord.totalGrams, 30.0);

    // Verificación de salvaguarda de mínimo 1
    final invalidQuantityRecord = PrintRecord(
      id: 2,
      date: DateTime.now().millisecondsSinceEpoch,
      pieceType: 'Pieza Test',
      figureCategory: 'Miniatura',
      materials: [
        MaterialData(
          type: 'PETG',
          colorName: 'Rojo',
          color: 0xFFE53935,
          grams: 15.0,
        ),
      ],
      cantidad: 0,
    );
    expect(invalidQuantityRecord.cantidad, 1);

    final cappedPrinterRecord = PrintRecord(
      date: DateTime.now().millisecondsSinceEpoch,
      pieceType: 'Pieza Test',
      figureCategory: 'Miniatura',
      materials: const [],
      printerCount: 101,
    );
    expect(cappedPrinterRecord.printerCount, 100);
  });

  test(
      'Verifica PrintRecord con datos de solicitante, número de control/empleado y tiempo de impresión',
      () {
    final record = PrintRecord(
      id: 5,
      date: DateTime.now().millisecondsSinceEpoch,
      pieceType: 'Soporte de Sensor Ultrasónico',
      figureCategory: 'Pieza Funcional',
      materials: [
        MaterialData(
          type: 'PLA',
          colorName: 'Azul',
          color: 0xFF1976D2,
          grams: 45.5,
        ),
      ],
      printerName: 'Bambulab A1 Mini Combo',
      printerCount: 1,
      cantidad: 2,
      requesterType: 'Estudiante',
      requesterName: 'Juan Pérez Morales',
      requesterId: '21120456',
      printTime: '3h 15m',
      notes: 'Pieza para proyecto final de Mecatrónica',
    );

    expect(record.requesterType, 'Estudiante');
    expect(record.requesterName, 'Juan Pérez Morales');
    expect(record.requesterId, '21120456');
    expect(record.printTime, '3h 15m');
    expect(record.totalGrams, 91.0);

    final map = record.toMap();
    expect(map['requesterType'], 'Estudiante');
    expect(map['requesterName'], 'Juan Pérez Morales');
    expect(map['requesterId'], '21120456');
    expect(map['printTime'], '3h 15m');

    final deserialized = PrintRecord.fromMap(map);
    expect(deserialized.requesterType, 'Estudiante');
    expect(deserialized.requesterName, 'Juan Pérez Morales');
    expect(deserialized.requesterId, '21120456');
    expect(deserialized.printTime, '3h 15m');
    expect(deserialized.pieceType, 'Soporte de Sensor Ultrasónico');
  });

  test('Verifica PrintRecord con nombre del proyecto y deserialización', () {
    final record = PrintRecord(
      id: 10,
      date: DateTime.now().millisecondsSinceEpoch,
      pieceType: 'brazo_robotico_v3.stl',
      projectName: 'Proyecto Automatización SILM',
      figureCategory: 'Prototipo',
      materials: [
        MaterialData(
          type: 'PLA',
          colorName: 'Negro',
          color: 0xFF111111,
          grams: 25.0,
        ),
      ],
      printerName: 'Bambu Lab X1-Carbon',
      printerCount: 1,
      cantidad: 1,
      requesterType: 'Docente',
      requesterName: 'Dr. Roberto Mendoza',
      requesterId: 'DOC-5012',
      printTime: '1h 45m',
    );

    expect(record.projectName, 'Proyecto Automatización SILM');
    expect(record.pieceType, 'brazo_robotico_v3.stl');
    expect(record.cantidad, 1);

    final map = record.toMap();
    expect(map['projectName'], 'Proyecto Automatización SILM');
    expect(map['pieceType'], 'brazo_robotico_v3.stl');

    final copy = PrintRecord.fromMap(map);
    expect(copy.projectName, 'Proyecto Automatización SILM');
    expect(copy.pieceType, 'brazo_robotico_v3.stl');
  });
}
