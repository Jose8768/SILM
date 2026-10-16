import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'theme.dart' show SidebarToggleIcon, darkAppBar, voxelColorPalette;

class PedidoMaterialesWidget extends StatefulWidget {
  final bool embedded;
  final VoidCallback? onToggleMenu;
  final VoidCallback? onHoverMenu;
  final bool isPinned;

  const PedidoMaterialesWidget({
    super.key,
    this.embedded = false,
    this.onToggleMenu,
    this.onHoverMenu,
    this.isPinned = false,
  });

  @override
  State<PedidoMaterialesWidget> createState() => PedidoMaterialesWidgetState();
}

class PedidoMaterialesWidgetState extends State<PedidoMaterialesWidget> {
  static const _storageKey = 'pedido_materiales_widget_v1';
  static const _otro = 'Otro (escribir)';
  static const _defaultMaterials = [
    'PLA',
    'PETG',
    'ABS',
    'ASA',
    'TPU (flexible)',
    'Nylon',
    'Resina',
  ];
  static const _defaultColors = [
    'Marrón Van Dyke',
    'Marrón',
    'Ocre amarillo',
    'Azul de Prusia',
    'Oro',
    'Silver',
    'Negro',
    'Blanco',
    'Gris',
    'Rojo',
    'Azul',
    'Verde',
    'Amarillo',
    'Naranja',
    'Transparente',
  ];

  final List<_OrderDraft> _orderDrafts = [_OrderDraft()];

  final List<String> _materials = List<String>.from(_defaultMaterials);
  final List<String> _colors = List<String>.from(_defaultColors);
  final List<String> _consumables = [];
  final List<_MaterialOrder> _orders = [];

  bool _expanded = false;
  bool _loading = true;
  bool _saving = false;
  String? _storageError;

  void prefillOrder({
    required String material,
    required String color,
    double? spoolGrams,
  }) {
    setState(() {
      _expanded = true;
      final draft = _orderDrafts.first;
      _mergeUnique(_materials, [material]);
      draft.selectedMaterial = material;
      _mergeUnique(_colors, [color]);
      draft.selectedColor = color;
      if (spoolGrams != null && spoolGrams > 0) {
        draft.spoolWeightController.text = '${spoolGrams.toInt()} g';
      }
      draft.selectedUrgency = 'Rojo';
      draft.urgencyTypeController.text = 'Reposición de inventario';
      draft.urgencyDetailsController.text =
          'Bobina agotada o con stock bajo en laboratorio';
    });
    _showMessage(
      'Se cargó $material ($color) en el formulario de pedido.',
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSavedData());
  }

  @override
  void dispose() {
    for (final draft in _orderDrafts) {
      draft.dispose();
    }
    super.dispose();
  }

