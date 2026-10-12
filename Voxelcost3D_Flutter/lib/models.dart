import 'dart:convert';

class MaterialData {
  String type;
  /// Gramos consumidos POR UNIDAD de pieza individual
  double grams;
  int color;
  String? colorName;
  bool combine;

  MaterialData({
    required this.type,
    required this.grams,
    required this.color,
    this.colorName,
    this.combine = true,
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'grams': grams,
        'color': color,
        'colorName': colorName,
        'combine': combine,
      };

  factory MaterialData.fromJson(Map<String, dynamic> json) => MaterialData(
        type: json['type'] as String,
        grams: (json['grams'] as num).toDouble(),
        color: json['color'] as int,
        colorName: json['colorName'] as String?,
        combine: json['combine'] as bool? ?? true,
      );
}

class PrintRecord {
  int id;
  String pieceType;
  String figureCategory;
  int date;
  List<MaterialData> materials;
  String? notes;
  String? printerName;
  int printerCount;
  bool hasMaterialCombination;

  /// Cantidad de piezas fabricadas en este lote (entero, mínimo 1, por defecto 1)
  int cantidad;

  /// Tipo de solicitante: 'Estudiante', 'Docente', 'Otro'
  String? requesterType;

  /// Nombre completo de quien solicitó la impresión
  String? requesterName;

  /// Identificador: No. de control (estudiante), No. de empleado (docente) u otro ID
  String? requesterId;

  /// Si tipo es 'Otro', detalle o rol personalizado
  String? customRequesterType;

  /// Tiempo total de la impresión (ej. '2h 30m')
  String? printTime;

  /// Nombre del proyecto
  String? projectName;

  PrintRecord({
    this.id = 0,
    required this.pieceType,
    required this.figureCategory,
    required this.date,
    required this.materials,
    this.notes,
    this.printerName,
    this.printerCount = 1,
    this.hasMaterialCombination = false,
    this.cantidad = 1,
    this.requesterType,
    this.requesterName,
    this.requesterId,
    this.customRequesterType,
    this.printTime,
    this.projectName,
  }) {
    if (cantidad < 1) cantidad = 1;
    printerCount = printerCount.clamp(1, 100).toInt();
  }

  /// Consumo total de filamento del lote = suma de (gramos por unidad × cantidad)
  double get totalGrams =>
      materials.fold(0.0, (sum, m) => sum + (m.grams * cantidad));

  /// Consumo de filamento por unidad individual = suma de materiales de una pieza
  double get unitGrams =>
      materials.fold(0.0, (sum, m) => sum + m.grams);

  Map<String, dynamic> toMap() => {
        'id': id == 0 ? null : id,
        'pieceType': pieceType,
        'figureCategory': figureCategory,
        'date': date,
        'materials': jsonEncode(materials.map((item) => item.toJson()).toList()),
        'notes': notes,
        'printerName': printerName,
        'printerCount': printerCount,
        'hasMaterialCombination': hasMaterialCombination,
        'cantidad': cantidad < 1 ? 1 : cantidad,
        'requesterType': requesterType,
        'requesterName': requesterName,
        'requesterId': requesterId,
        'customRequesterType': customRequesterType,
        'printTime': printTime,
        'projectName': projectName,
      };

  factory PrintRecord.fromMap(Map<String, dynamic> map) => PrintRecord(
        id: map['id'] as int,
        pieceType: map['pieceType'] as String,
        figureCategory: map['figureCategory'] as String,
        date: map['date'] as int,
        materials: (jsonDecode(map['materials'] as String) as List)
            .map((item) => MaterialData.fromJson(Map<String, dynamic>.from(item)))
            .toList(),
        notes: map['notes'] as String?,
        printerName: map['printerName'] as String?,
        printerCount: (map['printerCount'] as num?)?.toInt() ?? 1,
        hasMaterialCombination: map['hasMaterialCombination'] as bool? ?? false,
        cantidad: (map['cantidad'] as num?)?.toInt() ?? 1,
        requesterType: map['requesterType'] as String?,
        requesterName: map['requesterName'] as String?,
        requesterId: map['requesterId'] as String?,
        customRequesterType: map['customRequesterType'] as String?,
        printTime: map['printTime'] as String?,
        projectName: map['projectName'] as String?,
      );
}
class InventoryItem {
  String id;
  String material;
  String color;
  String colorHex;
  double stockActual;
  double stockInicial;
  String brand;
  String finish;
  double price;
  double tareWeight;
  double diameter;
  int? tempNozzle;
  int? tempBed;
  String? location;
  String? notes;

  InventoryItem({
    String? id,
    required this.material,
    required this.color,
    this.colorHex = '#888887',
    required this.stockActual,
    required this.stockInicial,
    this.brand = 'Genérica',
    this.finish = 'Estándar',
    this.price = 0.0,
    this.tareWeight = 0.0,
    this.diameter = 1.75,
    this.tempNozzle,
    this.tempBed,
    this.location,
    this.notes,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  double get costPerGram => stockInicial > 0 ? price / stockInicial : 0.0;
  double get currentEstimatedValue => stockActual * costPerGram;
  double get remainingRatio =>
      stockInicial > 0 ? (stockActual / stockInicial).clamp(0.0, 1.0) : 0.0;
  bool get isLowStock => stockInicial <= 0 || remainingRatio <= 0.2;
  bool get isDepleted => stockActual <= 0.001;

  Map<String, dynamic> toMap() => {
        'id': id,
        'material': material,
        'color': color,
        'colorHex': colorHex,
        'stockActual': stockActual,
        'stockInicial': stockInicial,
        'brand': brand,
        'finish': finish,
        'price': price,
        'tareWeight': tareWeight,
        'diameter': diameter,
        'tempNozzle': tempNozzle,
        'tempBed': tempBed,
        'location': location,
        'notes': notes,
      };

  factory InventoryItem.fromMap(Map<String, dynamic> map) => InventoryItem(
        id: map['id'] as String,
        material: map['material'] as String,
        color: map['color'] as String,
        colorHex: (map['colorHex'] as String?) ?? '#888887',
        stockActual: (map['stockActual'] as num).toDouble(),
        stockInicial: (map['stockInicial'] as num).toDouble(),
        brand: (map['brand'] as String?) ?? 'Genérica',
        finish: (map['finish'] as String?) ?? 'Estándar',
        price: (map['price'] as num?)?.toDouble() ?? 0.0,
        tareWeight: (map['tareWeight'] as num?)?.toDouble() ?? 0.0,
        diameter: (map['diameter'] as num?)?.toDouble() ?? 1.75,
        tempNozzle: (map['tempNozzle'] as num?)?.toInt(),
        tempBed: (map['tempBed'] as num?)?.toInt(),
        location: map['location'] as String?,
        notes: map['notes'] as String?,
      );

  InventoryItem copyWith({
    String? id,
    String? material,
    String? color,
    String? colorHex,
    double? stockActual,
    double? stockInicial,
    String? brand,
    String? finish,
    double? price,
    double? tareWeight,
    double? diameter,
    int? tempNozzle,
    int? tempBed,
    String? location,
    String? notes,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      material: material ?? this.material,
      color: color ?? this.color,
      colorHex: colorHex ?? this.colorHex,
      stockActual: stockActual ?? this.stockActual,
      stockInicial: stockInicial ?? this.stockInicial,
      brand: brand ?? this.brand,
      finish: finish ?? this.finish,
      price: price ?? this.price,
      tareWeight: tareWeight ?? this.tareWeight,
      diameter: diameter ?? this.diameter,
      tempNozzle: tempNozzle ?? this.tempNozzle,
      tempBed: tempBed ?? this.tempBed,
      location: location ?? this.location,
      notes: notes ?? this.notes,
    );
  }
}
class MaterialCatalogItem { final String nombre; final bool esPersonalizado; MaterialCatalogItem(this.nombre, [this.esPersonalizado = true]); Map<String, dynamic> toMap() => {'nombre': nombre, 'esPersonalizado': esPersonalizado ? 1 : 0}; }
class ColorCatalogItem { final String nombre, hex; final bool esPersonalizado; ColorCatalogItem(this.nombre, this.hex, [this.esPersonalizado = true]); Map<String, dynamic> toMap() => {'nombre': nombre, 'hex': hex, 'esPersonalizado': esPersonalizado ? 1 : 0}; }
class MonthlyStats { final String monthLabel; final double totalGrams; final int pieceCount; final int sortKey; MonthlyStats(this.monthLabel, this.totalGrams, this.pieceCount, this.sortKey); }