  Future<void> _loadSavedData() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final saved = preferences.getString(_storageKey);
      if (saved != null) {
        final decoded = jsonDecode(saved);
        if (decoded is! Map<String, dynamic>) {
          throw const FormatException('El contenido guardado no es válido.');
        }

        final loadedMaterials = _readStringList(decoded['materials']);
        final loadedColors = _readStringList(decoded['colors']);
        final loadedConsumables = _readStringList(decoded['consumables']);
        final loadedOrders = _readOrders(decoded['orders']);

        if (!mounted) return;
        setState(() {
          _mergeUnique(_materials, loadedMaterials);
          _mergeUnique(_colors, loadedColors);
          _mergeUnique(_consumables, loadedConsumables);
          _orders
            ..clear()
            ..addAll(loadedOrders);
        });
      }
    } catch (error, stackTrace) {
      debugPrint('Error al cargar los pedidos de materiales: $error');
      debugPrintStack(stackTrace: stackTrace);
      _showMessage(
        'No se pudieron cargar los pedidos guardados. $error',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveData() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final preferences = await SharedPreferences.getInstance();
      final saved = await preferences.setString(
        _storageKey,
        jsonEncode({
          'materials': _materials,
          'colors': _colors,
          'consumables': _consumables,
          'orders': _orders.map((order) => order.toJson()).toList(),
        }),
      );
      if (!saved) {
        throw StateError('El almacenamiento rechazó los cambios.');
      }
      _storageError = null;
    } catch (error, stackTrace) {
      debugPrint('Error al guardar los pedidos de materiales: $error');
      debugPrintStack(stackTrace: stackTrace);
      _storageError =
          'No se pudieron guardar los cambios. Permanecerán solo mientras la app esté abierta.';
      _showMessage('Error al guardar los pedidos: $error', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  List<String> _readStringList(Object? value) {
    if (value == null) return [];
    if (value is! List) {
      throw const FormatException('Una de las listas guardadas no es válida.');
    }
    return value.map((item) {
      if (item is! String) {
        throw const FormatException('Se encontró un elemento no válido.');
      }
      return item;
    }).toList();
  }

  List<_MaterialOrder> _readOrders(Object? value) {
    if (value == null) return [];
    if (value is! List) {
      throw const FormatException('La lista de pedidos guardada no es válida.');
    }
    return value.map((item) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('Se encontró un pedido no válido.');
      }
      return _MaterialOrder.fromJson(item);
    }).toList();
  }

  void _mergeUnique(List<String> target, Iterable<String> values) {
    for (final value in values) {
      final normalized = value.trim();
      if (normalized.isNotEmpty &&
          !target.any(
            (existing) => existing.toLowerCase() == normalized.toLowerCase(),
          )) {
        target.add(normalized);
      }
    }
  }

  String? _resolveManualValue({
    required String? selection,
    required TextEditingController controller,
    required String fieldName,
  }) {
    if (selection == _otro) {
      final value = controller.text.trim();
      if (value.isEmpty) {
        _showMessage('Escribe el nombre de $fieldName.', isError: true);
        return null;
      }
      return value;
    }
    return selection;
  }

  String? _normalizedPageLink(String value) {
    final entered = value.trim();
    if (entered.isEmpty) return null;
    final candidate = entered.contains('://') ? entered : 'https://$entered';
    final uri = Uri.tryParse(candidate);
    if (uri == null ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      return null;
    }
    return uri.toString();
  }

  Future<void> _addOrder() async {
    final sharedDraft = _orderDrafts.first;
    if (sharedDraft.selectedUrgency == null) {
      _showMessage('Selecciona el nivel de urgencia.', isError: true);
      return;
    }
    final urgencyType = sharedDraft.urgencyTypeController.text.trim();
    if (urgencyType.isEmpty) {
      _showMessage('Escribe el tipo de urgencia.', isError: true);
      return;
    }
    final urgencyDetails = sharedDraft.urgencyDetailsController.text.trim();
    if (urgencyDetails.isEmpty) {
      _showMessage('Escribe la urgencia en texto.', isError: true);
      return;
    }

    final consumables = <String>[];
    final newConsumables = <String>[];
    for (final form in sharedDraft.consumableForms) {
      if (form.selected == null) continue;
      final consumable = _resolveManualValue(
        selection: form.selected,
        controller: form.manualController,
        fieldName: 'consumible',
      );
      if (consumable == null) return;
      consumables.add(consumable);
      if (form.selected == _otro) newConsumables.add(consumable);
    }

    final costText =
        sharedDraft.costController.text.trim().replaceAll(',', '.');
    final cost = costText.isEmpty ? 0.0 : double.tryParse(costText);
    if (cost == null || cost < 0) {
      _showMessage('Escribe un costo válido en pesos.', isError: true);
      return;
    }

    final orders = <_MaterialOrder>[];
    final newMaterials = <String>[];
    final newColors = <String>[];
    final now = DateTime.now().microsecondsSinceEpoch;
    for (var index = 0; index < _orderDrafts.length; index++) {
      final draft = _orderDrafts[index];
      final link = _normalizedPageLink(draft.linkController.text);
      if (link == null) {
        _showMessage(
          'Escribe un enlace válido para el pedido ${index + 1}.',
          isError: true,
        );
        return;
      }

      final material = _resolveManualValue(
        selection: draft.selectedMaterial,
        controller: draft.manualMaterialController,
        fieldName: 'material',
      );
      if (material == null) {
        if (draft.selectedMaterial != _otro) {
          _showMessage(
            'Selecciona el material del pedido ${index + 1}.',
            isError: true,
          );
        }
        return;
      }

      final color = _resolveManualValue(
        selection: draft.selectedColor,
        controller: draft.manualColorController,
        fieldName: 'color',
      );
      if (color == null) {
        if (draft.selectedColor != _otro) {
          _showMessage(
            'Selecciona el color del pedido ${index + 1}.',
            isError: true,
          );
        }
        return;
      }

      final spoolText = draft.spoolWeightController.text.trim();
      final spoolGrams = parseWeightToGrams(spoolText);
      if (spoolText.isNotEmpty && spoolGrams == null) {
        _showMessage(
          'No entendí el peso del carrete del pedido ${index + 1}.',
          isError: true,
        );
        return;
      }

      if (draft.selectedMaterial == _otro) newMaterials.add(material);
      if (draft.selectedColor == _otro) newColors.add(color);
      orders.add(
        _MaterialOrder(
          id: '${now}_$index',
          link: link,
          material: material,
          color: color,
          urgency: sharedDraft.selectedUrgency!,
          urgencyType: urgencyType,
          urgencyDetails: urgencyDetails,
          consumables: consumables,
          spoolGrams: spoolGrams,
          usedGrams: null,
          cost: cost,
        ),
      );
    }

    setState(() {
      _mergeUnique(_materials, newMaterials);
      _mergeUnique(_colors, newColors);
      _mergeUnique(_consumables, newConsumables);
      _orders.insertAll(0, orders);
      for (final draft in _orderDrafts) {
        draft.dispose();
      }
      _orderDrafts
        ..clear()
        ..add(_OrderDraft());
    });
    await _saveData();
  }

  void _removeOrderDraft(_OrderDraft draft) {
    if (_orderDrafts.indexOf(draft) <= 0) return;
    setState(() => _orderDrafts.remove(draft));
    draft.dispose();
  }

  Future<void> _removeOrder(_MaterialOrder order) async {
    setState(() => _orders.removeWhere((item) => item.id == order.id));
    await _saveData();
  }

  Future<void> _addCustomColorToPalette(_OrderDraft draft) async {
    final color = draft.manualColorController.text.trim();
    if (color.isEmpty) {
      _showMessage('Escribe el nombre o el código del color.', isError: true);
      return;
    }

    setState(() {
      _mergeUnique(_colors, [color]);
      draft.selectedColor = _colors.firstWhere(
        (existing) => existing.toLowerCase() == color.toLowerCase(),
      );
      draft.manualColorController.clear();
    });
    await _saveData();
  }

  Future<void> _selectFilamentColor(_OrderDraft draft, String? value) async {
    if (value == null) return;
    final colorDraft = draft.manualColorController.text.trim();
    final isNewDraft = colorDraft.isNotEmpty &&
        value.toLowerCase() == colorDraft.toLowerCase() &&
        !_colors
            .any((color) => color.toLowerCase() == colorDraft.toLowerCase());
    setState(() {
      if (isNewDraft) _mergeUnique(_colors, [value]);
      draft.selectedColor = value;
      draft.manualColorController.clear();
    });
    if (isNewDraft) await _saveData();
  }

  Future<void> _openLink(_MaterialOrder order) => _openPageLink(order.link);

  Future<void> _openPageLink(String value) async {
    final link = _normalizedPageLink(value);
    if (link == null) {
      _showMessage(
        'Escribe un enlace válido (por ejemplo, https://tienda.com).',
        isError: true,
      );
      return;
    }
    try {
      final uri = Uri.parse(link);
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) {
        throw StateError('El navegador no pudo abrir $link.');
      }
    } catch (error, stackTrace) {
      debugPrint('Error al abrir el enlace del material: $error');
      debugPrintStack(stackTrace: stackTrace);
      _showMessage('No se pudo abrir el enlace: $error', isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError
              ? Theme.of(context).colorScheme.error
              : Theme.of(context).colorScheme.primary,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return LayoutBuilder(
      builder: (context, constraints) {
        final pagePadding = constraints.maxWidth < 600 ? 14.0 : 24.0;
        final pageWidth = constraints.maxWidth;
        if (widget.embedded) {
          return _buildEmbeddedContent(context, pageWidth);
        }
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: darkAppBar(
            'Pedido de Material',
            widget.onToggleMenu ?? () {},
            leadingWidget: const SidebarToggleIcon(),
            onHoverEnter: widget.onHoverMenu,
            hideLeading: widget.isPinned,
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(pagePadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(theme, isDark),
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    height: 38,
                    child: ElevatedButton.icon(
                      onPressed: () => setState(() => _expanded = !_expanded),
                      icon: Icon(
                        _expanded ? Icons.close_rounded : Icons.add_rounded,
                        size: 18,
                      ),
                      label: Text(
                        _expanded ? 'Ocultar pedidos' : 'Nuevo pedido',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: colors.onPrimary,
                        elevation: 2,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
                if (_expanded) ...[
                  const SizedBox(height: 16),
                  if (_loading)
                    const LinearProgressIndicator(minHeight: 3)
                  else ...[
                    _buildForm(context, pageWidth),
                    const SizedBox(height: 20),
                    _buildOrdersTable(context),
                  ],
                ],
                if (_storageError != null) ...[
                  const SizedBox(height: 12),
                  _buildStorageWarning(context),
                ],
                if (_saving) ...[
                  const SizedBox(height: 10),
                  const LinearProgressIndicator(minHeight: 2),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmbeddedContent(
    BuildContext context,
    double maxWidth,
  ) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!_expanded)
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              height: 40,
              child: ElevatedButton.icon(
                onPressed: () => setState(() => _expanded = true),
                icon: const Icon(
                  Icons.add_rounded,
                  size: 18,
                ),
                label: const Text(
                  'Nuevo pedido',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  elevation: 1,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          )
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Nuevo pedido',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              OutlinedButton.icon(
                onPressed: () => setState(() => _expanded = false),
                icon: const Icon(
                  Icons.close_rounded,
                  size: 16,
                ),
                label: const Text(
                  'Cerrar formulario de pedido',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
              ),
            ],
          ),
        if (_expanded) ...[
          const SizedBox(height: 14),
          _buildForm(context, maxWidth),
          const SizedBox(height: 14),
          _buildOrdersTable(context),
        ],
        if (_storageError != null) ...[
          const SizedBox(height: 10),
          _buildStorageWarning(context),
        ],
        if (_saving) ...[
          const SizedBox(height: 8),
          const LinearProgressIndicator(minHeight: 2),
        ],
      ],
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.primary,
            Color.lerp(colors.primary, colors.secondary, 0.65)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: isDark ? 0.22 : 0.16),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.shopping_cart_checkout_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pedido de materiales',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Organiza las compras y prioridades del laboratorio',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context, double maxWidth) {
    final theme = Theme.of(context);
    return Container(
      key: const ValueKey('order_draft_template'),
      padding: EdgeInsets.all(maxWidth < 600 ? 16 : 22),
      decoration: _cardDecoration(theme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < _orderDrafts.length; index++) ...[
            if (index > 0) const SizedBox(height: 14),
            _buildOrderDraftForm(
              context,
              maxWidth,
              _orderDrafts[index],
              index,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderDraftForm(
    BuildContext context,
    double maxWidth,
    _OrderDraft draft,
    int draftIndex,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final sharedDraft = _orderDrafts.first;
    final pageInset =
        widget.embedded ? 0.0 : (maxWidth < 600 ? 14.0 : 24.0) * 2;
    final cardInset = (maxWidth < 600 ? 16.0 : 22.0) * 2;
    final availableWidth = maxWidth - pageInset - cardInset;
    final columns = availableWidth >= 1000
        ? 3
        : availableWidth >= 620
            ? 2
            : 1;
    final fieldWidth = (availableWidth - (12 * (columns - 1))) / columns;
    final detailFieldWidth =
        (availableWidth - 28 - (12 * (columns - 1))) / columns;
    Widget field(Widget child, {double? width}) =>
        SizedBox(width: width ?? fieldWidth, child: child);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Pedido ${draftIndex + 1}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (draftIndex > 0)
              IconButton(
                key: ValueKey('remove_order_draft_$draftIndex'),
                tooltip: 'Quitar pedido',
                onPressed: () => _removeOrderDraft(draft),
                icon: const Icon(Icons.remove_circle_outline_rounded),
                color: theme.colorScheme.error,
              ),
          ],
        ),
        const SizedBox(height: 16),
        _textInput(
          context,
          key: ValueKey('order_link_${draft.id}'),
          controller: draft.linkController,
          label: 'Link de la página donde se encontró el material',
          hint: 'https://...',
          keyboardType: TextInputType.url,
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Pegar enlace',
                onPressed: () async {
                  final data = await Clipboard.getData(Clipboard.kTextPlain);
                  if (data?.text != null && data!.text!.trim().isNotEmpty) {
                    draft.linkController.text = data.text!.trim();
                    setState(() {});
                  }
                },
                icon: const Icon(Icons.content_paste_rounded, size: 20),
              ),
              IconButton(
                tooltip: 'Abrir página web',
                onPressed: () => _openPageLink(draft.linkController.text),
                icon: const Icon(Icons.open_in_browser_rounded, size: 20),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _formSectionTitle(context, 'Material y color'),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            field(_dropdown(
              context,
              key: ValueKey('order_material_$draftIndex'),
              label: 'Material',
              value: draft.selectedMaterial,
              options: [..._materials, _otro],
              hint: 'Elegir material',
              onChanged: (value) =>
                  setState(() => draft.selectedMaterial = value),
            )),
            field(_filamentColorDropdown(context, draft)),
            field(_weightInput(
              context,
              controller: draft.spoolWeightController,
              label: 'Peso del carrete',
              hint: '1kg, un kilo y medio, 500 g',
            )),
          ],
        ),
        if (draft.selectedMaterial == _otro ||
            draft.selectedColor == _otro) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              if (draft.selectedMaterial == _otro)
                field(_textInput(
                  context,
                  controller: draft.manualMaterialController,
                  label: 'Escribe el material',
                  hint: 'Ej. PLA con fibra de carbono',
                )),
              if (draft.selectedColor == _otro)
                field(_manualColorInput(context, draft)),
            ],
          ),
        ],
        if (draftIndex == _orderDrafts.length - 1)
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              key: ValueKey('add_order_draft_$draftIndex'),
              onPressed: () => setState(() => _orderDrafts.add(_OrderDraft())),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Agregar otro pedido'),
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        if (draftIndex == _orderDrafts.length - 1) ...[
          const SizedBox(height: 24),
          Divider(
            height: 1,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 20),
          _formSectionTitle(context, 'Urgencia en el laboratorio'),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [field(_urgencyDropdown(context, sharedDraft))],
          ),
          if (sharedDraft.selectedUrgency != null) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                field(
                  _textInput(
                    context,
                    controller: sharedDraft.urgencyTypeController,
                    label: 'Tipo de urgencia',
                    hint: 'Ej. Reposición urgente',
                  ),
                  width: detailFieldWidth,
                ),
                field(
                  _textInput(
                    context,
                    controller: sharedDraft.urgencyDetailsController,
                    label: 'Urgencia en texto',
                    hint: 'Ej. Falta para la entrega de mañana',
                  ),
                  width: detailFieldWidth,
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          Divider(
            height: 1,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 20),
          _formSectionTitle(context, 'Consumibles'),
          ...sharedDraft.consumableForms.asMap().entries.map((entry) {
            final index = entry.key;
            final form = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Wrap(
                key: ValueKey('consumable_row_${sharedDraft.id}_$index'),
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  field(_dropdown(
                    context,
                    key: ValueKey(
                      'consumable_dropdown_${sharedDraft.id}_$index',
                    ),
                    label: 'Consumible ${index + 1}',
                    value: form.selected,
                    options: [..._consumables, _otro],
                    hint: 'Elegir consumible',
                    onChanged: (value) => setState(() => form.selected = value),
                  )),
                  if (form.selected == _otro)
                    field(_textInput(
                      context,
                      controller: form.manualController,
                      label: 'Escribe el consumible',
                      hint: 'Ej. Boquilla de 0.4 mm',
                    )),
                  if (index > 0)
                    IconButton(
                      key: ValueKey(
                        'remove_consumable_${sharedDraft.id}_$index',
                      ),
                      tooltip: 'Quitar consumible',
                      onPressed: () => setState(() {
                        sharedDraft.consumableForms.removeAt(index).dispose();
                      }),
                      icon: const Icon(Icons.remove_circle_outline_rounded),
                      color: theme.colorScheme.error,
                    ),
                ],
              ),
            );
          }),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              TextButton.icon(
                key: ValueKey('add_consumable_${sharedDraft.id}'),
                onPressed: () => setState(
                  () => sharedDraft.consumableForms.add(_ConsumableForm()),
                ),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Agregar otro consumible'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Divider(
            height: 1,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 20),
          _formSectionTitle(context, 'Costo del material'),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              field(_textInput(
                context,
                controller: sharedDraft.costController,
                label: 'Costo (\$)',
                hint: '0',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              )),
              SizedBox(
                height: 48,
                child: FilledButton.icon(
                  key: const ValueKey('submit_order_0'),
                  onPressed: _loading || _saving ? null : _addOrder,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text(
                    'Agregar a la tabla',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onPrimary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _formSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _textInput(
    BuildContext context, {
    Key? key,
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
    Widget? suffixIcon,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          key: key,
          controller: controller,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: theme.textTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: suffixIcon,
            isDense: true,
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.48 : 0.55,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: BorderSide(
                color: theme.colorScheme.outlineVariant,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: BorderSide(
                color: theme.colorScheme.outlineVariant,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 1.6,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _weightInput(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    final theme = Theme.of(context);
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final grams = parseWeightToGrams(value.text);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _textInput(
              context,
              controller: controller,
              label: label,
              hint: hint,
              keyboardType: TextInputType.text,
            ),
            if (value.text.trim().isNotEmpty && grams != null) ...[
              const SizedBox(height: 4),
              Text(
                '= ${_formatWeight(grams)}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _dropdown(
    BuildContext context, {
    Key? key,
    required String label,
    required String? value,
    required List<String> options,
    required String hint,
    required ValueChanged<String?> onChanged,
  }) {
    final theme = Theme.of(context);
    final safeValue = value != null && options.contains(value) ? value : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          key: key ?? ValueKey('material_$safeValue'),
          initialValue: safeValue,
          isExpanded: true,
          hint: Text(hint, overflow: TextOverflow.ellipsis),
          items: options
              .map(
                (option) => DropdownMenuItem<String>(
                  value: option,
                  child: Text(option, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.48 : 0.55,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
            ),
          ),
        ),
      ],
    );
  }

  Widget _filamentColorDropdown(BuildContext context, _OrderDraft draft) {
    final theme = Theme.of(context);
    final colorDraft = draft.manualColorController.text.trim();
    final options = [..._colors];
    if (colorDraft.isNotEmpty &&
        !_colors.any(
          (color) => color.toLowerCase() == colorDraft.toLowerCase(),
        )) {
      options.add(colorDraft);
    }
    options.add(_otro);
    final safeValue =
        draft.selectedColor != null && options.contains(draft.selectedColor)
            ? draft.selectedColor
            : null;
    Widget colorRow(String option, {bool selected = false}) => Row(
          children: [
            _filamentSwatch(
              option,
              key: ValueKey(
                selected
                    ? 'selected_filament_swatch'
                    : 'filament_palette_swatch_${option.toLowerCase()}',
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(option, overflow: TextOverflow.ellipsis),
            ),
          ],
        );
    Widget addColorRow() => const Row(
          children: [
            Icon(Icons.add_circle_outline_rounded, size: 18),
            SizedBox(width: 9),
            Expanded(
              child: Text(
                'Agregar otro color',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
    final selectedItems = options.map((option) {
      if (option == _otro) {
        return addColorRow();
      }
      return colorRow(option, selected: true);
    }).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Color del filamento',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          key: ValueKey('filament_color_${draft.id}_$safeValue'),
          initialValue: safeValue,
          isExpanded: true,
          menuMaxHeight: 360,
          hint: const Text('Elegir color'),
          items: options.map((option) {
            if (option == _otro) {
              return const DropdownMenuItem<String>(
                value: _otro,
                child: Row(
                  children: [
                    Icon(Icons.add_circle_outline_rounded, size: 18),
                    SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        'Agregar otro color',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }
            return DropdownMenuItem<String>(
              value: option,
              child: colorRow(option),
            );
          }).toList(),
          selectedItemBuilder: (context) => selectedItems,
          onChanged: (value) => _selectFilamentColor(draft, value),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.48 : 0.55,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
            ),
          ),
        ),
      ],
    );
  }

  Widget _filamentSwatch(
    String name, {
    double size = 20,
    required Key key,
  }) {
    final color = _filamentColor(name);
    return Container(
      key: key,
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(
          color: color.computeLuminance() > 0.88
              ? const Color(0xFF9E9E9E)
              : Colors.black.withValues(alpha: 0.12),
        ),
      ),
    );
  }

  Widget _manualColorInput(BuildContext context, _OrderDraft draft) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _textInput(
          context,
          controller: draft.manualColorController,
          label: 'Escribe un color nuevo',
          hint: 'Ej. Azul marino o #123ABC',
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            _filamentSwatch(
              draft.manualColorController.text,
              key: const ValueKey('filament_preview_swatch'),
              size: 22,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                draft.manualColorController.text.trim().isEmpty
                    ? 'Vista previa del color'
                    : draft.manualColorController.text.trim(),
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: _saving ? null : () => _addCustomColorToPalette(draft),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Añadir a la paleta'),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _urgencyDropdown(BuildContext context, _OrderDraft draft) {
    final theme = Theme.of(context);
    final selectedColor = draft.selectedUrgency == null
        ? null
        : _urgencyColor(context, draft.selectedUrgency!);
    final selectedForeground = draft.selectedUrgency == null
        ? theme.colorScheme.onSurface
        : Colors.white;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Urgencia en el laboratorio',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          key: ValueKey('urgency_${draft.id}_${draft.selectedUrgency}'),
          initialValue: draft.selectedUrgency,
          isExpanded: true,
          hint: const Text('Elegir urgencia'),
          items: ['Rojo', 'Amarillo', 'Verde']
              .map(
                (level) => DropdownMenuItem<String>(
                  value: level,
                  child: Row(
                    children: [
                      Icon(
                        Icons.circle,
                        size: 13,
                        color: _urgencyColor(context, level),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        level,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        level == 'Rojo'
                            ? '· Alta / Crítica'
                            : level == 'Amarillo'
                                ? '· Media'
                                : '· Baja',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
          selectedItemBuilder: (context) => ['Rojo', 'Amarillo', 'Verde']
              .map(
                (level) => Row(
                  children: [
                    const Icon(
                      Icons.circle,
                      size: 11,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      level,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
              .toList(),
          onChanged: (value) => setState(() => draft.selectedUrgency = value),
          decoration: InputDecoration(
            filled: true,
            fillColor: selectedColor ??
                theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: theme.brightness == Brightness.dark ? 0.48 : 0.55,
                ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: BorderSide(
                color: theme.colorScheme.outlineVariant,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: BorderSide(
                color: theme.colorScheme.outlineVariant,
              ),
            ),
          ),
          dropdownColor: theme.colorScheme.surface,
          iconEnabledColor: selectedForeground,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: selectedForeground,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildOrdersTable(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: _cardDecoration(theme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
            child: Text(
              'Tabla de pedidos',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (_orders.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 22),
              child: Text(
                'Aún no hay pedidos',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: constraints.maxWidth,
                    ),
                    child: DataTable(
                      columnSpacing: 22,
                      headingRowColor: WidgetStatePropertyAll(
                        theme.colorScheme.surfaceContainerHighest,
                      ),
                      columns: const [
                        DataColumn(label: Text('Página')),
                        DataColumn(label: Text('Material')),
                        DataColumn(label: Text('Color')),
                        DataColumn(label: Text('Urgencia')),
                        DataColumn(label: Text('Consumible')),
                        DataColumn(label: Text('Peso restante')),
                        DataColumn(label: Text('Costo')),
                        DataColumn(label: Text('')),
                      ],
                      rows: _orders.map((order) {
                        return DataRow(
                          cells: [
                            DataCell(
                              Tooltip(
                                message: order.link,
                                child: TextButton.icon(
                                  onPressed: () => _openLink(order),
                                  icon: const Icon(
                                    Icons.open_in_new_rounded,
                                    size: 15,
                                  ),
                                  label: Text(
                                    _siteName(order.link),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              Chip(
                                label: Text(order.material),
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 15,
                                    height: 15,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _filamentColor(order.color),
                                      border: Border.all(
                                        color: theme.colorScheme.outlineVariant,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(order.color),
                                ],
                              ),
                            ),
                            DataCell(_urgencyChip(context, order)),
                            DataCell(Text(
                              order.consumables.isEmpty
                                  ? '—'
                                  : order.consumables.join(', '),
                            )),
                            DataCell(_remainingCell(context, order)),
                            DataCell(
                                Text('\$${order.cost.toStringAsFixed(2)}')),
                            DataCell(
                              IconButton(
                                tooltip: 'Quitar pedido',
                                onPressed:
                                    _saving ? null : () => _removeOrder(order),
                                icon: const Icon(Icons.delete_outline_rounded),
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _urgencyChip(BuildContext context, _MaterialOrder order) {
    final color = _urgencyColor(context, order.urgency);
    return Tooltip(
      message: order.urgencyDetails,
      child: Chip(
        avatar: Icon(Icons.circle, size: 12, color: color),
        label: Text(
          '${order.urgencyType}: ${order.urgencyDetails}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        side: BorderSide(color: color.withValues(alpha: 0.4)),
        backgroundColor: color.withValues(alpha: 0.12),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _remainingCell(BuildContext context, _MaterialOrder order) {
    final theme = Theme.of(context);
    final total = order.spoolGrams;
    final remaining = order.remainingGrams;
    if (total == null || remaining == null) {
      return const SizedBox(
        width: 145,
        child: Text('Peso no disponible'),
      );
    }
    final ratio =
        total <= 0 ? 0.0 : (remaining / total).clamp(0.0, 1.0).toDouble();
    return SizedBox(
      width: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatWeight(remaining),
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          LinearProgressIndicator(
            value: ratio,
            minHeight: 6,
            borderRadius: BorderRadius.circular(8),
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
          ),
        ],
      ),
    );
  }

  Widget _buildStorageWarning(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _storageError!,
        style: TextStyle(color: theme.colorScheme.onErrorContainer),
      ),
    );
  }

  BoxDecoration _cardDecoration(ThemeData theme) => BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.16 : 0.06,
            ),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      );

  Color _urgencyColor(BuildContext context, String urgency) {
    switch (urgency) {
      case 'Rojo':
        return const Color(0xFFDC2626);
      case 'Amarillo':
        return const Color(0xFFFACC15);
      case 'Verde':
        return const Color(0xFF15803D);
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  Color _filamentColor(String name) {
    final normalized = name.trim().toLowerCase();
    final hex = normalized.startsWith('#') ? normalized.substring(1) : '';
    if (hex.length == 6 || hex.length == 8) {
      final parsed = int.tryParse(hex, radix: 16);
      if (parsed != null) {
        return Color(hex.length == 6 ? 0xFF000000 | parsed : parsed);
      }
    }
    for (final paletteColor in voxelColorPalette) {
      if (paletteColor.name.toLowerCase() == normalized) {
        return paletteColor.color;
      }
    }
    switch (normalized) {
      case 'negro':
      case 'black':
        return const Color(0xFF111111);
      case 'blanco':
      case 'white':
        return const Color(0xFFFFFFFF);
      case 'gris':
      case 'gray':
      case 'grey':
        return const Color(0xFF808080);
      case 'rojo':
      case 'red':
        return const Color(0xFFE53935);
      case 'azul':
        return const Color(0xFF1E88E5);
      case 'azul de prusia':
      case 'prussian blue':
        return const Color(0xFF003153);
      case 'azul marino':
      case 'navy':
        return const Color(0xFF001F3F);
      case 'azul cielo':
      case 'sky blue':
        return const Color(0xFF4FC3F7);
      case 'verde':
      case 'green':
        return const Color(0xFF43A047);
      case 'verde lima':
      case 'lime green':
        return const Color(0xFF8BC34A);
      case 'amarillo':
        return const Color(0xFFFDD835);
      case 'ocre amarillo':
      case 'yellow ochre':
        return const Color(0xFFCC7722);
      case 'naranja':
      case 'orange':
        return const Color(0xFFFB8C00);
      case 'rosa':
      case 'pink':
        return const Color(0xFFE91E63);
      case 'morado':
      case 'púrpura':
      case 'purple':
        return const Color(0xFF7E57C2);
      case 'turquesa':
      case 'turquoise':
        return const Color(0xFF26A69A);
      case 'beige':
        return const Color(0xFFD7CCC8);
      case 'café':
      case 'cafe':
        return const Color(0xFF795548);
      case 'transparente':
        return Colors.transparent;
      case 'marrón van dyke':
      case 'vandyke brown':
        return const Color(0xFF8B3F2F);
      case 'marrón':
      case 'brown':
        return const Color(0xFFA94F3D);
      case 'oro':
      case 'dorado':
      case 'gold':
      case 'golden':
        return voxelColorPalette
            .firstWhere((color) => color.name == 'Oro')
            .color;
      case 'silver':
      case 'plata':
      case 'plateado':
        return voxelColorPalette
            .firstWhere((color) => color.name == 'Silver')
            .color;
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  String _siteName(String link) {
    final uri = Uri.tryParse(link);
    return uri?.host.isNotEmpty == true ? uri!.host : link;
  }

  String _formatWeight(double grams) {
    final normalized = grams.roundToDouble();
    final formattedGrams = normalized == grams
        ? normalized.toStringAsFixed(0)
        : grams.toStringAsFixed(1);
    if (grams >= 1000) {
      final kilograms = grams / 1000;
      final formattedKilograms = kilograms == kilograms.roundToDouble()
          ? kilograms.toStringAsFixed(0)
          : kilograms.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
      return '$formattedKilograms kg ($formattedGrams g)';
    }
    return '$formattedGrams g';
  }
}

class _MaterialOrder {
  const _MaterialOrder({
    required this.id,
    required this.link,
    required this.material,
    required this.color,
    required this.urgency,
    required this.urgencyType,
    required this.urgencyDetails,
    required this.consumables,
    required this.spoolGrams,
    required this.usedGrams,
    required this.cost,
  });

  final String id;
  final String link;
  final String material;
  final String color;
  final String urgency;
  final String urgencyType;
  final String urgencyDetails;
  final List<String> consumables;
  final double? spoolGrams;
  final double? usedGrams;
  final double cost;

  double? get remainingGrams {
    if (spoolGrams == null) return null;
    return (spoolGrams! - (usedGrams ?? 0)).clamp(0, spoolGrams!).toDouble();
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'link': link,
        'material': material,
        'color': color,
        'urgency': urgency,
        'urgencyType': urgencyType,
        'urgencyDetails': urgencyDetails,
        'consumables': consumables,
        'spoolGrams': spoolGrams,
        'usedGrams': usedGrams,
        'cost': cost,
      };

  factory _MaterialOrder.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final link = json['link'];
    final material = json['material'];
    final color = json['color'];
    final urgency = json['urgency'];
    final urgencyType = json['urgencyType'] ?? urgency;
    final urgencyDetails = json['urgencyDetails'];
    final savedConsumables = json['consumables'];
    final legacyConsumable = json['consumable'];
    final cost = json['cost'];
    if (id is! String ||
        link is! String ||
        material is! String ||
        color is! String ||
        urgency is! String ||
        urgencyType is! String ||
        urgencyDetails is! String ||
        (savedConsumables != null &&
            (savedConsumables is! List ||
                savedConsumables.any((item) => item is! String))) ||
        (legacyConsumable != null && legacyConsumable is! String) ||
        (cost is! num)) {
      throw const FormatException('Los datos de un pedido no son válidos.');
    }
    return _MaterialOrder(
      id: id,
      link: link,
      material: material,
      color: color,
      urgency: urgency,
      urgencyType: urgencyType,
      urgencyDetails: urgencyDetails,
      consumables: savedConsumables is List
          ? savedConsumables.cast<String>()
          : legacyConsumable is String
              ? [legacyConsumable]
              : const [],
      spoolGrams: _readNullableNumber(json['spoolGrams']),
      usedGrams: _readNullableNumber(json['usedGrams']),
      cost: cost.toDouble(),
    );
  }
}

class _OrderDraft {
  static int _nextId = 0;

  _OrderDraft() : id = _nextId++;

  final int id;
  final linkController = TextEditingController();
  final manualMaterialController = TextEditingController();
  final manualColorController = TextEditingController();
  final urgencyTypeController = TextEditingController();
  final urgencyDetailsController = TextEditingController();
  final spoolWeightController = TextEditingController();
  final costController = TextEditingController(text: '0');
  final List<_ConsumableForm> consumableForms = [_ConsumableForm()];

  String? selectedMaterial;
  String? selectedColor;
  String? selectedUrgency;

  void dispose() {
    linkController.dispose();
    manualMaterialController.dispose();
    manualColorController.dispose();
    urgencyTypeController.dispose();
    urgencyDetailsController.dispose();
    spoolWeightController.dispose();
    costController.dispose();
    for (final consumable in consumableForms) {
      consumable.dispose();
    }
  }
}

class _ConsumableForm {
  String? selected;
  final TextEditingController manualController = TextEditingController();

  void dispose() => manualController.dispose();
}

double? _readNullableNumber(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  throw const FormatException('El peso guardado no es válido.');
}

/// Convierte un peso en español a gramos.
///
/// Admite unidades explícitas, números solos (menos de 50 = kg) y cantidades
/// escritas con palabras, como "un kilo y medio" o "quinientos gramos".
double? parseWeightToGrams(String input) {
  var text = _normalizeSpanish(input);
  if (text.isEmpty) return null;

  final hasKilograms = RegExp(
    r'(?<![a-z])(kg|kilo|kilos|kilogramo|kilogramos)\b',
  ).hasMatch(text);
  final hasGrams = RegExp(
    r'(?<![a-z])(g|gr|gramo|gramos)\b',
  ).hasMatch(text);
  if (hasKilograms && hasGrams) return null;

  text = text
      .replaceAll(
        RegExp(r'(?<![a-z])(kilogramos?|kilos?|kg|gramos?|gr|g)\b'),
        ' ',
      )
      .replaceAll(RegExp(r'\b(de|del)\b'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (text.isEmpty) return null;

  var extraHalf = 0.0;
  final halfSuffix = RegExp(r'\s+y\s+medio(?:a)?$');
  if (halfSuffix.hasMatch(text)) {
    text = text.replaceFirst(halfSuffix, '').trim();
    extraHalf = 0.5;
  } else if (text == 'medio' || text == 'media') {
    text = '';
    extraHalf = 0.5;
  }

  double? amount;
  final numericMatch = RegExp(r'\d+(?:[.,]\d+)?').firstMatch(text);
  if (numericMatch != null) {
    amount = double.tryParse(numericMatch.group(0)!.replaceAll(',', '.'));
    final rest = text.replaceFirst(numericMatch.group(0)!, '').trim();
    if (rest.isNotEmpty) return null;
  } else if (text.isNotEmpty) {
    amount = _parseSpanishNumber(text);
  } else {
    amount = 0;
  }

  if (amount == null || amount < 0) return null;
  amount += extraHalf;
  if (hasKilograms) return amount * 1000;
  if (hasGrams) return amount;
  return amount < 50 ? amount * 1000 : amount;
}

double? _parseSpanishNumber(String phrase) {
  final numberWords = <String, int>{
    'cero': 0,
    'un': 1,
    'uno': 1,
    'una': 1,
    'dos': 2,
    'tres': 3,
    'cuatro': 4,
    'cinco': 5,
    'seis': 6,
    'siete': 7,
    'ocho': 8,
    'nueve': 9,
    'diez': 10,
    'once': 11,
    'doce': 12,
    'trece': 13,
    'catorce': 14,
    'quince': 15,
    'dieciseis': 16,
    'diecisiete': 17,
    'dieciocho': 18,
    'diecinueve': 19,
    'veinte': 20,
    'veintiuno': 21,
    'veintiun': 21,
    'veintiuna': 21,
    'veintidos': 22,
    'veintitres': 23,
    'veinticuatro': 24,
    'veinticinco': 25,
    'veintiseis': 26,
    'veintisiete': 27,
    'veintiocho': 28,
    'veintinueve': 29,
    'treinta': 30,
    'cuarenta': 40,
    'cincuenta': 50,
    'sesenta': 60,
    'setenta': 70,
    'ochenta': 80,
    'noventa': 90,
    'cien': 100,
    'ciento': 100,
    'doscientos': 200,
    'trescientos': 300,
    'cuatrocientos': 400,
    'quinientos': 500,
    'seiscientos': 600,
    'setecientos': 700,
    'ochocientos': 800,
    'novecientos': 900,
  };

  final words = phrase.split(' ').where((word) => word != 'y').toList();
  if (words.isEmpty) return null;
  var total = 0;
  var current = 0;
  for (final word in words) {
    if (word == 'mil') {
      total += (current == 0 ? 1 : current) * 1000;
      current = 0;
      continue;
    }
    final value = numberWords[word];
    if (value == null) return null;
    current += value;
  }
  total += current;
  return total.toDouble();
}

String _normalizeSpanish(String input) {
  const replacements = {
    'á': 'a',
    'é': 'e',
    'í': 'i',
    'ó': 'o',
    'ú': 'u',
    'ü': 'u',
  };
  var normalized = input.toLowerCase().trim();
  for (final entry in replacements.entries) {
    normalized = normalized.replaceAll(entry.key, entry.value);
  }
  return normalized.replaceAll(RegExp(r'\s+'), ' ');
}
