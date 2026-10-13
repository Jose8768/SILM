import 'dart:async';
import 'package:excel/excel.dart' as excel_pkg;
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart' as share_plus;
import 'controllers.dart';
import 'database.dart';
import 'hover_menu_item.dart';
import 'models.dart';
import 'pedido_materiales.dart'
    show PedidoMaterialesWidget, PedidoMaterialesWidgetState;
import 'theme.dart';

void toast(BuildContext context, String message, {bool isError = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      backgroundColor: surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: isError ? semanticDanger : borderSubtle),
      ),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      content: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: isError ? semanticDanger : semanticSuccess,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      duration: const Duration(seconds: 3),
    ));
}

void goBack(BuildContext context) => Navigator.of(context).maybePop();

Widget techButton(
  String text,
  VoidCallback? onPressed, {
  Color color = accentPetrol,
  Color? foreground,
  IconData? icon,
  bool isOutlined = false,
  double height = 44,
}) {
  final buttonForeground = foreground ?? textPrimary;
  return MouseRegion(
    cursor:
        onPressed != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
    child: SizedBox(
      height: height,
      child: isOutlined
          ? OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon ?? Icons.check, size: 16),
              label: Text(
                text.toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 0.8,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: buttonForeground,
                side: BorderSide(color: borderSubtle),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            )
          : ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon ?? Icons.check, size: 16),
              label: Text(
                text.toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 0.8,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: buttonForeground,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
    ),
  );
}

String dateText(int milliseconds, {bool short = false}) {
  final d = DateTime.fromMillisecondsSinceEpoch(milliseconds);
  final day = d.day.toString().padLeft(2, '0');
  final month = d.month.toString().padLeft(2, '0');
  return short
      ? '$day/$month/${d.year.toString().substring(2)}'
      : '$day/$month/${d.year}';
}

// ==========================================
// 1. PANTALLA DE LOGIN
// ==========================================
class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  const LoginScreen({super.key, required this.onLoginSuccess});
  @override
  State<LoginScreen> createState() => _LoginState();
}

class _LoginState extends State<LoginScreen> with RestorationMixin {
  final user = RestorableTextEditingController();
  final password = RestorableTextEditingController();
  final userFocus = FocusNode(), passwordFocus = FocusNode();
  bool _passwordVisible = false;

  @override
  String? get restorationId => 'login';

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(user, 'user');
    registerForRestoration(password, 'password');
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      FocusManager.instance.primaryFocus?.unfocus();
    });
  }

  void _openKeyboard(FocusNode focusNode) {
    focusNode.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && focusNode.hasFocus) {
        SystemChannels.textInput.invokeMethod<void>('TextInput.show');
      }
    });
  }

  void _login() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (user.value.text.trim().isEmpty || password.value.text.trim().isEmpty) {
      toast(context, 'Faltan datos de acceso', isError: true);
      return;
    }
    if ((user.value.text.trim().toLowerCase() == 'admin' ||
            user.value.text.trim().toLowerCase() == 'admin@voxel.com') &&
        password.value.text.trim() == 'admin123') {
      widget.onLoginSuccess();
      return;
    }
    toast(context, 'Credenciales incorrectas. Usa admin / admin123',
        isError: true);
  }

  @override
  void dispose() {
    user.dispose();
    password.dispose();
    userFocus.dispose();
    passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: bgBase,
        body: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.2),
              radius: 1.2,
              colors: [const Color(0xFF1B2027), bgBase],
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 390),
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: surfaceCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderSubtle),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x55000000),
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: surfaceElevated,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: accentPetrol.withValues(alpha: 0.35),
                            ),
                          ),
                          child: const Icon(
                            Icons.precision_manufacturing_outlined,
                            size: 28,
                            color: accentPetrol,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'VOXELCOST3D',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.0,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'SISTEMA DE CONTROL DE FABRICACIÓN',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 28),
                      TextField(
                        controller: user.value,
                        focusNode: userFocus,
                        keyboardType: TextInputType.text,
                        textCapitalization: TextCapitalization.none,
                        autocorrect: false,
                        enableSuggestions: false,
                        textInputAction: TextInputAction.next,
                        onTap: () => _openKeyboard(userFocus),
                        onEditingComplete: () => passwordFocus.requestFocus(),
                        style: TextStyle(color: textPrimary, fontSize: 13),
                        decoration: fieldDecoration(
                          'Operador / ID',
                          hint: 'admin',
                          prefix: Icon(Icons.person_outline,
                              color: textSecondary, size: 18),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: password.value,
                        focusNode: passwordFocus,
                        keyboardType: TextInputType.visiblePassword,
                        autocorrect: false,
                        enableSuggestions: false,
                        obscureText: !_passwordVisible,
                        textInputAction: TextInputAction.done,
                        onTap: () => _openKeyboard(passwordFocus),
                        onSubmitted: (_) => _login(),
                        style: TextStyle(color: textPrimary, fontSize: 13),
                        decoration: fieldDecoration(
                          'Contraseña',
                          hint: 'admin123',
                          prefix: Icon(Icons.lock_outline,
                              color: textSecondary, size: 18),
                          suffix: IconButton(
                            tooltip: _passwordVisible
                                ? 'Ocultar contraseña'
                                : 'Mostrar contraseña',
                            onPressed: () => setState(
                                () => _passwordVisible = !_passwordVisible),
                            icon: Icon(
                              _passwordVisible
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: textSecondary,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      techButton(
                        'ACCEDER AL TALLER',
                        _login,
                        icon: Icons.login,
                        height: 46,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

// ==========================================
// 2. PANTALLA PRINCIPAL (DASHBOARD)
// ==========================================
enum ActivePanel {
  welcome,
  printHistory,
  inventory,
  analytics,
  materialOrder,
  export,
}

class _ThemeModeSwitch extends StatelessWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onChanged;

  const _ThemeModeSwitch({
    required this.isDarkMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Tooltip(
        message: isDarkMode ? 'Activar modo claro' : 'Activar modo oscuro',
        child: Semantics(
          button: true,
          toggled: isDarkMode,
          label: 'Modo oscuro',
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => onChanged(!isDarkMode),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                width: 78,
                height: 36,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: surfaceElevated,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderStrong),
                ),
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 5),
                        child: Icon(
                          Icons.light_mode_rounded,
                          size: 17,
                          color: isDarkMode ? textMuted : accentAmber,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 5),
                        child: Icon(
                          Icons.dark_mode_rounded,
                          size: 17,
                          color: isDarkMode ? accentPetrol : textMuted,
                        ),
                      ),
                    ),
                    AnimatedAlign(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeInOut,
                      alignment: isDarkMode
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: surfaceCard,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.16),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          isDarkMode
                              ? Icons.dark_mode_rounded
                              : Icons.light_mode_rounded,
                          size: 16,
                          color: isDarkMode ? accentPetrol : accentAmber,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

class HomeScreen extends StatefulWidget {
  final VoidCallback onLogout;
  final bool isDarkMode;
  final ValueChanged<bool> onThemeModeChanged;

  const HomeScreen({
    super.key,
    required this.onLogout,
    required this.isDarkMode,
    required this.onThemeModeChanged,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isPinned = false;
  bool _isHovered = false;
  ActivePanel _activePanel = ActivePanel.welcome;
  Timer? _menuCloseTimer;
  late final PrintViewModel printVm = PrintViewModel(AppDatabase());
  late final InventoryViewModel inventoryVm = InventoryViewModel(AppDatabase());

  @override
  void dispose() {
    _menuCloseTimer?.cancel();
    printVm.dispose();
    inventoryVm.dispose();
    super.dispose();
  }

  void _selectPanel(ActivePanel panel) {
    _menuCloseTimer?.cancel();
    setState(() {
      _activePanel = panel;
      _isPinned = false;
      _isHovered = false;
    });
  }

  void _togglePinned() {
    _menuCloseTimer?.cancel();
    setState(() {
      if (_isPinned) {
        _isPinned = false;
        _isHovered = false;
      } else {
        _isPinned = true;
        _isHovered = false;
      }
    });
  }

  void _onHoverMenu(bool hovered) {
    if (_isPinned) return;
    _menuCloseTimer?.cancel();
    if (hovered) {
      if (!_isHovered) {
        setState(() {
          _isHovered = true;
        });
      }
    } else {
      // Período de gracia de 350ms para que al mover el cursor hacia arriba,
      // hacia los lados o por el encabezado el menú se mantenga abierto sin cerrarse bruscamente.
      _menuCloseTimer = Timer(const Duration(milliseconds: 350), () {
        if (mounted && !_isPinned && _isHovered) {
          setState(() {
            _isHovered = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool showMenu = _isPinned || _isHovered;

    return Scaffold(
      backgroundColor: bgBase,
      body: Stack(
        children: [
          // 1. Capa del Panel:
          // Cuando se da clic (_isPinned == true), el spacer empuja el panel a la derecha.
          // En estado normal o hover, el panel está a pantalla completa.
          Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOutCubic,
                width: _isPinned ? 320 : 0,
              ),
              Expanded(
                child: _buildCurrentPanel(),
              ),
            ],
          ),

          // 2. Capa del Menú Lateral:
          // Se despliega de izquierda a derecha apareciendo simultáneamente de invisible (0%) a totalmente opaco (100%).
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 320,
            child: IgnorePointer(
              ignoring: !showMenu,
              child: MouseRegion(
                onEnter: (_) => _onHoverMenu(true),
                onExit: (_) => _onHoverMenu(false),
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 380),
                  curve: Curves.easeOutCubic,
                  offset: showMenu ? Offset.zero : const Offset(-1.0, 0),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 380),
                    curve: Curves.easeOutCubic,
                    opacity: showMenu ? 1.0 : 0.0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: surfaceCard,
                        border: Border(
                          right: BorderSide(color: borderSubtle),
                        ),
                        boxShadow: (_isHovered && !_isPinned)
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.45),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                  offset: const Offset(4, 0),
                                ),
                              ]
                            : null,
                      ),
                      child: _buildSidebar(context),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentPanel() {
    switch (_activePanel) {
      case ActivePanel.welcome:
        return _buildWelcomePanel(context);
      case ActivePanel.printHistory:
        return PrintHistoryScreen(
          onToggleMenu: _togglePinned,
          onHoverMenu: () => _onHoverMenu(true),
          isPinned: _isPinned,
          vm: printVm,
          inventoryVm: inventoryVm,
        );
      case ActivePanel.inventory:
        return InventoryScreen(
          onToggleMenu: _togglePinned,
          onHoverMenu: () => _onHoverMenu(true),
          isPinned: _isPinned,
          vm: inventoryVm,
        );
      case ActivePanel.analytics:
        return AnalyticsScreen(
          onToggleMenu: _togglePinned,
          onHoverMenu: () => _onHoverMenu(true),
          isPinned: _isPinned,
          vm: printVm,
          inventoryVm: inventoryVm,
        );
      case ActivePanel.materialOrder:
        return MaterialOrderScreen(
          inventoryVm: inventoryVm,
          onToggleMenu: _togglePinned,
          onHoverMenu: () => _onHoverMenu(true),
          isPinned: _isPinned,
        );
      case ActivePanel.export:
        return ExportScreen(
          onToggleMenu: _togglePinned,
          onHoverMenu: () => _onHoverMenu(true),
          isPinned: _isPinned,
          vm: printVm,
          inventoryVm: inventoryVm,
        );
    }
  }

  Widget _buildSidebar(BuildContext context) {
    return Container(
      color: surfaceCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header del Menú - alineado exactamente con la coordenada y dimensiones del AppBar (56px)
          Container(
            height: kToolbarHeight,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: bgBase,
              border: Border(bottom: BorderSide(color: borderSubtle)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 48,
                  height: kToolbarHeight,
                  child: IconButton(
                    hoverColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    focusColor: Colors.transparent,
                    mouseCursor: SystemMouseCursors.click,
                    icon: const SidebarToggleIcon(),
                    onPressed: _togglePinned,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'MENÚ PRINCIPAL',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _ThemeModeSwitch(
                    isDarkMode: widget.isDarkMode,
                    onChanged: widget.onThemeModeChanged,
                  ),
                ),
              ],
            ),
          ),

          // Opciones de navegación
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 10, bottom: 8, top: 4),
                  child: Text(
                    'MÓDULOS DE GESTIÓN',
                    style: TextStyle(
                      color: textSecondary.withValues(alpha: 0.8),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                HoverMenuItem(
                  title: 'Registro de Impresiones',
                  icon: Icons.view_in_ar_rounded,
                  selected: _activePanel == ActivePanel.printHistory,
                  onTap: () => _selectPanel(ActivePanel.printHistory),
                ),
                HoverMenuItem(
                  title: 'Inventario de Materiales',
                  icon: Icons.inventory_2_rounded,
                  selected: _activePanel == ActivePanel.inventory,
                  onTap: () => _selectPanel(ActivePanel.inventory),
                ),
                HoverMenuItem(
                  title: 'Análisis de Producción',
                  icon: Icons.bar_chart_rounded,
                  selected: _activePanel == ActivePanel.analytics,
                  onTap: () => _selectPanel(ActivePanel.analytics),
                ),
                HoverMenuItem(
                  title: 'Pedido de Material',
                  icon: Icons.shopping_cart_outlined,
                  selected: _activePanel == ActivePanel.materialOrder,
                  onTap: () => _selectPanel(ActivePanel.materialOrder),
                ),
                HoverMenuItem(
                  title: 'Exportar',
                  icon: Icons.download_rounded,
                  selected: _activePanel == ActivePanel.export,
                  onTap: () => _selectPanel(ActivePanel.export),
                ),
              ],
            ),
          ),

          // Pie del Menú con Cerrar Sesión
          Divider(color: borderSubtle, height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: widget.onLogout,
                  borderRadius: BorderRadius.circular(8),
                  mouseCursor: SystemMouseCursors.click,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: borderSubtle),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout_rounded,
                            size: 16, color: textSecondary),
                        const SizedBox(width: 8),
                        Text(
                          'CERRAR SESIÓN',
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'VoxelCost 3D · Control de Taller',
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomePanel(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([printVm, inventoryVm]),
      builder: (context, _) {
        final latest = printVm.latestRecord;
        final lowStock = inventoryVm.lowStockItems;

        return Scaffold(
          backgroundColor: bgBase,
          appBar: darkAppBar(
            'PANEL PRINCIPAL',
            _togglePinned,
            leadingWidget: const SidebarToggleIcon(),
            onHoverEnter: () => _onHoverMenu(true),
            onHoverExit: () => _onHoverMenu(false),
            hideLeading: _isPinned,
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: double.infinity),
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                children: [
                  // Cabecera compacta con saludo industrial
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: surfaceCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderSubtle),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: surfaceElevated,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: accentPetrol.withValues(alpha: 0.4)),
                          ),
                          child: const Icon(Icons.layers_outlined,
                              size: 24, color: accentPetrol),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'VOXELCOST 3D · SISTEMA DE CONTROL DE FABRICACIÓN',
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '¡BIENVENIDO!',
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                        techButton(
                          'NUEVA IMPRESIÓN',
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PrintFormScreen(
                                vm: printVm,
                                inventoryVm: inventoryVm,
                              ),
                            ),
                          ),
                          icon: Icons.add_circle_outline,
                          color: accentPetrol,
                          height: 38,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Resumen Rápido (4 Tarjetas)
                  LayoutBuilder(builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 650;
                    final cardWidth = isNarrow
                        ? constraints.maxWidth
                        : (constraints.maxWidth - 12) / 2;

                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: cardWidth,
                          child: _welcomeMetricCard(
                            title: 'CONSUMO TOTAL',
                            value: '${printVm.totalGrams.toStringAsFixed(1)} g',
                            subtitle:
                                '${printVm.totalPlaGrams.toStringAsFixed(0)}g PLA · ${printVm.totalPetgGrams.toStringAsFixed(0)}g PETG',
                            icon: Icons.scale_outlined,
                            iconColor: accentPetrol,
                            badgeText: '${printVm.totalPieces} piezas',
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: _welcomeMetricCard(
                            title: 'PIEZAS FABRICADAS',
                            value: '${printVm.totalPieces} piezas',
                            subtitle:
                                '${printVm.totalPrints} registros técnicos en historial',
                            icon: Icons.precision_manufacturing_outlined,
                            iconColor: accentAmber,
                            badgeText: printVm.totalPieces > 0
                                ? 'Activo'
                                : 'Sin piezas',
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: _welcomeMetricCard(
                            title: 'ESTADO DE STOCK',
                            value: lowStock.isEmpty
                                ? 'Niveles Óptimos'
                                : '${lowStock.length} Bajo Stock',
                            subtitle: lowStock.isEmpty
                                ? 'Todas las bobinas con stock > 20%'
                                : lowStock
                                    .map((i) =>
                                        '${i.material} ${i.color} (${i.stockActual.toInt()}g)')
                                    .join(', '),
                            icon: lowStock.isEmpty
                                ? Icons.check_circle_outline
                                : Icons.warning_amber_rounded,
                            iconColor: lowStock.isEmpty
                                ? semanticSuccess
                                : semanticDanger,
                            isAlert: lowStock.isNotEmpty,
                            badgeText: lowStock.isEmpty ? 'OK' : 'ATENCIÓN',
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: _welcomeLastPrintCard(latest),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _welcomeMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    String? badgeText,
    bool isAlert = false,
  }) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surfaceCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isAlert ? semanticDanger.withValues(alpha: 0.5) : borderSubtle,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 18, color: iconColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                if (badgeText != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (isAlert ? semanticDanger : accentPetrol)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: (isAlert ? semanticDanger : accentPetrol)
                            .withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        color: isAlert ? semanticDanger : accentPetrol,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                color: isAlert ? semanticDanger : textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: textSecondary,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );

  Widget _welcomeLastPrintCard(PrintRecord? latest) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surfaceCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: surfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.history_toggle_off_outlined,
                      size: 18, color: accentPetrol),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'ÚLTIMA PIEZA REGISTRADA',
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                if (latest != null)
                  Text(
                    dateText(latest.date, short: true),
                    style: TextStyle(color: textMuted, fontSize: 10),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (latest == null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  'Aún no hay impresiones registradas',
                  style: TextStyle(color: textSecondary, fontSize: 12),
                ),
              )
            else ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      (latest.projectName ?? '').trim().isNotEmpty
                          ? latest.projectName!
                          : latest.pieceType,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (latest.cantidad > 1) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: accentAmber.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                            color: accentAmber.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        '×${latest.cantidad}',
                        style: const TextStyle(
                          color: accentAmber,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if ((latest.projectName ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  'Archivo: ${latest.pieceType}',
                  style: TextStyle(color: textSecondary, fontSize: 11),
                ),
              ],
              const SizedBox(height: 3),
              Text(
                'Categoría: ${latest.figureCategory} · ${latest.totalGrams.toStringAsFixed(1)}g total${latest.cantidad > 1 ? ' (${latest.unitGrams.toStringAsFixed(1)}g c/u)' : ''}',
                style: TextStyle(color: textSecondary, fontSize: 11),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: latest.materials.map((m) {
                  final colorObj =
                      findVoxelColor(value: m.color, name: m.colorName);
                  final itemTotalGrams = m.grams * latest.cantidad;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      colorSwatchCircle(colorObj.color,
                          size: 8, isTransparent: colorObj.isTransparent),
                      const SizedBox(width: 4),
                      Text(
                        latest.cantidad > 1
                            ? '${m.type} (${itemTotalGrams.toStringAsFixed(1)}g)'
                            : '${m.type} (${m.grams.toStringAsFixed(1)}g)',
                        style: TextStyle(
                            color: textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      );
}

class MaterialOrderScreen extends StatefulWidget {
  final InventoryViewModel inventoryVm;
  final VoidCallback onToggleMenu;
  final VoidCallback onHoverMenu;
  final bool isPinned;

  const MaterialOrderScreen({
    super.key,
    required this.inventoryVm,
    required this.onToggleMenu,
    required this.onHoverMenu,
    required this.isPinned,
  });

  @override
  State<MaterialOrderScreen> createState() => _MaterialOrderScreenState();
}

class _MaterialOrderScreenState extends State<MaterialOrderScreen> {
  final GlobalKey<PedidoMaterialesWidgetState> _pedidoKey =
      GlobalKey<PedidoMaterialesWidgetState>();

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: widget.inventoryVm,
        builder: (context, _) {
          final lowStockItems = widget.inventoryVm.lowStockItems;
          final depletedCount =
              lowStockItems.where((item) => item.isDepleted).length;
          final itemsToOrder = lowStockItems.length;

          return Scaffold(
            backgroundColor: bgBase,
            appBar: darkAppBar(
              'PEDIDO DE MATERIAL',
              widget.onToggleMenu,
              leadingWidget: const SidebarToggleIcon(),
              onHoverEnter: widget.onHoverMenu,
              hideLeading: widget.isPinned,
            ),
            body: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (widget.inventoryVm.error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: semanticDanger.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: semanticDanger.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      widget.inventoryVm.error!,
                      style:
                          const TextStyle(color: semanticDanger, fontSize: 13),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                PedidoMaterialesWidget(
                  key: _pedidoKey,
                  embedded: true,
                ),
                const SizedBox(height: 16),
                formCard(
                  title: 'Lista de pedido',
                  subtitle:
                      'El inventario marca para reponer las bobinas con 20% o menos',
                  child: lowStockItems.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          child: Center(
                            child: Text(
                              'No hay materiales por acabarse. Puedes agregar materiales por escrito.',
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(color: textSecondary, fontSize: 13),
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('MATERIAL')),
                              DataColumn(label: Text('COLOR / DETALLE')),
                              DataColumn(label: Text('STOCK')),
                              DataColumn(label: Text('DISPONIBLE')),
                              DataColumn(label: Text('ESTADO')),
                              DataColumn(label: Text('')),
                            ],
                            rows: [
                              ...lowStockItems.map((item) {
                                final ratio = item.remainingRatio;
                                final statusColor = item.isDepleted
                                    ? semanticDanger
                                    : semanticWarning;
                                return DataRow(cells: [
                                  DataCell(Text(item.material,
                                      style: TextStyle(
                                          color: textPrimary,
                                          fontWeight: FontWeight.w600))),
                                  DataCell(Text('${item.color} · ${item.brand}',
                                      style: TextStyle(color: textSecondary))),
                                  DataCell(Text(
                                      '${item.stockActual.toStringAsFixed(0)} / ${item.stockInicial.toStringAsFixed(0)} g',
                                      style: TextStyle(color: textPrimary))),
                                  DataCell(
                                    SizedBox(
                                      width: 120,
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: LinearProgressIndicator(
                                              value: ratio,
                                              minHeight: 6,
                                              backgroundColor: borderSubtle,
                                              color: statusColor,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text('${(ratio * 100).round()}%',
                                              style: TextStyle(
                                                  color: statusColor,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  DataCell(_orderStatusBadge(
                                      item.isDepleted ? 'AGOTADO' : 'PEDIR',
                                      statusColor)),
                                  DataCell(
                                    FilledButton.tonalIcon(
                                      onPressed: () {
                                        _pedidoKey.currentState?.prefillOrder(
                                          material: item.material,
                                          color: item.color,
                                          spoolGrams: item.stockInicial > 0
                                              ? item.stockInicial
                                              : 1000,
                                        );
                                      },
                                      icon: const Icon(
                                          Icons.add_shopping_cart_rounded,
                                          size: 14),
                                      label: const Text('Pedir',
                                          style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700)),
                                      style: FilledButton.styleFrom(
                                        visualDensity: VisualDensity.compact,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 0),
                                      ),
                                    ),
                                  ),
                                ]);
                              }),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      );


  Widget _orderStatusBadge(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
      );
}

// ==========================================
// 3. HISTORIAL TÉCNICO DE IMPRESIONES
// ==========================================
class PrintHistoryScreen extends StatefulWidget {
  final VoidCallback? onToggleMenu;
  final VoidCallback? onHoverMenu;
  final bool isPinned;
  final PrintViewModel? vm;
  final InventoryViewModel? inventoryVm;
  const PrintHistoryScreen({
    super.key,
    this.onToggleMenu,
    this.onHoverMenu,
    this.isPinned = false,
    this.vm,
    this.inventoryVm,
  });
  @override
  State<PrintHistoryScreen> createState() => _HistoryState();
}

class _HistoryState extends State<PrintHistoryScreen> {
  late final PrintViewModel vm;
  late final InventoryViewModel inventoryVm;
  bool _ownsVm = false;
  bool _ownsInvVm = false;

  final TextEditingController _searchController = TextEditingController();
  String _activeFilter = 'Todos'; // 'Todos', 'PLA', 'PETG', 'Este mes'

  @override
  void initState() {
    super.initState();
    if (widget.vm != null) {
      vm = widget.vm!;
    } else {
      vm = PrintViewModel(AppDatabase());
      _ownsVm = true;
    }
    if (widget.inventoryVm != null) {
      inventoryVm = widget.inventoryVm!;
    } else {
      inventoryVm = InventoryViewModel(AppDatabase());
      _ownsInvVm = true;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    if (_ownsVm) vm.dispose();
    if (_ownsInvVm) inventoryVm.dispose();
    super.dispose();
  }

  List<PrintRecord> _getFilteredRecords() {
    final query = _searchController.text.trim().toLowerCase();
    final now = DateTime.now();

    return vm.allRecords.where((r) {
      // 1. Filtro por Chips
      if (_activeFilter == 'PLA') {
        if (!r.materials.any((m) => m.type.toUpperCase() == 'PLA')) {
          return false;
        }
      } else if (_activeFilter == 'PETG') {
        if (!r.materials.any((m) => m.type.toUpperCase() == 'PETG')) {
          return false;
        }
      } else if (_activeFilter == 'Este mes') {
        final d = DateTime.fromMillisecondsSinceEpoch(r.date);
        if (d.year != now.year || d.month != now.month) return false;
      }

      // 2. Filtro por búsqueda (archivo, proyecto, solicitante, no. de control, impresora o color)
      if (query.isNotEmpty) {
        final matchPiece = r.pieceType.toLowerCase().contains(query);
        final matchProject =
            (r.projectName ?? '').toLowerCase().contains(query);
        final matchCategory = r.figureCategory.toLowerCase().contains(query);
        final matchNotes = (r.notes ?? '').toLowerCase().contains(query);
        final matchRequester =
            (r.requesterName ?? '').toLowerCase().contains(query);
        final matchReqId = (r.requesterId ?? '').toLowerCase().contains(query);
        final matchReqType =
            (r.requesterType ?? '').toLowerCase().contains(query);
        final matchPrinter =
            (r.printerName ?? '').toLowerCase().contains(query);
        final matchMaterial = r.materials.any((m) {
          final cName = (m.colorName ?? '').toLowerCase();
          final mType = m.type.toLowerCase();
          final colorObj = findVoxelColor(value: m.color, name: m.colorName);
          return cName.contains(query) ||
              mType.contains(query) ||
              colorObj.name.toLowerCase().contains(query);
        });
        if (!matchPiece &&
            !matchProject &&
            !matchCategory &&
            !matchNotes &&
            !matchMaterial &&
            !matchRequester &&
            !matchReqId &&
            !matchReqType &&
            !matchPrinter) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: Listenable.merge([vm, inventoryVm]),
        builder: (_, __) {
          final filtered = _getFilteredRecords();

          return Scaffold(
            appBar: darkAppBar(
              'HISTORIAL TÉCNICO',
              widget.onToggleMenu ?? () => goBack(context),
              leadingWidget: widget.onToggleMenu != null
                  ? const SidebarToggleIcon()
                  : null,
              leadingIcon: Icons.arrow_back,
              onHoverEnter: widget.onHoverMenu,
              hideLeading: widget.isPinned,
            ),
            backgroundColor: bgBase,
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1360),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 780;
                    return ListView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      children: [
                        _searchAndFilterRow(),
                        const SizedBox(height: 16),

                        if (vm.error != null) ...[
                          _databaseError(vm.error!),
                          const SizedBox(height: 14),
                        ],

                        _tableHeader(isNarrow),
                        const SizedBox(height: 8),

                        if (filtered.isEmpty)
                          _emptyState(_searchController.text.isNotEmpty ||
                              _activeFilter != 'Todos')
                        else
                          ...filtered.map(
                            (record) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _recordRow(context, vm, record,
                                  isNarrow: isNarrow),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          );
        },
      );

  Widget _databaseError(String message) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: semanticDanger.withValues(alpha: 0.12),
          border: Border.all(color: semanticDanger.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: semanticDanger, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: semanticDanger, fontSize: 13),
              ),
            ),
          ],
        ),
      );

  Widget _emptyState(bool hasFilters) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: surfaceCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderSubtle),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: surfaceElevated,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.print_outlined, size: 32, color: textMuted),
            ),
            const SizedBox(height: 14),
            Text(
              hasFilters
                  ? 'No se encontraron registros que coincidan con la búsqueda o filtro'
                  : 'No hay impresiones registradas en el historial',
              style: TextStyle(
                color: textPrimary,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              hasFilters
                  ? 'Prueba modificando los términos de búsqueda o seleccionando "Todos".'
                  : 'Registra una nueva impresión para comenzar a llevar el registro.',
              style: TextStyle(
                color: textSecondary,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  Widget _searchAndFilterRow() {
    return LayoutBuilder(builder: (context, constraints) {
      final isNarrow = constraints.maxWidth < 780;

      final searchField = SizedBox(
        height: 40,
        child: TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          style: TextStyle(color: textPrimary, fontSize: 13),
          decoration: InputDecoration(
            isDense: true,
            hintText: 'Buscar por pieza, solicitante, material o impresora...',
            hintStyle: TextStyle(color: textMuted, fontSize: 12.5),
            prefixIcon: Icon(Icons.search, size: 18, color: textMuted),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.close, size: 16, color: textMuted),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                  )
                : null,
            filled: true,
            fillColor: surfaceElevated,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: borderSubtle),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: borderSubtle),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: accentPetrol, width: 1.5),
            ),
          ),
        ),
      );

      final filterChips = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _filterChip('Todos'),
          const SizedBox(width: 6),
          _filterChip('PLA'),
          const SizedBox(width: 6),
          _filterChip('PETG'),
          const SizedBox(width: 6),
          _filterChip('Este mes'),
        ],
      );

      final newPrintBtn = ElevatedButton.icon(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PrintFormScreen(vm: vm, inventoryVm: inventoryVm),
          ),
        ),
        icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
        label: const Text(
          'Nueva impresión',
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: accentPetrol,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          minimumSize: const Size(0, 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );

      if (isNarrow) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: searchField),
                const SizedBox(width: 8),
                newPrintBtn,
              ],
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: filterChips,
            ),
          ],
        );
      } else {
        return Row(
          children: [
            Expanded(child: searchField),
            const SizedBox(width: 12),
            filterChips,
            const SizedBox(width: 14),
            newPrintBtn,
          ],
        );
      }
    });
  }

  Widget _filterChip(String label) {
    final isSelected = _activeFilter == label;
    return InkWell(
      onTap: () => setState(() => _activeFilter = label),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? surfaceElevated : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? accentPetrol : borderSubtle,
            width: isSelected ? 1.4 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? textPrimary : textSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _tableHeader(bool isNarrow) {
    if (isNarrow) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Row(
          children: [
            const SizedBox(width: 20),
            Text(
              'PIEZA',
              style: TextStyle(
                color: textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
            ),
            const Spacer(),
            Text(
              'FILAMENTO',
              style: TextStyle(
                color: textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(width: 36),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const SizedBox(width: 25),
          Expanded(
            flex: 4,
            child: Text(
              'PIEZA',
              style: TextStyle(
                color: textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            flex: 3,
            child: Text(
              'SOLICITANTE',
              style: TextStyle(
                color: textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            flex: 3,
            child: Text(
              'DETALLES TÉCNICOS',
              style: TextStyle(
                color: textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
            ),
          ),
          const SizedBox(width: 14),
          SizedBox(
            width: 85,
            child: Text(
              'FILAMENTO',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _recordRow(BuildContext context, PrintViewModel vm, PrintRecord r,
      {bool isNarrow = false}) {
    return _PrintRecordRow(
      record: r,
      vm: vm,
      inventoryVm: inventoryVm,
      onDelete: (rec) => _confirmDeleteRecord(context, vm, inventoryVm, rec),
      isNarrow: isNarrow,
    );
  }

  void _confirmDeleteRecord(
    BuildContext context,
    PrintViewModel vm,
    InventoryViewModel inventoryVm,
    PrintRecord r,
  ) {
    bool returnToStock = true;
    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          backgroundColor: surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: borderSubtle),
          ),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: semanticDanger, size: 22),
              const SizedBox(width: 8),
              Text(
                'Eliminar Registro',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¿Eliminar "${r.pieceType}"? Esta acción no se puede deshacer.',
                style: TextStyle(color: textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 14),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderSubtle),
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: returnToStock,
                      activeColor: accentPetrol,
                      checkColor: Colors.white,
                      onChanged: (val) {
                        setDialogState(() {
                          returnToStock = val ?? false;
                        });
                      },
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Devolver filamento al inventario',
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text('Cancelar',
                  style: TextStyle(color: textSecondary, fontSize: 12)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogCtx).pop();
                if (returnToStock) {
                  for (final m in r.materials) {
                    inventoryVm.restoreGrams(
                      m.type,
                      m.grams * r.cantidad,
                      colorName: m.colorName,
                      colorValue: m.color,
                    );
                  }
                }
                await vm.deleteRecord(r);
                if (context.mounted) {
                  toast(
                    context,
                    returnToStock
                        ? 'Registro eliminado y ${r.totalGrams.toStringAsFixed(1)} g devueltos al inventario'
                        : 'Registro eliminado',
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: semanticDanger,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Eliminar',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}

class _MaterialColorEntry {
  final String type;
  final VoxelColor voxelColor;
  final String fullName;

  _MaterialColorEntry({
    required this.type,
    required this.voxelColor,
    required this.fullName,
  });
}

class _PrintRecordRow extends StatefulWidget {
  final PrintRecord record;
  final PrintViewModel vm;
  final InventoryViewModel inventoryVm;
  final void Function(PrintRecord record) onDelete;
  final bool isNarrow;

  const _PrintRecordRow({
    required this.record,
    required this.vm,
    required this.inventoryVm,
    required this.onDelete,
    this.isNarrow = false,
  });

  @override
  State<_PrintRecordRow> createState() => _PrintRecordRowState();
}

class _PrintRecordRowState extends State<_PrintRecordRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.record;

    // Obtener lista única de materiales y colores
    final List<_MaterialColorEntry> distinctMaterials = [];
    final Set<String> seenKeys = {};

    for (final m in r.materials) {
      final vColor = findVoxelColor(value: m.color, name: m.colorName);
      final colorName = (m.colorName != null && m.colorName!.trim().isNotEmpty)
          ? m.colorName!.trim()
          : vColor.name;
      final fullName = '${m.type} $colorName'.trim();
      final key = '${m.type.trim().toUpperCase()}_${vColor.value}_$colorName';

      if (!seenKeys.contains(key)) {
        seenKeys.add(key);
        distinctMaterials.add(_MaterialColorEntry(
          type: m.type,
          voxelColor: vColor,
          fullName: fullName,
        ));
      }
    }

    if (distinctMaterials.isEmpty) {
      final fallback = findVoxelColor(hex: '#888887');
      distinctMaterials.add(_MaterialColorEntry(
        type: 'Material',
        voxelColor: fallback,
        fullName: 'Material',
      ));
    }

    final primaryColor = distinctMaterials.first.voxelColor;
    final dateStr = dateText(r.date);
    final isMultiQty = r.cantidad > 1;

    final hasProjectName = (r.projectName ?? '').trim().isNotEmpty;
    final mainTitle = hasProjectName ? r.projectName!.trim() : r.pieceType;
    final subtitleFileName = hasProjectName ? r.pieceType : null;

    final totalGramsStr = r.totalGrams % 1 == 0
        ? '${r.totalGrams.toInt()} g'
        : '${r.totalGrams.toStringAsFixed(1)} g';

    final unitGramsStr = r.unitGrams % 1 == 0
        ? '${r.unitGrams.toInt()} g c/u'
        : '${r.unitGrams.toStringAsFixed(1)} g c/u';

    final optionsMenu = SizedBox(
      width: 32,
      height: 32,
      child: PopupMenuButton<String>(
        tooltip: 'Opciones',
        color: surfaceCard,
        elevation: 6,
        padding: EdgeInsets.zero,
        icon: Icon(
          Icons.more_vert,
          size: 18,
          color: _isHovered ? textPrimary : textSecondary,
        ),
        constraints: const BoxConstraints(minWidth: 130),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: borderSubtle),
        ),
        onSelected: (val) {
          if (val == 'edit') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PrintFormScreen(
                  vm: widget.vm,
                  inventoryVm: widget.inventoryVm,
                  record: r,
                ),
              ),
            );
          } else if (val == 'delete') {
            widget.onDelete(r);
          }
        },
        itemBuilder: (ctx) => [
          PopupMenuItem(
            value: 'edit',
            height: 36,
            child: Row(
              children: [
                Icon(Icons.edit_outlined, size: 16, color: textPrimary),
                const SizedBox(width: 8),
                Text('Editar',
                    style: TextStyle(
                        color: textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const PopupMenuDivider(height: 1),
          const PopupMenuItem(
            value: 'delete',
            height: 36,
            child: Row(
              children: [
                Icon(Icons.delete_outline, size: 16, color: semanticDanger),
                const SizedBox(width: 8),
                Text('Eliminar',
                    style: TextStyle(
                        color: semanticDanger,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _isHovered
              ? surfaceElevated.withValues(alpha: 0.7)
              : surfaceCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _isHovered ? borderStrong : borderSubtle,
          ),
        ),
        child: widget.isNarrow
            ? _buildNarrowLayout(
                r,
                primaryColor,
                mainTitle,
                subtitleFileName,
                isMultiQty,
                dateStr,
                distinctMaterials,
                totalGramsStr,
                unitGramsStr,
                optionsMenu,
              )
            : _buildWideLayout(
                r,
                primaryColor,
                mainTitle,
                subtitleFileName,
                isMultiQty,
                dateStr,
                distinctMaterials,
                totalGramsStr,
                unitGramsStr,
                optionsMenu,
              ),
      ),
    );
  }

  Widget _buildWideLayout(
    PrintRecord r,
    VoxelColor primaryColor,
    String mainTitle,
    String? subtitleFileName,
    bool isMultiQty,
    String dateStr,
    List<_MaterialColorEntry> distinctMaterials,
    String totalGramsStr,
    String unitGramsStr,
    Widget optionsMenu,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 1. Punto de color simple y elegante
        colorSwatchCircle(
          primaryColor.color,
          size: 11,
          isTransparent: primaryColor.isTransparent,
        ),
        const SizedBox(width: 14),

        // 2. Columna: PIEZA Y PROYECTO
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      mainTitle,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isMultiQty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: surfaceElevated,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: borderSubtle),
                      ),
                      child: Text(
                        '× ${r.cantidad}',
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  if (subtitleFileName != null &&
                      subtitleFileName.trim().isNotEmpty)
                    Flexible(
                      child: Text(
                        subtitleFileName,
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if (r.figureCategory.trim().isNotEmpty) ...[
                    if (subtitleFileName != null &&
                        subtitleFileName.trim().isNotEmpty)
                      Text(
                        ' · ',
                        style: TextStyle(color: textMuted, fontSize: 11),
                      ),
                    Text(
                      r.figureCategory,
                      style: TextStyle(
                        color: textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  if ((subtitleFileName == null || subtitleFileName.isEmpty) &&
                      r.figureCategory.trim().isEmpty)
                    Text(
                      'Pieza 3D',
                      style: TextStyle(
                        color: textMuted.withValues(alpha: 0.6),
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),

        // 3. Columna: SOLICITANTE
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if ((r.requesterName ?? '').trim().isNotEmpty) ...[
                Text(
                  r.requesterName!.trim(),
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  '${r.requesterType ?? 'Solicitante'}${r.requesterId != null && r.requesterId!.isNotEmpty ? ' (${r.requesterId})' : ''}',
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ] else ...[
                Text(
                  '—',
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 14),

        // 4. Columna: DETALLES TÉCNICOS (Material, Impresora, Fecha, Tiempo)
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMaterialSubtitle(distinctMaterials),
              const SizedBox(height: 3),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      '$dateStr · ${(r.printerName ?? '').trim().isNotEmpty ? r.printerName! : 'Estándar'}',
                      style: TextStyle(
                        color: textMuted,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if ((r.printTime ?? '').trim().isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Text(
                      '⏱ ${r.printTime}',
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),

        // 5. Columna: FILAMENTO
        SizedBox(
          width: 85,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                totalGramsStr,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isMultiQty ? unitGramsStr : 'total',
                style: TextStyle(
                  color: textMuted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),

        // 6. Columna: OPCIONES
        optionsMenu,
      ],
    );
  }

  Widget _buildNarrowLayout(
    PrintRecord r,
    VoxelColor primaryColor,
    String mainTitle,
    String? subtitleFileName,
    bool isMultiQty,
    String dateStr,
    List<_MaterialColorEntry> distinctMaterials,
    String totalGramsStr,
    String unitGramsStr,
    Widget optionsMenu,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            colorSwatchCircle(
              primaryColor.color,
              size: 10,
              isTransparent: primaryColor.isTransparent,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                mainTitle,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isMultiQty) ...[
              const SizedBox(width: 6),
              Text(
                '× ${r.cantidad}',
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(width: 8),
            Text(
              totalGramsStr,
              style: TextStyle(
                color: textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 4),
            optionsMenu,
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const SizedBox(width: 20),
            Expanded(
              child: _buildMaterialSubtitle(distinctMaterials),
            ),
            if ((r.requesterName ?? '').trim().isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                r.requesterName!.trim(),
                style: TextStyle(
                  color: textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const SizedBox(width: 20),
            Text(
              '$dateStr · ${(r.printerName ?? '').trim().isNotEmpty ? r.printerName! : 'Estándar'}',
              style: TextStyle(
                color: textMuted,
                fontSize: 10.5,
              ),
            ),
            if ((r.printTime ?? '').trim().isNotEmpty) ...[
              const SizedBox(width: 6),
              Text(
                '· ⏱ ${r.printTime}',
                style: TextStyle(
                  color: textMuted,
                  fontSize: 10.5,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildMaterialSubtitle(List<_MaterialColorEntry> materials) {
    if (materials.length <= 1) {
      return Text(
        materials.first.fullName,
        style: TextStyle(
          color: textPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    // Múltiples materiales: swatches circulares compactos con tooltip
    final List<Widget> swatches = [];
    final bool hasOverflow = materials.length > 5;
    final int displayCount = hasOverflow ? 4 : materials.length;

    for (int i = 0; i < displayCount; i++) {
      final m = materials[i];
      swatches.add(
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Tooltip(
            message: m.fullName,
            waitDuration: const Duration(milliseconds: 200),
            child: colorSwatchCircle(
              m.voxelColor.color,
              size: 9,
              isTransparent: m.voxelColor.isTransparent,
            ),
          ),
        ),
      );
    }

    if (hasOverflow) {
      final remainingCount = materials.length - 4;
      final remainingNames =
          materials.skip(4).map((m) => m.fullName).join('\n');
      swatches.add(
        Tooltip(
          message: remainingNames,
          waitDuration: const Duration(milliseconds: 200),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: surfaceElevated,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: borderSubtle),
            ),
            child: Text(
              '+$remainingCount',
              style: TextStyle(
                color: textSecondary,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ...swatches,
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            '${materials.length} materiales',
            style: TextStyle(
              color: textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ==========================================
// 4. REGISTRO / EDICIÓN DE IMPRESIÓN
// ==========================================
class PrintFormScreen extends StatefulWidget {
  final PrintViewModel vm;
  final InventoryViewModel? inventoryVm;
  final PrintRecord? record;
  const PrintFormScreen(
      {super.key, required this.vm, this.inventoryVm, this.record});
  @override
  State<PrintFormScreen> createState() => _FormState();
}

class PredefinedPrinter {
  final String key;
  final String displayName;
  final String printerName;
  final int maxCount;
  final bool isUnique;

  const PredefinedPrinter({
    required this.key,
    required this.displayName,
    required this.printerName,
    this.maxCount = 1,
    this.isUnique = false,
  });
}

const List<PredefinedPrinter> predefinedPrinters = [
  PredefinedPrinter(
    key: 'flashforge_creator_3_pro',
    displayName: 'FLASHFORGE CREATOR 3 PRO',
    printerName: 'Flashforge Creator 3 Pro',
    maxCount: 1,
    isUnique: true,
  ),
  PredefinedPrinter(
    key: 'creality_ender_v3_se',
    displayName: 'CREALITY ENDER V3 SE',
    printerName: 'Creality Ender V3 SE',
    maxCount: 1,
    isUnique: true,
  ),
  PredefinedPrinter(
    key: 'bambulab_a1_mini_combo',
    displayName: 'BAMBULAB A1 MINI COMBO',
    printerName: 'Bambulab A1 Mini Combo',
    maxCount: 6,
    isUnique: false,
  ),
  PredefinedPrinter(
    key: 'bambu_lab_h2c',
    displayName: 'BAMBU LAB H2C',
    printerName: 'Bambu Lab H2C',
    maxCount: 2,
    isUnique: false,
  ),
  PredefinedPrinter(
    key: 'custom',
    displayName: '+ Nueva impresora / Otra',
    printerName: '',
    maxCount: 100,
    isUnique: false,
  ),
];

class _PrinterFormEntry {
  String? selectedKey;
  Set<int> selectedUnits;
  final TextEditingController customNameController;
  final TextEditingController customCountController;

  _PrinterFormEntry({
    this.selectedKey,
    Set<int>? selectedUnits,
    String customName = '',
    String customCount = '1',
  })  : selectedUnits = selectedUnits ?? {1},
        customNameController = TextEditingController(text: customName),
        customCountController = TextEditingController(text: customCount);

  void dispose() {
    customNameController.dispose();
    customCountController.dispose();
  }

  bool get isConfigured {
    if (selectedKey == null) return false;
    if (selectedKey == 'custom') {
      return customNameController.text.trim().isNotEmpty;
    }
    return true;
  }
}

class _FormState extends State<PrintFormScreen> {
  late final InventoryViewModel inventoryVm;
  bool _ownsInvVm = false;
  late TextEditingController name, notes, customCategory;
  late TextEditingController qtyController;
  late List<_PrinterFormEntry> printerEntries;
  int cantidad = 1;
  bool _hasMaterialCombination = false;
  String? category;
  DateTime selectedDate = DateTime.now();
  final categories = [
    'Pieza Funcional',
    'Arte / Decorativo',
    'Prototipo',
    'Repuesto',
    'Miniatura',
    'Otro'
  ];
  final types = [
    'PLA',
    'PETG',
    'ABS',
    'TPU',
    'ASA',
    'Nylon',
    'Carbon Fiber',
    'Resina',
    'Otro'
  ];
  late List<_MaterialForm> materials;
  bool _saving = false;

  Set<int> _parseUnitsFromName(String name, int count, int maxCount) {
    final regExp = RegExp(r'#(\d+)');
    final matches = regExp.allMatches(name);
    final units = <int>{};
    for (final m in matches) {
      final u = int.tryParse(m.group(1) ?? '');
      if (u != null && u >= 1 && u <= maxCount) {
        units.add(u);
      }
    }
    if (units.isNotEmpty) return units;
    final safeCount = count.clamp(1, maxCount);
    return List.generate(safeCount, (i) => i + 1).toSet();
  }

  List<_PrinterFormEntry> _parsePrintersFromRecord(
      String? recordPrinterName, int recordPrinterCount) {
    if (recordPrinterName == null || recordPrinterName.trim().isEmpty) {
      return [_PrinterFormEntry()];
    }
    final parts = recordPrinterName.split(' + ');
    final entries = <_PrinterFormEntry>[];
    for (final part in parts) {
      final cleanPart = part.trim();
      if (cleanPart.isEmpty) continue;
      final lower = cleanPart.toLowerCase();
      final match = predefinedPrinters.firstWhere(
        (p) =>
            p.key != 'custom' &&
            (p.printerName.toLowerCase() == lower ||
                cleanPart.toLowerCase().contains(p.printerName.toLowerCase()) ||
                p.displayName.toLowerCase().contains(lower)),
        orElse: () => const PredefinedPrinter(
          key: 'custom',
          displayName: '+ Nueva impresora / Otra',
          printerName: '',
          maxCount: 100,
        ),
      );
      if (match.key != 'custom') {
        final units = _parseUnitsFromName(cleanPart, 1, match.maxCount);
        entries.add(_PrinterFormEntry(
          selectedKey: match.key,
          selectedUnits: units,
        ));
      } else {
        entries.add(_PrinterFormEntry(
          selectedKey: 'custom',
          customName: cleanPart,
          customCount: '1',
        ));
      }
    }
    return entries.isNotEmpty ? entries : [_PrinterFormEntry()];
  }

  String requesterType = 'Estudiante';
  late TextEditingController requesterNameController;
  late TextEditingController requesterIdController;
  late TextEditingController customRequesterTypeController;
  late TextEditingController printHoursController;
  late TextEditingController printMinutesController;
  late TextEditingController projectNameController;

  List<String> getSelectedPrinterList() {
    final list = <String>[];
    for (final entry in printerEntries) {
      if (entry.selectedKey == null) continue;
      if (entry.selectedKey == 'custom') {
        final customName = entry.customNameController.text.trim();
        if (customName.isEmpty) continue;
        final count = int.tryParse(entry.customCountController.text) ?? 1;
        final safeCount = count.clamp(1, 100);
        if (safeCount == 1) {
          list.add(customName);
        } else {
          for (int i = 1; i <= safeCount; i++) {
            list.add('$customName (#$i)');
          }
        }
      } else {
        final p = predefinedPrinters.firstWhere(
          (x) => x.key == entry.selectedKey,
          orElse: () => const PredefinedPrinter(
            key: '',
            displayName: '',
            printerName: '',
          ),
        );
        if (p.printerName.isEmpty) continue;
        if (p.isUnique) {
          list.add(p.printerName);
        } else {
          final sortedUnits = entry.selectedUnits.toList()..sort();
          if (sortedUnits.isEmpty) {
            list.add(p.printerName);
          } else {
            for (final u in sortedUnits) {
              list.add('${p.printerName} (Impresora #$u)');
            }
          }
        }
      }
    }
    return list;
  }

  @override
  void initState() {
    super.initState();
    if (widget.inventoryVm != null) {
      inventoryVm = widget.inventoryVm!;
    } else {
      inventoryVm = InventoryViewModel(AppDatabase());
      _ownsInvVm = true;
    }

    final r = widget.record;
    _hasMaterialCombination = r?.hasMaterialCombination ?? false;
    name = TextEditingController(text: r?.pieceType ?? '');
    projectNameController = TextEditingController(text: r?.projectName ?? '');
    notes = TextEditingController(text: r?.notes ?? '');
    printerEntries =
        _parsePrintersFromRecord(r?.printerName, r?.printerCount ?? 1);

    cantidad = r?.cantidad ?? 1;
    if (cantidad < 1) cantidad = 1;
    qtyController = TextEditingController(text: '$cantidad');

    final savedReqType = r?.requesterType;
    if (savedReqType == 'Docente' || savedReqType == 'Otro' || savedReqType == 'Estudiante') {
      requesterType = savedReqType!;
    } else if (savedReqType != null && savedReqType.isNotEmpty) {
      requesterType = 'Otro';
    } else {
      requesterType = 'Estudiante';
    }
    requesterNameController =
        TextEditingController(text: r?.requesterName ?? '');
    requesterIdController = TextEditingController(text: r?.requesterId ?? '');
    customRequesterTypeController = TextEditingController(
      text: r?.customRequesterType ??
          (savedReqType != null &&
                  !['Estudiante', 'Docente'].contains(savedReqType)
              ? savedReqType
              : ''),
    );

    int initH = 0;
    int initM = 0;
    if (r?.printTime != null && r!.printTime!.isNotEmpty) {
      final hMatch =
          RegExp(r'(\d+)\s*h', caseSensitive: false).firstMatch(r.printTime!);
      final mMatch =
          RegExp(r'(\d+)\s*m', caseSensitive: false).firstMatch(r.printTime!);
      if (hMatch != null) initH = int.tryParse(hMatch.group(1) ?? '0') ?? 0;
      if (mMatch != null) initM = int.tryParse(mMatch.group(1) ?? '0') ?? 0;
      if (hMatch == null && mMatch == null) {
        initM =
            int.tryParse(r.printTime!.replaceAll(RegExp(r'\D'), '')) ?? 0;
      }
    }
    printHoursController =
        TextEditingController(text: initH > 0 ? '$initH' : '');
    printMinutesController =
        TextEditingController(text: initM > 0 ? '$initM' : '');

    if (r != null) {
      final savedCategory = r.figureCategory;
      if (categories.contains(savedCategory)) {
        category = savedCategory;
      } else {
        category = 'Otro';
      }
      customCategory =
          TextEditingController(text: category == 'Otro' ? savedCategory : '');
    } else {
      category = null;
      customCategory = TextEditingController();
    }

    selectedDate = r == null
        ? DateTime.now()
        : DateTime.fromMillisecondsSinceEpoch(r.date);
    materials = r?.materials
            .map((m) => _MaterialForm(
                types.contains(m.type) ? m.type : 'Otro',
                m.grams == 0 ? '' : '${m.grams}',
                m.color,
                m.colorName ?? '',
                m.combine,
                customType: types.contains(m.type) ? '' : m.type))
            .toList() ??
        [
          _MaterialForm('PLA', '', null, '', true),
        ];
  }

  @override
  void dispose() {
    name.dispose();
    projectNameController.dispose();
    notes.dispose();
    customCategory.dispose();
    qtyController.dispose();
    requesterNameController.dispose();
    requesterIdController.dispose();
    customRequesterTypeController.dispose();
    printHoursController.dispose();
    printMinutesController.dispose();
    for (final entry in printerEntries) {
      entry.dispose();
    }
    for (final material in materials) {
      material.dispose();
    }
    if (_ownsInvVm) inventoryVm.dispose();
    super.dispose();
  }

  Widget _buildRequesterPanel() => formCard(
        title: 'Datos del Solicitante',
        subtitle:
            'Identificación institucional de quien solicita el servicio de impresión',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Quién solicitó la impresión? *',
              style: TextStyle(
                color: textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                _buildRequesterTypeChip('Estudiante', Icons.school_outlined),
                _buildRequesterTypeChip('Docente', Icons.badge_outlined),
                _buildRequesterTypeChip('Otro', Icons.person_outline),
              ],
            ),
            if (requesterType == 'Otro') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: 340,
                child: TextField(
                  controller: customRequesterTypeController,
                  style: TextStyle(color: textPrimary, fontSize: 13),
                  decoration: fieldDecoration(
                    'Especificar tipo de solicitante *',
                    hint: 'Ej: Investigador / Administrativo / Externo',
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 560;
                final fieldWidth = isWide
                    ? (constraints.maxWidth - 16) / 2
                    : constraints.maxWidth;
                final nameFieldWidth = isWide
                    ? (fieldWidth * 0.5)
                    : constraints.maxWidth;
                final idFieldWidth = isWide
                    ? (fieldWidth * 0.25).clamp(120.0, fieldWidth)
                    : constraints.maxWidth;
                final idLabel = requesterType == 'Estudiante'
                    ? 'No. de Control *'
                    : (requesterType == 'Docente'
                        ? 'No. de Empleado *'
                        : 'No. de Identificación / Rol *');
                final idHint = requesterType == 'Estudiante'
                    ? 'Ej: 21120456'
                    : (requesterType == 'Docente'
                        ? 'Ej: DOC-4091'
                        : 'Ej: EXT-012');
                final idIcon = requesterType == 'Estudiante'
                    ? Icons.pin_outlined
                    : (requesterType == 'Docente'
                        ? Icons.badge_outlined
                        : Icons.credit_card_outlined);

                return Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: nameFieldWidth,
                      child: TextField(
                        controller: requesterNameController,
                        style: TextStyle(color: textPrimary, fontSize: 13),
                        decoration: fieldDecoration(
                          'Nombre del solicitante *',
                          hint: 'Ej: Juan Pérez Morales',
                          prefix: const Icon(Icons.person_outline,
                              size: 18, color: accentPetrol),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: idFieldWidth,
                      child: TextField(
                        controller: requesterIdController,
                        style: TextStyle(color: textPrimary, fontSize: 13),
                        decoration: fieldDecoration(
                          idLabel,
                          hint: idHint,
                          prefix: Icon(idIcon, size: 18, color: accentPetrol),
                        ).copyWith(
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      );

  Widget _buildRequesterTypeChip(String type, IconData icon) {
    final isSelected = requesterType == type;
    return InkWell(
      onTap: () => setState(() => requesterType = type),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? accentPetrol.withValues(alpha: 0.15)
              : surfaceElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? accentPetrol : borderSubtle,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? accentPetrol : textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              type,
              style: TextStyle(
                color: isSelected ? textPrimary : textSecondary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              const Icon(Icons.check, size: 14, color: accentPetrol),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPrintTimeInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tiempo total de impresión',
          style: TextStyle(
            color: textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: surfaceElevated,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderSubtle),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.schedule, size: 16, color: accentPetrol),
              const SizedBox(width: 8),
              SizedBox(
                width: 36,
                child: TextField(
                  controller: printHoursController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3),
                  ],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: const InputDecoration(
                    hintText: '0',
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                  ),
                ),
              ),
              Text(' h  ',
                  style: TextStyle(
                      color: textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              Container(width: 1, height: 18, color: borderSubtle),
              const SizedBox(width: 8),
              SizedBox(
                width: 36,
                child: TextField(
                  key: const ValueKey('print_minutes_field'),
                  controller: printMinutesController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(2),
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      if (newValue.text.isEmpty) return newValue;
                      final m = int.tryParse(newValue.text);
                      if (m != null && m > 60) {
                        return const TextEditingValue(
                          text: '60',
                          selection: TextSelection.collapsed(offset: 2),
                        );
                      }
                      return newValue;
                    }),
                  ],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: const InputDecoration(
                    hintText: '0',
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                  ),
                  onChanged: (val) {
                    final m = int.tryParse(val);
                    if (m != null && m > 60) {
                      printMinutesController.text = '60';
                      printMinutesController.selection =
                          const TextSelection.collapsed(offset: 2);
                    }
                    setState(() {});
                  },
                ),
              ),
              Text(' min',
                  style: TextStyle(
                      color: textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrinterInfoPanel() => formCard(
        title: 'Datos de la impresora',
        subtitle: 'Identifica la impresora o impresoras utilizadas',
        child: LayoutBuilder(
          builder: (context, constraints) {
            final fitsInRow = constraints.maxWidth >= 520;
            final dropdownWidth = fitsInRow
                ? (constraints.maxWidth * 0.58).clamp(240.0, 380.0)
                : constraints.maxWidth;
            final countWidth = fitsInRow ? 204.0 : constraints.maxWidth;

            final allConfigured = printerEntries.isNotEmpty &&
                printerEntries.every((e) => e.isConfigured);

            return Column(
              key: const ValueKey('printer_info_panel'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...List.generate(printerEntries.length, (entryIndex) {
                  final entry = printerEntries[entryIndex];
                  final selectedPrinter = predefinedPrinters.firstWhere(
                    (p) => p.key == entry.selectedKey,
                    orElse: () => const PredefinedPrinter(
                      key: '',
                      displayName: '',
                      printerName: '',
                      maxCount: 1,
                    ),
                  );

                  return Padding(
                    padding: EdgeInsets.only(
                      bottom:
                          entryIndex < printerEntries.length - 1 ? 16.0 : 0.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: dropdownWidth,
                              child: DropdownButtonFormField<String>(
                                key: entryIndex == 0
                                    ? const ValueKey('printer_select_dropdown')
                                    : ValueKey(
                                        'printer_select_dropdown_$entryIndex'),
                                value: entry.selectedKey,
                                isExpanded: true,
                                dropdownColor: surfaceElevated,
                                style:
                                    TextStyle(color: textPrimary, fontSize: 13),
                                iconEnabledColor: textSecondary,
                                hint: Text(
                                  printerEntries.length > 1
                                      ? 'Selecciona otra impresora *'
                                      : 'Selecciona una impresora *',
                                  style: TextStyle(
                                      color: textMuted, fontSize: 13),
                                ),
                                decoration: fieldDecoration(
                                  printerEntries.length > 1
                                      ? 'Impresora ${entryIndex + 1} *'
                                      : 'Impresora *',
                                ),
                                items: predefinedPrinters
                                    .map((p) => DropdownMenuItem(
                                          value: p.key,
                                          child: Text(
                                            p.displayName,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ))
                                    .toList(),
                                onChanged: (val) {
                                  setState(() {
                                    entry.selectedKey = val;
                                    entry.selectedUnits = {1};
                                  });
                                },
                              ),
                            ),
                            if (printerEntries.length > 1) ...[
                              const SizedBox(width: 8),
                              IconButton(
                                key: ValueKey('remove_printer_$entryIndex'),
                                tooltip: 'Eliminar impresora',
                                icon: Icon(
                                  Icons.delete_outline,
                                  size: 20,
                                  color: semanticDanger.withOpacity(0.85),
                                ),
                                onPressed: () {
                                  setState(() {
                                    final removed =
                                        printerEntries.removeAt(entryIndex);
                                    removed.dispose();
                                  });
                                },
                              ),
                            ],
                          ],
                        ),
                        if (entry.selectedKey != null &&
                            entry.selectedKey != 'custom' &&
                            !selectedPrinter.isUnique) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: List.generate(
                              selectedPrinter.maxCount,
                              (index) {
                                final unitNumber = index + 1;
                                final isSelected =
                                    entry.selectedUnits.contains(unitNumber);
                                return InkWell(
                                  key: ValueKey(
                                      'printer_unit_chip_${entryIndex}_$unitNumber'),
                                  borderRadius: BorderRadius.circular(8),
                                  onTap: () {
                                    setState(() {
                                      if (isSelected) {
                                        if (entry.selectedUnits.length > 1) {
                                          entry.selectedUnits
                                              .remove(unitNumber);
                                        }
                                      } else {
                                        entry.selectedUnits.add(unitNumber);
                                      }
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? accentPetrol
                                          : surfaceElevated,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isSelected
                                            ? accentPetrol
                                            : borderSubtle,
                                        width: isSelected ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isSelected
                                              ? Icons.check_box
                                              : Icons.check_box_outline_blank,
                                          size: 15,
                                          color: isSelected
                                              ? Colors.white
                                              : textSecondary,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Impresora $unitNumber',
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : textPrimary,
                                            fontSize: 12,
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                        if (entry.selectedKey == 'custom') ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              SizedBox(
                                width: dropdownWidth,
                                child: TextField(
                                  key: ValueKey('printer_name_field_$entryIndex'),
                                  controller: entry.customNameController,
                                  textCapitalization: TextCapitalization.words,
                                  style: TextStyle(
                                      color: textPrimary, fontSize: 13),
                                  decoration: fieldDecoration(
                                    'Nombre de la nueva impresora *',
                                    hint: 'Ej: Prusa MK4',
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              SizedBox(
                                width: countWidth,
                                child: TextField(
                                  key: ValueKey(
                                      'printer_count_field_$entryIndex'),
                                  controller: entry.customCountController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    TextInputFormatter.withFunction(
                                        (oldValue, newValue) {
                                      if (newValue.text.isEmpty) {
                                        return newValue;
                                      }
                                      final count = int.tryParse(newValue.text);
                                      return count != null &&
                                              count >= 1 &&
                                              count <= 100
                                          ? newValue
                                          : oldValue;
                                    }),
                                  ],
                                  style: TextStyle(
                                      color: textPrimary, fontSize: 13),
                                  decoration: fieldDecoration(
                                    'Número de impresoras *',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                }),
                if (allConfigured) ...[
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    key: const ValueKey('add_printer_button'),
                    onPressed: () {
                      setState(() {
                        printerEntries.add(_PrinterFormEntry());
                      });
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text(
                      'AGREGAR OTRA IMPRESORA',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: accentPetrol,
                      side: const BorderSide(color: accentPetrol),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      );


  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: inventoryVm,
        builder: (context, _) => Scaffold(
          appBar: darkAppBar(
            widget.record == null
                ? 'REGISTRO DE IMPRESIÓN'
                : 'EDITAR IMPRESIÓN',
            () => goBack(context),
          ),
          backgroundColor: bgBase,
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: double.infinity),
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                children: [
                  _buildRequesterPanel(),
                  const SizedBox(height: 16),
                  _buildPrinterInfoPanel(),
                  const SizedBox(height: 16),
                  formCard(
                    title: 'Información de la Pieza',
                    subtitle:
                        'Datos del proyecto, archivo 3D y tiempo de impresión',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nombre del proyecto
                        LayoutBuilder(
                          builder: (context, constraints) => SizedBox(
                            width: constraints.maxWidth > 500
                                ? constraints.maxWidth * 0.65
                                : double.infinity,
                            child: TextField(
                              key: const ValueKey('print_project_name_field'),
                              controller: projectNameController,
                              style:
                                  TextStyle(color: textPrimary, fontSize: 13),
                              decoration: fieldDecoration(
                                'Nombre del proyecto *',
                                hint: 'Ej: Brazo robótico SILM / Tesis Manufactura 2026',
                                prefix: const Icon(Icons.folder_open_outlined,
                                    size: 18, color: accentPetrol),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Nombre del archivo 3D
                        LayoutBuilder(
                          builder: (context, constraints) => SizedBox(
                            width: constraints.maxWidth > 500
                                ? constraints.maxWidth * 0.65
                                : double.infinity,
                            child: TextField(
                              key: const ValueKey('print_piece_name_field'),
                              controller: name,
                              style:
                                  TextStyle(color: textPrimary, fontSize: 13),
                              decoration: fieldDecoration(
                                'Nombre del archivo *',
                                hint: 'Ej: soporte_engrane_v2.stl / pinza_robotica.gcode',
                                prefix: const Icon(Icons.insert_drive_file_outlined,
                                    size: 18, color: accentPetrol),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Categoría a la medida de la opción más larga ("Arte / Decorativo")
                        SizedBox(
                          width: 230,
                          child: DropdownButtonFormField<String>(
                            initialValue: category,
                            isExpanded: true,
                            dropdownColor: surfaceElevated,
                            style: TextStyle(color: textPrimary, fontSize: 13),
                            iconEnabledColor: textSecondary,
                            hint: Text('Selecciona una categoría *',
                                style:
                                    TextStyle(color: textMuted, fontSize: 13)),
                            decoration: fieldDecoration('Categoría *'),
                            items: categories
                                .map((x) =>
                                    DropdownMenuItem(value: x, child: Text(x)))
                                .toList(),
                            onChanged: (x) => setState(() => category = x),
                          ),
                        ),
                        if (category == 'Otro') ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: 230,
                            child: TextField(
                              controller: customCategory,
                              style:
                                  TextStyle(color: textPrimary, fontSize: 13),
                              decoration:
                                  fieldDecoration('Categoría personalizada *'),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        // Fecha de fabricación a medida
                        SizedBox(
                          width: 230,
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                                initialDate: selectedDate,
                                builder: (context, child) => Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.dark(
                                      primary: accentPetrol,
                                      onPrimary: textPrimary,
                                      surface: surfaceCard,
                                      onSurface: textPrimary,
                                    ),
                                  ),
                                  child: child!,
                                ),
                              );
                              if (!mounted || picked == null) return;
                              setState(() => selectedDate = picked);
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: surfaceElevated,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: borderSubtle),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today_outlined,
                                      size: 16, color: accentPetrol),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Fecha de fabricación',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: textSecondary,
                                            fontSize: 10,
                                          ),
                                        ),
                                        Text(
                                          dateText(selectedDate
                                              .millisecondsSinceEpoch),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: textPrimary,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(Icons.edit_calendar_outlined,
                                      size: 16, color: textSecondary),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Tiempo total de impresión (sin campo de cantidad de piezas)
                        _buildPrintTimeInput(),
                        const SizedBox(height: 12),

                        // Resumen en vivo contenido a medida
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 500),
                          child: _buildLiveConsumptionSummary(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  formCard(
                    title: 'Materiales Utilizados',
                    subtitle:
                        'Gramos consumidos POR UNIDAD de pieza individual',
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Combinación de material',
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Checkbox(
                          key: const ValueKey('material_combination_toggle'),
                          value: _hasMaterialCombination,
                          shape: const CircleBorder(),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          activeColor: accentPetrol,
                          onChanged: (value) => setState(
                            () => _hasMaterialCombination = value ?? false,
                          ),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ...materials.asMap().entries.map(
                              (entry) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _materialCard(entry.key, entry.value),
                              ),
                            ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            onPressed: () => setState(() => materials.add(
                                  _MaterialForm('PLA', '', null, '', true),
                                )),
                            icon: const Icon(Icons.add,
                                size: 16, color: accentPetrol),
                            label: const Text(
                              'AGREGAR OTRO MATERIAL',
                              style: TextStyle(
                                color: accentPetrol,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              side: const BorderSide(
                                  color: accentPetrol, width: 1.2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              backgroundColor: surfaceElevated,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_hasMaterialCombination) ...[
                    _buildMaterialCombinationCard(),
                    const SizedBox(height: 16),
                  ],
                  formCard(
                    title: 'Comentarios y Observaciones',
                    subtitle: 'Notas adicionales sobre la impresión o incidencias',
                    child: TextField(
                      controller: notes,
                      minLines: 2,
                      maxLines: 4,
                      style: TextStyle(color: textPrimary, fontSize: 13),
                      decoration: fieldDecoration('Comentarios / Observaciones',
                          hint: 'Notas sobre el acabado, tolerancias, propósito o incidencias'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  techButton(
                    'GUARDAR REGISTRO',
                    _save,
                    icon: Icons.save_outlined,
                    height: 46,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      );



  Widget _buildLiveConsumptionSummary() {
    final printerList = getSelectedPrinterList();
    final printerCount = printerList.isEmpty ? 1 : printerList.length;
    final unitGrams = materials.fold(
        0.0, (s, m) => s + (double.tryParse(m.grams.text) ?? 0.0));
    final totalGrams = unitGrams * printerCount;

    if (unitGrams <= 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: surfaceElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderSubtle),
        ),
        child: Row(
          children: [
            Icon(Icons.scale_outlined, size: 16, color: textMuted),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Ingresa los gramos de material para calcular el consumo total',
                style: TextStyle(color: textMuted, fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    final String originText;
    if (printerCount > 1) {
      if (materials.length > 1) {
        originText =
            'Origen: ${unitGrams.toStringAsFixed(1)} g por impresión (${materials.length} materiales) × $printerCount impresoras';
      } else {
        originText =
            'Origen: ${unitGrams.toStringAsFixed(1)} g por impresión × $printerCount impresoras';
      }
    } else {
      if (materials.length > 1) {
        originText =
            'Origen: ${unitGrams.toStringAsFixed(1)} g sumando ${materials.length} materiales para 1 impresión';
      } else {
        originText = 'Origen: peso unitario de 1 impresión';
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accentPetrol.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: accentPetrol.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child:
                const Icon(Icons.scale_outlined, size: 16, color: accentPetrol),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      printerCount > 1
                          ? 'Consumo total ($printerCount impresoras): '
                          : 'Consumo total: ',
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${totalGrams.toStringAsFixed(1)} g',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  originText,
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialCombinationCard() {
    final printerList = getSelectedPrinterList();
    final printerCount = printerList.isEmpty ? 1 : printerList.length;
    final unitGrams = materials.fold(
      0.0,
      (sum, material) => sum + (double.tryParse(material.grams.text) ?? 0.0),
    );
    final totalBatchGrams = unitGrams * printerCount;
    final rows = materials.map((material) {
      final materialName =
          material.type == 'Otro' ? material.customType.trim() : material.type;
      final grams = double.tryParse(material.grams.text) ?? 0.0;
      return TableRow(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            child: Text(
              materialName.isEmpty ? 'Sin especificar' : materialName,
              style: TextStyle(color: textPrimary, fontSize: 12),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            child: Row(
              children: [
                if (material.color != null)
                  colorSwatchCircle(Color(material.color!), size: 12)
                else
                  Icon(Icons.circle_outlined, size: 12, color: textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    material.colorName.isEmpty
                        ? 'Sin seleccionar'
                        : material.colorName,
                    style: TextStyle(
                      color:
                          material.colorName.isEmpty ? textMuted : textPrimary,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            child: Text(
              '${grams.toStringAsFixed(1)} g',
              textAlign: TextAlign.right,
              style: TextStyle(color: textPrimary, fontSize: 12),
            ),
          ),
        ],
      );
    }).toList();

    return KeyedSubtree(
      key: const ValueKey('material_combination_card'),
      child: formCard(
        title: 'Combinación de material y colores',
        subtitle: 'Materiales, colores y gramos consumidos',
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(1),
            1: FlexColumnWidth(1.5),
            2: FlexColumnWidth(0.9),
          },
          border: TableBorder(
            horizontalInside: BorderSide(color: borderSubtle),
            bottom: BorderSide(color: borderSubtle),
          ),
          children: [
            TableRow(
              decoration: BoxDecoration(color: surfaceElevated),
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  child: Text(
                    'MATERIAL',
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  child: Text(
                    'COLOR',
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  child: Text(
                    'GRAMOS',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            ...rows,
            TableRow(
              decoration: BoxDecoration(
                color: accentPetrol.withValues(alpha: 0.08),
              ),
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  child: Text(
                    'TOTAL USADO',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  child: Text(
                    printerCount == 1 ? '1 impresión' : '$printerCount impresoras',
                    style: TextStyle(color: textSecondary, fontSize: 11),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${unitGrams.toStringAsFixed(1)} g / pieza',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: accentPetrol,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (printerCount > 1)
                        Text(
                          'Total: ${totalBatchGrams.toStringAsFixed(1)} g',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _materialCard(int index, _MaterialForm m) {
    final effectiveType = m.type == 'Otro' ? m.customType : m.type;
    final enteredUnitGrams = double.tryParse(m.grams.text) ?? 0.0;
    final printerList = getSelectedPrinterList();
    final printerCount = printerList.isEmpty ? 1 : printerList.length;
    final totalBatchGrams = enteredUnitGrams * printerCount;
    final currentStock = inventoryVm.getAvailableStock(
      effectiveType,
      colorName: m.colorName.isEmpty ? null : m.colorName,
      colorValue: m.color,
    );
    final isOverStock = totalBatchGrams > currentStock && currentStock > 0;
    final isStandardColor =
        m.color != null && voxelColorPalette.any((c) => c.value == m.color);

    int? dropdownColorValue;
    if (m.color == null && m.colorName.isEmpty) {
      dropdownColorValue = null;
    } else if (isStandardColor) {
      dropdownColorValue = m.color;
    } else {
      dropdownColorValue = -1;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'MATERIAL ${index + 1}',
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              const Spacer(),
              if (index > 0)
                InkWell(
                  onTap: () => setState(() => materials.removeAt(index)),
                  borderRadius: BorderRadius.circular(4),
                  child: const Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(Icons.close, size: 16, color: semanticDanger),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.start,
            children: [
              // Tipo de material a la medida de la opción más larga ("Carbon Fiber")
              SizedBox(
                width: 170,
                child: DropdownButtonFormField<String>(
                  key: ValueKey('type_${index}_${m.type}'),
                  initialValue: types.contains(m.type) ? m.type : 'Otro',
                  isExpanded: true,
                  dropdownColor: surfaceElevated,
                  style: TextStyle(color: textPrimary, fontSize: 13),
                  iconEnabledColor: textSecondary,
                  decoration: fieldDecoration('Tipo *'),
                  items: types
                      .map((x) => DropdownMenuItem(value: x, child: Text(x)))
                      .toList(),
                  onChanged: (x) => setState(() => m.type = x!),
                ),
              ),
              // Color a la medida de la opción más larga ("Personalizado...", "Transparente"), vacío por default
              SizedBox(
                width: 205,
                child: DropdownButtonFormField<int?>(
                  key: ValueKey('color_${index}_${m.color}_${m.colorName}'),
                  initialValue: dropdownColorValue,
                  isExpanded: true,
                  dropdownColor: surfaceElevated,
                  style: TextStyle(color: textPrimary, fontSize: 13),
                  iconEnabledColor: textSecondary,
                  hint: Text(
                    'Seleccionar...',
                    style: TextStyle(color: textMuted, fontSize: 13),
                  ),
                  decoration: fieldDecoration('Color *'),
                  items: [
                    ...voxelColorPalette.map((vc) => DropdownMenuItem<int?>(
                          value: vc.value,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              colorSwatchCircle(vc.color,
                                  size: 10, isTransparent: vc.isTransparent),
                              const SizedBox(width: 8),
                              Text(vc.name,
                                  style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        )),
                    DropdownMenuItem<int?>(
                      value: -1,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.palette_outlined,
                              size: 14, color: accentPetrol),
                          const SizedBox(width: 8),
                          Text(
                            !isStandardColor && m.colorName.isNotEmpty
                                ? m.colorName
                                : 'Personalizado...',
                            style: const TextStyle(
                              fontSize: 12,
                              color: accentPetrol,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (val) async {
                    if (val == -1) {
                      final picked = await showCustomColorDialog(
                        context,
                        initialColor: m.color != null
                            ? Color(m.color!)
                            : const Color(0xFF2563EB),
                        initialName: m.colorName,
                      );
                      if (mounted) {
                        if (picked != null) {
                          setState(() {
                            m.color = ((picked.color.a * 255).round() << 24) |
                                ((picked.color.r * 255).round() << 16) |
                                ((picked.color.g * 255).round() << 8) |
                                ((picked.color.b * 255).round());
                            m.colorName = picked.name;
                          });
                        } else {
                          setState(() {});
                        }
                      }
                    } else if (val != null) {
                      final selected =
                          voxelColorPalette.firstWhere((c) => c.value == val);
                      setState(() {
                        m.color = val;
                        m.colorName = selected.name;
                      });
                    }
                  },
                ),
              ),
              // Gramos c/u del tamaño para 4 caracteres
              SizedBox(
                width: 80,
                child: TextField(
                  key: ValueKey('material_grams_$index'),
                  controller: m.grams,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(4),
                  ],
                  textAlign: TextAlign.center,
                  style: TextStyle(color: textPrimary, fontSize: 13),
                  decoration: fieldDecoration('Gramos *', hint: '0').copyWith(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 12)),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          if (m.type == 'Otro') ...[
            const SizedBox(height: 10),
            SizedBox(
              width: 250,
              child: TextField(
                decoration:
                    fieldDecoration('Nombre del material personalizado *'),
                style: TextStyle(color: textPrimary, fontSize: 13),
                onChanged: (x) => setState(() => m.customType = x),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: bgBase.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isOverStock
                    ? semanticWarning.withValues(alpha: 0.6)
                    : borderSubtle.withValues(alpha: 0.6),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  currentStock > 0
                      ? Icons.inventory_2_outlined
                      : Icons.info_outline,
                  size: 13,
                  color: currentStock > 0
                      ? (currentStock <= 200 ? semanticWarning : textSecondary)
                      : textMuted,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    m.color == null && m.colorName.isEmpty
                        ? 'Selecciona un color para consultar el stock disponible'
                        : (printerCount > 1 && enteredUnitGrams > 0
                            ? 'Stock: ${currentStock.toStringAsFixed(1)} g · Total ($printerCount imp): ${totalBatchGrams.toStringAsFixed(1)} g (${enteredUnitGrams.toStringAsFixed(1)}g × $printerCount)'
                            : 'Stock disponible: ${currentStock.toStringAsFixed(1)} g'),
                    style: TextStyle(
                      color: currentStock > 0
                          ? (currentStock <= 200
                              ? semanticWarning
                              : textSecondary)
                          : textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isOverStock) ...[
                  const SizedBox(width: 6),
                  Text(
                    '¡Supera en ${(totalBatchGrams - currentStock).toStringAsFixed(1)}g!',
                    style: const TextStyle(
                      color: semanticWarning,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_saving) return;
    final reqName = requesterNameController.text.trim();
    if (reqName.isEmpty) {
      toast(context, 'Falta el nombre de quien solicitó la impresión',
          isError: true);
      return;
    }
    if (requesterType == 'Otro' &&
        customRequesterTypeController.text.trim().isEmpty) {
      toast(context, 'Especifica el tipo de solicitante', isError: true);
      return;
    }
    final reqId = requesterIdController.text.trim();
    if (reqId.isEmpty) {
      if (requesterType == 'Estudiante') {
        toast(context, 'Falta el No. de Control del estudiante', isError: true);
      } else if (requesterType == 'Docente') {
        toast(context, 'Falta el No. de Empleado del docente', isError: true);
      } else {
        toast(context, 'Falta el número de identificación del solicitante',
            isError: true);
      }
      return;
    }
    final projName = projectNameController.text.trim();
    if (projName.isEmpty) {
      toast(context, 'Falta el nombre del proyecto', isError: true);
      return;
    }
    final fileName = name.text.trim();
    if (fileName.isEmpty) {
      toast(context, 'Falta el nombre del archivo', isError: true);
      return;
    }
    final h = int.tryParse(printHoursController.text.trim()) ?? 0;
    final m = int.tryParse(printMinutesController.text.trim()) ?? 0;
    if (m > 60) {
      toast(context, 'Los minutos no pueden ser mayores a 60', isError: true);
      return;
    }
    String? formattedPrintTime;
    if (h > 0 || m > 0) {
      if (h > 0 && m > 0) {
        formattedPrintTime = '${h}h ${m}m';
      } else if (h > 0) {
        formattedPrintTime = '${h}h';
      } else {
        formattedPrintTime = '${m}m';
      }
    }

    for (int i = 0; i < printerEntries.length; i++) {
      final entry = printerEntries[i];
      if (entry.selectedKey == null) {
        toast(
          context,
          printerEntries.length > 1
              ? 'Selecciona la impresora #${i + 1}'
              : 'Selecciona una impresora',
          isError: true,
        );
        return;
      }
      if (entry.selectedKey == 'custom') {
        final customName = entry.customNameController.text.trim();
        if (customName.isEmpty) {
          toast(context, 'Falta el nombre de la nueva impresora',
              isError: true);
          return;
        }
      }
    }

    final printerList = getSelectedPrinterList();
    if (printerList.isEmpty) {
      toast(context, 'Selecciona al menos una impresora', isError: true);
      return;
    }

    if (category == null || category!.isEmpty) {
      toast(context, 'Selecciona una categoría para la pieza', isError: true);
      return;
    }
    final finalCategory =
        category == 'Otro' ? customCategory.text.trim() : category!;
    if (finalCategory.isEmpty) {
      toast(context, 'Especifica la categoría personalizada', isError: true);
      return;
    }

    final totalPrinters = printerList.length;
    final result = <MaterialData>[];
    bool hasOverStock = false;
    final overStockDetails = <String>[];

    for (final m in materials) {
      final type = m.type == 'Otro' ? m.customType : m.type;
      if (type.trim().isEmpty) {
        toast(context, 'Falta especificar el tipo de material', isError: true);
        return;
      }
      if (m.color == null && m.colorName.isEmpty) {
        toast(context, 'Falta seleccionar el color para el material $type',
            isError: true);
        return;
      }
      final g = double.tryParse(m.grams.text) ?? 0;
      if (g <= 0) {
        toast(
          context,
          'Ingresa los gramos consumidos por impresión para $type (debe ser mayor a 0)',
          isError: true,
        );
        return;
      }
      final avail = inventoryVm.getAvailableStock(
        type,
        colorName: m.colorName.isEmpty ? null : m.colorName,
        colorValue: m.color,
      );
      final totalBatch = g * (widget.record != null ? 1 : totalPrinters);
      if (totalBatch > avail && avail > 0) {
        hasOverStock = true;
        overStockDetails.add(
            '$type (${m.colorName.isNotEmpty ? m.colorName : 'Color'}): requiere ${totalBatch.toStringAsFixed(1)}g ($g g × $totalPrinters ${totalPrinters == 1 ? 'impresora' : 'impresoras'}) pero solo hay ${avail.toStringAsFixed(1)}g en inventario');
      }

      result.add(MaterialData(
        type: type,
        grams: g,
        color: m.color ?? 0xFF808080,
        colorName: m.colorName.isEmpty ? null : m.colorName,
        combine: m.combine,
      ));
    }

    if (hasOverStock) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (dlgCtx) => AlertDialog(
          backgroundColor: surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: borderSubtle),
          ),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: semanticWarning, size: 22),
              const SizedBox(width: 8),
              Text(
                'Stock insuficiente',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Los gramos requeridos superan el stock en inventario:',
                style: TextStyle(color: textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 8),
              ...overStockDetails.map((det) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text('• $det',
                        style: const TextStyle(
                            color: semanticWarning,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  )),
              const SizedBox(height: 12),
              Text('¿Deseas guardar de todos modos?',
                  style: TextStyle(color: textPrimary, fontSize: 13)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dlgCtx, false),
              child: Text('Cancelar', style: TextStyle(color: textSecondary)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dlgCtx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentPetrol,
                foregroundColor: textPrimary,
              ),
              child: const Text('Continuar y Guardar'),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }

    setState(() => _saving = true);
    try {
      if (widget.record != null) {
        // En modo edición: restituir primero el consumo anterior
        final oldQty = widget.record!.cantidad;
        for (final oldM in widget.record!.materials) {
          await inventoryVm.restoreGrams(
            oldM.type,
            oldM.grams * oldQty,
            colorName: oldM.colorName,
            colorValue: oldM.color,
          );
        }

        // Descontar nuevo consumo (1 registro en edición)
        bool hasLowStockAlert = false;
        for (final newM in result) {
          final isLow = await inventoryVm.deductGrams(
            newM.type,
            newM.grams,
            colorName: newM.colorName,
            colorValue: newM.color,
          );
          if (isLow) hasLowStockAlert = true;
        }

        await widget.vm.saveRecord(PrintRecord(
          id: widget.record!.id,
          pieceType: fileName,
          projectName: projName,
          figureCategory: finalCategory,
          date: selectedDate.millisecondsSinceEpoch,
          materials: result,
          notes: notes.text.trim().isEmpty ? null : notes.text.trim(),
          printerName: printerList.first,
          printerCount: 1,
          hasMaterialCombination: _hasMaterialCombination,
          cantidad: 1,
          requesterType: requesterType,
          requesterName: reqName,
          requesterId: reqId,
          customRequesterType: requesterType == 'Otro'
              ? customRequesterTypeController.text.trim()
              : null,
          printTime: formattedPrintTime,
        ));

        if (!mounted) return;
        if (hasLowStockAlert) {
          toast(
            context,
            'Registro actualizado. ¡Alerta: filamento con stock bajo (≤ 20%)!',
            isError: true,
          );
        } else {
          toast(context, 'Registro de impresión actualizado correctamente');
        }
        Navigator.pop(context);
      } else {
        // Modo nuevo registro: si hay varias impresoras, se crean varios registros independientes
        bool hasLowStockAlert = false;
        for (final newM in result) {
          final isLow = await inventoryVm.deductGrams(
            newM.type,
            newM.grams * totalPrinters,
            colorName: newM.colorName,
            colorValue: newM.color,
          );
          if (isLow) hasLowStockAlert = true;
        }

        for (final singlePrinter in printerList) {
          await widget.vm.saveRecord(PrintRecord(
            id: 0,
            pieceType: fileName,
            projectName: projName,
            figureCategory: finalCategory,
            date: selectedDate.millisecondsSinceEpoch,
            materials: result,
            notes: notes.text.trim().isEmpty ? null : notes.text.trim(),
            printerName: singlePrinter,
            printerCount: 1,
            hasMaterialCombination: _hasMaterialCombination,
            cantidad: 1,
            requesterType: requesterType,
            requesterName: reqName,
            requesterId: reqId,
            customRequesterType: requesterType == 'Otro'
                ? customRequesterTypeController.text.trim()
                : null,
            printTime: formattedPrintTime,
          ));
        }

        if (!mounted) return;
        if (totalPrinters == 1) {
          if (hasLowStockAlert) {
            toast(
              context,
              'Registro guardado. ¡Alerta: filamento con stock bajo (≤ 20%)!',
              isError: true,
            );
          } else {
            toast(context, 'Registro de impresión guardado exitosamente');
          }
        } else {
          if (hasLowStockAlert) {
            toast(
              context,
              'Se generaron $totalPrinters registros de impresión (1 por impresora). ¡Alerta: filamento con stock bajo (≤ 20%)!',
              isError: true,
            );
          } else {
            toast(context,
                'Se generaron $totalPrinters registros de impresión independientes exitosamente');
          }
        }
        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _MaterialForm {
  String type, customType, colorName;
  final TextEditingController grams;
  int? color;
  bool combine;
  _MaterialForm(
    this.type,
    String gramsText,
    this.color,
    this.colorName,
    this.combine, {
    this.customType = '',
  }) : grams = TextEditingController(text: gramsText);
  void dispose() => grams.dispose();
}

// ==========================================
// 5. ANÁLISIS DE DATOS Y PRODUCCIÓN
// ==========================================
class AnalyticsScreen extends StatefulWidget {
  final VoidCallback? onToggleMenu;
  final VoidCallback? onHoverMenu;
  final bool isPinned;
  final PrintViewModel? vm;
  final InventoryViewModel? inventoryVm;
  const AnalyticsScreen({
    super.key,
    this.onToggleMenu,
    this.onHoverMenu,
    this.isPinned = false,
    this.vm,
    this.inventoryVm,
  });
  @override
  State<AnalyticsScreen> createState() => _AnalyticsState();
}

class _AnalyticsState extends State<AnalyticsScreen> {
  late final PrintViewModel vm;
  bool _ownsVm = false;

  String _selectedPeriod = '6M'; // '3M', '6M', 'AÑO', 'TODO'
  String? _selectedMonthKey; // ej. '2026-AGO'
  int _metricIndex = 0; // 0 = Gramos, 1 = Piezas
  int? _hoveredBarIndex;

  @override
  void initState() {
    super.initState();
    if (widget.vm != null) {
      vm = widget.vm!;
    } else {
      vm = PrintViewModel(AppDatabase());
      _ownsVm = true;
    }
  }

  @override
  void dispose() {
    if (_ownsVm) vm.dispose();
    super.dispose();
  }

  List<PrintRecord> _getFilteredRecords() {
    final all = vm.allRecords;
    if (all.isEmpty) return [];
    final now = DateTime.now();

    switch (_selectedPeriod) {
      case '3M':
        final threshold =
            DateTime(now.year, now.month - 2, 1).millisecondsSinceEpoch;
        return all.where((r) => r.date >= threshold).toList();
      case '6M':
        final threshold =
            DateTime(now.year, now.month - 5, 1).millisecondsSinceEpoch;
        return all.where((r) => r.date >= threshold).toList();
      case 'AÑO':
        final threshold = DateTime(now.year, 1, 1).millisecondsSinceEpoch;
        return all.where((r) => r.date >= threshold).toList();
      case 'TODO':
      default:
        return all;
    }
  }

  List<_MonthlyDataPoint> _getMonthlyPoints(List<PrintRecord> records) {
    final now = DateTime.now();
    DateTime start;
    DateTime end = DateTime(now.year, now.month, 1);

    if (records.isEmpty) {
      start = DateTime(now.year, now.month - 5, 1);
    } else {
      final sortedDates = records
          .map((r) => DateTime.fromMillisecondsSinceEpoch(r.date))
          .toList()
        ..sort();
      final earliest = sortedDates.first;
      final latest = sortedDates.last;
      start = DateTime(earliest.year, earliest.month, 1);
      final latestMonth = DateTime(latest.year, latest.month, 1);
      if (latestMonth.isAfter(end)) end = latestMonth;

      final monthDiff = (end.year - start.year) * 12 + end.month - start.month;
      if (_selectedPeriod == '3M' && monthDiff < 2) {
        start = DateTime(end.year, end.month - 2, 1);
      } else if (_selectedPeriod == '6M' && monthDiff < 5) {
        start = DateTime(end.year, end.month - 5, 1);
      } else if (_selectedPeriod == 'AÑO') {
        start = DateTime(now.year, 1, 1);
        end = DateTime(now.year, 12, 1);
      } else if (monthDiff < 5) {
        start = DateTime(end.year, end.month - 5, 1);
      }
    }

    final grouped = <String, List<PrintRecord>>{};
    for (final record in records) {
      final date = DateTime.fromMillisecondsSinceEpoch(record.date);
      final key = '${date.year}-${date.month}';
      grouped.putIfAbsent(key, () => []).add(record);
    }

    final points = <_MonthlyDataPoint>[];
    var cur = DateTime(start.year, start.month, 1);
    while (!cur.isAfter(end)) {
      final key = '${cur.year}-${cur.month}';
      final inMonth = grouped[key] ?? [];
      final grams = inMonth.fold(0.0, (s, r) => s + r.totalGrams);
      final pieces = inMonth.fold(0, (s, r) => s + r.cantidad);
      points.add(_MonthlyDataPoint(
        label: _monthShort(cur.month),
        year: cur.year,
        grams: grams,
        pieces: pieces,
      ));
      cur = DateTime(cur.year, cur.month + 1, 1);
    }
    return points;
  }

  static String _monthShort(int month) => const [
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

  @override
  Widget build(BuildContext context) {
    final listenables = <Listenable>[vm];
    if (widget.inventoryVm != null) {
      listenables.add(widget.inventoryVm!);
    }
    return AnimatedBuilder(
      animation: Listenable.merge(listenables),
      builder: (_, __) {
        final periodRecords = _getFilteredRecords();
        final monthlyPoints = _getMonthlyPoints(periodRecords);

        // Si hay un mes seleccionado, filtramos los datos de detalle
        final displayedRecords = _selectedMonthKey != null
            ? periodRecords.where((r) {
                final d = DateTime.fromMillisecondsSinceEpoch(r.date);
                return '${d.year}-${_monthShort(d.month)}' == _selectedMonthKey;
              }).toList()
            : periodRecords;

        final displayedGrams =
            displayedRecords.fold(0.0, (s, r) => s + r.totalGrams);
        final displayedPieces =
            displayedRecords.fold(0, (s, r) => s + r.cantidad);
        final spoolsUsed = displayedGrams / 1000.0;

        // Stock de filamento en inventario
        final inventoryItems = widget.inventoryVm?.inventoryItems ?? [];
        final totalStockGrams =
            inventoryItems.fold(0.0, (s, i) => s + i.stockActual);
        final spoolsInStock = totalStockGrams / 1000.0;

        // Desglose de materiales, colores, categorías y piezas
        final materialMap = <String, double>{};
        final colorMap = <String, double>{};
        final categoryMap = <String, double>{};
        final pieceMap = <String, _TopPieceStat>{};

        for (final r in displayedRecords) {
          final cat = r.figureCategory.trim().isEmpty
              ? 'General'
              : r.figureCategory.trim();
          categoryMap[cat] = (categoryMap[cat] ?? 0.0) + r.totalGrams;

          final pieceKey =
              r.pieceType.trim().isEmpty ? 'Sin Nombre' : r.pieceType.trim();
          final existing = pieceMap[pieceKey];
          if (existing == null) {
            pieceMap[pieceKey] = _TopPieceStat(
              name: pieceKey,
              totalGrams: r.totalGrams,
              totalUnits: r.cantidad,
              printCount: 1,
            );
          } else {
            pieceMap[pieceKey] = _TopPieceStat(
              name: pieceKey,
              totalGrams: existing.totalGrams + r.totalGrams,
              totalUnits: existing.totalUnits + r.cantidad,
              printCount: existing.printCount + 1,
            );
          }

          for (final m in r.materials) {
            final matKey = m.type.trim().toUpperCase();
            materialMap[matKey] =
                (materialMap[matKey] ?? 0.0) + (m.grams * r.cantidad);

            final colObj = findVoxelColor(value: m.color, name: m.colorName);
            colorMap[colObj.name] =
                (colorMap[colObj.name] ?? 0.0) + (m.grams * r.cantidad);
          }
        }

        final topPieces = pieceMap.values.toList()
          ..sort((a, b) => b.totalGrams.compareTo(a.totalGrams));

        final lotAvg = displayedRecords.isEmpty
            ? 0.0
            : (displayedPieces / displayedRecords.length);

        // Valor económico estimado del material consumido
        final pricePerGramByMat = <String, double>{};
        for (final item in inventoryItems) {
          if (item.costPerGram > 0) {
            pricePerGramByMat[item.material.trim().toUpperCase()] =
                item.costPerGram;
          }
        }
        final allCosts = inventoryItems
            .where((i) => i.costPerGram > 0)
            .map((i) => i.costPerGram);
        final avgCostRate = allCosts.isNotEmpty
            ? (allCosts.reduce((a, b) => a + b) / allCosts.length)
            : 0.40;

        double estimatedMaterialCost = 0.0;
        for (final r in displayedRecords) {
          for (final m in r.materials) {
            final rate =
                pricePerGramByMat[m.type.trim().toUpperCase()] ?? avgCostRate;
            estimatedMaterialCost += (m.grams * r.cantidad) * rate;
          }
        }

        String topMaterialStr = 'Sin datos';
        if (materialMap.isNotEmpty) {
          final sortedMats = materialMap.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          final topMat = sortedMats.first;
          final pct = displayedGrams > 0
              ? (topMat.value / displayedGrams * 100).round()
              : 0;
          topMaterialStr = '${topMat.key} ($pct%)';
        }

        return Scaffold(
          appBar: darkAppBar(
            'ANÁLISIS DE PRODUCCIÓN',
            widget.onToggleMenu ?? () => goBack(context),
            leadingWidget:
                widget.onToggleMenu != null ? const SidebarToggleIcon() : null,
            leadingIcon: Icons.arrow_back,
            onHoverEnter: widget.onHoverMenu,
            hideLeading: widget.isPinned,
            actions: [
              // Selector de Periodo compacto y elegante
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderSubtle),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _periodButton('3M', '3 Meses'),
                    _periodButton('6M', '6 Meses'),
                    _periodButton('AÑO', 'Este Año'),
                    _periodButton('TODO', 'Histórico'),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: 'Exportar informe',
                child: IconButton(
                  icon: const Icon(Icons.file_download_outlined, size: 20),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ExportScreen(
                          vm: vm,
                          inventoryVm: widget.inventoryVm,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 14),
            ],
          ),
          backgroundColor: bgBase,
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              // 1. CARDS OPERATIVAS COMPACTAS
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 1060
                      ? 4
                      : constraints.maxWidth >= 560
                          ? 2
                          : 1;
                  final cardWidth =
                      (constraints.maxWidth - (12 * (columns - 1))) / columns;

                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: cardWidth,
                        child: _kpiCard(
                          title: 'MATERIAL CONSUMIDO',
                          value:
                              '${(displayedGrams / 1000.0).toStringAsFixed(2)} kg',
                          subtitle:
                              '${spoolsUsed.toStringAsFixed(1)} carretes est.',
                          icon: Icons.album_outlined,
                          iconColor: accentPetrol,
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: _kpiCard(
                          title: 'PIEZAS FABRICADAS',
                          value: '$displayedPieces piezas',
                          subtitle:
                              '${displayedRecords.length} trabajos/órdenes',
                          icon: Icons.precision_manufacturing_outlined,
                          iconColor: const Color(0xFF0071E3),
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: _kpiCard(
                          title: 'VALOR EN MATERIAL',
                          value:
                              '\$${estimatedMaterialCost.toStringAsFixed(0)}',
                          subtitle: '${materialMap.length} plásticos usados',
                          icon: Icons.payments_outlined,
                          iconColor: const Color(0xFF34C759),
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: _kpiCard(
                          title: 'MATERIAL MÁS USADO',
                          value: topMaterialStr,
                          subtitle: '${colorMap.length} colores aplicados',
                          icon: Icons.star_rounded,
                          iconColor: const Color(0xFFFF9500),
                        ),
                      ),
                    ],
                  );
                },
              ),

              if (_selectedMonthKey != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0071E3).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF0071E3).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.filter_alt_outlined,
                          size: 16, color: Color(0xFF0071E3)),
                      const SizedBox(width: 8),
                      Text(
                        'Detalle mensual: $_selectedMonthKey',
                        style: const TextStyle(
                          color: Color(0xFF0071E3),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: () => setState(() => _selectedMonthKey = null),
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Quitar filtro',
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.close, size: 14, color: textSecondary),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 18),

              // 2. SECCIÓN PRINCIPAL: GRÁFICA INTELIGENTE + CATEGORÍAS
              LayoutBuilder(
                builder: (context, constraints) {
                  final isSingleColumn = constraints.maxWidth < 950;
                  if (isSingleColumn) {
                    return Column(
                      children: [
                        _buildEvolutionCard(monthlyPoints),
                        const SizedBox(height: 16),
                        _buildCategoryCard(categoryMap, displayedGrams),
                      ],
                    );
                  }
                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 5,
                          child: _buildEvolutionCard(monthlyPoints),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 3,
                          child: _buildCategoryCard(
                            categoryMap,
                            displayedGrams,
                            fillHeight: true,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 18),

              // 3. SECCIÓN SECUNDARIA: TOP PIEZAS + DESGLOSE CROMÁTICO
              LayoutBuilder(
                builder: (context, constraints) {
                  final isSingleColumn = constraints.maxWidth < 950;
                  if (isSingleColumn) {
                    return Column(
                      children: [
                        _buildTopPiecesCard(topPieces, displayedGrams),
                        const SizedBox(height: 16),
                        _buildMaterialAndColorCard(
                          materialMap,
                          colorMap,
                          displayedGrams,
                          inventoryItems,
                        ),
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 1,
                        child: _buildTopPiecesCard(topPieces, displayedGrams),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 1,
                        child: _buildMaterialAndColorCard(
                          materialMap,
                          colorMap,
                          displayedGrams,
                          inventoryItems,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // --- BOTÓN DE PERIODO EN APP BAR ---
  Widget _periodButton(String code, String tooltip) {
    final isSelected = _selectedPeriod == code;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () => setState(() {
          _selectedPeriod = code;
          _selectedMonthKey = null;
        }),
        borderRadius: BorderRadius.circular(6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? surfaceCard : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    )
                  ]
                : null,
          ),
          child: Text(
            code,
            style: TextStyle(
              color: isSelected ? textPrimary : textSecondary,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  // --- TARJETA DE KPI ---
  Widget _kpiCard({
    required String title,
    required String value,
    String? subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 15, color: iconColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: TextStyle(
                color: textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  // --- TARJETA 1: EVOLUCIÓN TEMPORAL UNIFICADA ---
  Widget _buildEvolutionCard(List<_MonthlyDataPoint> points) {
    final values = _metricIndex == 0
        ? points.map((p) => p.grams).toList()
        : points.map((p) => p.pieces.toDouble()).toList();

    final maxVal =
        values.isEmpty ? 1.0 : values.reduce((a, b) => a > b ? a : b);
    final totalVal = values.fold(0.0, (s, v) => s + v);
    final activeMonths = values.where((v) => v > 0).length;
    final avgVal = activeMonths > 0 ? (totalVal / activeMonths) : 0.0;

    final unitLabel = _metricIndex == 0 ? 'g' : 'piezas';
    final accent = _metricIndex == 0 ? chartPrimary : const Color(0xFF0071E3);

    return Container(
      key: const ValueKey('analytics_evolution_card'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera con selector de métrica
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TENDENCIA DE FABRICACIÓN',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Toca un mes para ver su detalle',
                      style: TextStyle(
                        color: textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Selector Toggle Gramos / Piezas
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderSubtle),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _metricToggleOption(
                      title: 'Gramos',
                      index: 0,
                      icon: Icons.layers_outlined,
                    ),
                    _metricToggleOption(
                      title: 'Piezas',
                      index: 1,
                      icon: Icons.view_in_ar_outlined,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Badge con Promedio y Total + Indicador de Mes Filtrado
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Total: ${totalVal.toStringAsFixed(_metricIndex == 0 ? 1 : 0)} $unitLabel',
                  style: TextStyle(
                    color: accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '· Media activa: ${avgVal.toStringAsFixed(1)} $unitLabel/mes',
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (_selectedMonthKey != null) ...[
                const SizedBox(width: 10),
                InkWell(
                  onTap: () => setState(() => _selectedMonthKey = null),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: accentPetrol.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: accentPetrol.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Mes: $_selectedMonthKey',
                          style: const TextStyle(
                            color: accentPetrol,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.close, size: 12, color: accentPetrol),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 20),

          // Gráfica de Barras estilizada
          SizedBox(
            height: 190,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Eje Y (Escala de valores)
                SizedBox(
                  width: 44,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(5, (i) {
                      final val = maxVal * (4 - i) / 4;
                      return Text(
                        val >= 1000
                            ? '${(val / 1000).toStringAsFixed(1)}k'
                            : val.toStringAsFixed(val % 1 == 0 ? 0 : 1),
                        style: TextStyle(
                          color: textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(width: 12),

                // Contenedor de Barras
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final count = points.isEmpty ? 1 : points.length;
                      final barWidth = (constraints.maxWidth / count * 0.55)
                          .clamp(24.0, 48.0);
                      final chartH = constraints.maxHeight - 26;

                      // Posición de la línea de promedio
                      final avgRatio =
                          maxVal > 0 ? (avgVal / maxVal).clamp(0.0, 1.0) : 0.0;
                      final avgTop = chartH * (1.0 - avgRatio) + 4;

                      return Stack(
                        children: [
                          // Líneas de fondo sutiles
                          ...List.generate(5, (i) {
                            final top = i * chartH / 4 + 4;
                            return Positioned(
                              left: 0,
                              right: 0,
                              top: top,
                              child: Container(
                                height: 1,
                                color: borderSubtle,
                              ),
                            );
                          }),

                          // Línea guía de promedio mensual
                          if (avgVal > 0)
                            Positioned(
                              left: 0,
                              right: 0,
                              top: avgTop,
                              child: Container(
                                height: 1.2,
                                color: accent.withValues(alpha: 0.35),
                              ),
                            ),

                          // Barras interactivas
                          Padding(
                            padding: const EdgeInsets.only(top: 4, bottom: 2),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: points.asMap().entries.map((e) {
                                final idx = e.key;
                                final point = e.value;
                                final pointKey = '${point.year}-${point.label}';
                                final isSelectedMonth =
                                    _selectedMonthKey == pointKey;
                                final val = _metricIndex == 0
                                    ? point.grams
                                    : point.pieces.toDouble();
                                final isZero = val == 0;
                                final ratio = isZero
                                    ? 0.02
                                    : (val / (maxVal == 0 ? 1 : maxVal))
                                        .clamp(0.04, 1.0);
                                final isHovered = _hoveredBarIndex == idx;

                                return Expanded(
                                  child: MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    onEnter: (_) =>
                                        setState(() => _hoveredBarIndex = idx),
                                    onExit: (_) =>
                                        setState(() => _hoveredBarIndex = null),
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () {
                                        setState(() {
                                          if (_selectedMonthKey == pointKey) {
                                            _selectedMonthKey = null;
                                          } else {
                                            _selectedMonthKey = pointKey;
                                          }
                                        });
                                      },
                                      child: Tooltip(
                                        waitDuration:
                                            const Duration(milliseconds: 100),
                                        message:
                                            '${point.label} ${point.year}\n• ${point.grams.toStringAsFixed(1)} g\n• ${point.pieces} piezas\n(Clic para filtrar)',
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            Expanded(
                                              child: Align(
                                                alignment:
                                                    Alignment.bottomCenter,
                                                child: AnimatedContainer(
                                                  duration: const Duration(
                                                      milliseconds: 150),
                                                  width: barWidth,
                                                  height: chartH * ratio,
                                                  decoration: BoxDecoration(
                                                    color: isZero
                                                        ? borderSubtle
                                                            .withValues(
                                                                alpha: 0.5)
                                                        : (isSelectedMonth
                                                            ? const Color(
                                                                0xFF0071E3)
                                                            : (isHovered
                                                                ? accentPetrolHover
                                                                : accent)),
                                                    borderRadius:
                                                        const BorderRadius
                                                            .vertical(
                                                      top: Radius.circular(5),
                                                    ),
                                                    border: isSelectedMonth
                                                        ? Border.all(
                                                            color: Colors.white
                                                                .withValues(
                                                                    alpha: 0.9),
                                                            width: 1.5,
                                                          )
                                                        : null,
                                                    boxShadow: (isHovered ||
                                                                isSelectedMonth) &&
                                                            !isZero
                                                        ? [
                                                            BoxShadow(
                                                              color: (isSelectedMonth
                                                                      ? const Color(
                                                                          0xFF0071E3)
                                                                      : accent)
                                                                  .withValues(
                                                                      alpha:
                                                                          0.4),
                                                              blurRadius: 8,
                                                              offset:
                                                                  const Offset(
                                                                      0, -2),
                                                            )
                                                          ]
                                                        : null,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Container(
                                              padding: isSelectedMonth
                                                  ? const EdgeInsets.symmetric(
                                                      horizontal: 5,
                                                      vertical: 1)
                                                  : EdgeInsets.zero,
                                              decoration: isSelectedMonth
                                                  ? BoxDecoration(
                                                      color: const Color(
                                                              0xFF0071E3)
                                                          .withValues(
                                                              alpha: 0.15),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4),
                                                    )
                                                  : null,
                                              child: Text(
                                                point.label,
                                                style: TextStyle(
                                                  color: isSelectedMonth
                                                      ? const Color(0xFF0071E3)
                                                      : (isHovered
                                                          ? textPrimary
                                                          : (isZero
                                                              ? textMuted
                                                              : textSecondary)),
                                                  fontSize: 10,
                                                  fontWeight: (isHovered ||
                                                          isSelectedMonth)
                                                      ? FontWeight.w800
                                                      : FontWeight.w600,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricToggleOption({
    required String title,
    required int index,
    required IconData icon,
  }) {
    final isSelected = _metricIndex == index;
    return InkWell(
      onTap: () => setState(() => _metricIndex = index),
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? surfaceCard : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? accentPetrol : textSecondary,
            ),
            const SizedBox(width: 5),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? textPrimary : textSecondary,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- TARJETA 2: DISTRIBUCIÓN POR CATEGORÍA ---
  Widget _buildCategoryCard(
    Map<String, double> categories,
    double totalGrams, {
    bool fillHeight = false,
  }) {
    final entries = categories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    const categoryColors = [
      Color(0xFF0066CC), // Petrol
      Color(0xFF5856D6), // Indigo
      Color(0xFF30B0C7), // Teal
      Color(0xFFFF9500), // Amber
      Color(0xFF34C759), // Green
      Color(0xFFFF2D55), // Red
    ];

    return Container(
      key: const ValueKey('analytics_category_card'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CATEGORÍAS DE USO',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: surfaceElevated,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: borderSubtle),
                ),
                child: Text(
                  '${entries.length} tipos',
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (entries.isEmpty)
            fillHeight
                ? Expanded(
                    child: Center(
                      child: Text(
                        'No hay categorías registradas',
                        style: TextStyle(color: textSecondary, fontSize: 12),
                      ),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'No hay categorías registradas',
                        style: TextStyle(color: textSecondary, fontSize: 12),
                      ),
                    ),
                  )
          else
            Column(
              children: entries.asMap().entries.map((e) {
                final idx = e.key;
                final entry = e.value;
                final pct = totalGrams > 0 ? (entry.value / totalGrams) : 0.0;
                final col = categoryColors[idx % categoryColors.length];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: col,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              entry.key,
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${entry.value.toStringAsFixed(1)} g',
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '(${(pct * 100).toStringAsFixed(0)}%)',
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: pct.clamp(0.01, 1.0),
                          minHeight: 5,
                          backgroundColor: surfaceElevated,
                          valueColor: AlwaysStoppedAnimation<Color>(col),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // --- TARJETA 3: TOP 5 PIEZAS CON MAYOR CONSUMO ---
  Widget _buildTopPiecesCard(List<_TopPieceStat> topPieces, double totalGrams) {
    final highestGrams = topPieces.isEmpty ? 1.0 : topPieces.first.totalGrams;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'IMPRESIONES CON MAYOR CONSUMO',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              const Icon(Icons.leaderboard_outlined,
                  size: 16, color: accentPetrol),
            ],
          ),
          const SizedBox(height: 16),
          if (topPieces.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No hay piezas registradas en el periodo',
                  style: TextStyle(color: textSecondary, fontSize: 12),
                ),
              ),
            )
          else
            Column(
              children: topPieces.asMap().entries.map((e) {
                final rank = e.key + 1;
                final piece = e.value;
                final ratio = highestGrams > 0
                    ? (piece.totalGrams / highestGrams).clamp(0.01, 1.0)
                    : 0.0;

                final Color medalColor = rank == 1
                    ? const Color(0xFFFF9500)
                    : (rank == 2
                        ? const Color(0xFF8E8E93)
                        : (rank == 3 ? const Color(0xFFC97A3E) : textMuted));

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      // Posición del ranking
                      Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: rank <= 3
                              ? medalColor.withValues(alpha: 0.15)
                              : surfaceElevated,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$rank',
                          style: TextStyle(
                            color: rank <= 3 ? medalColor : textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Nombre y detalles
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${piece.name} · ${piece.totalUnits} uds',
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: ratio,
                                minHeight: 4,
                                backgroundColor: surfaceElevated,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                    accentPetrol),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Gramos acumulados
                      Text(
                        '${piece.totalGrams.toStringAsFixed(1)} g',
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // --- TARJETA 4: MATERIALES Y COLORES DE FILAMENTO ---
  Widget _buildMaterialAndColorCard(
    Map<String, double> materials,
    Map<String, double> colors,
    double totalGrams,
    List<InventoryItem> inventoryItems,
  ) {
    final matEntries = materials.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final colEntries = colors.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'MATERIALES Y COLORES',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              const Icon(Icons.palette_outlined, size: 16, color: accentAmber),
            ],
          ),
          const SizedBox(height: 16),

          // 1. Tarjetas Compactas de Tipo de Material
          Text(
            'TIPOS DE FILAMENTO',
            style: TextStyle(
              color: textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          if (matEntries.isEmpty)
            Text('Sin datos',
                style: TextStyle(color: textSecondary, fontSize: 11))
          else
            Column(
              children: matEntries.take(5).map((m) {
                final pct = totalGrams > 0 ? (m.value / totalGrams) : 0.0;
                final stockGrams = inventoryItems
                    .where((i) =>
                        i.material.trim().toUpperCase() ==
                        m.key.trim().toUpperCase())
                    .fold(0.0, (s, i) => s + i.stockActual);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: accentPetrol.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              m.key,
                              style: const TextStyle(
                                color: accentPetrol,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${m.value.toStringAsFixed(1)} g',
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(${(pct * 100).toStringAsFixed(0)}%)',
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          if (inventoryItems.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: stockGrams > 0
                                    ? surfaceElevated
                                    : semanticWarning.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: stockGrams > 0
                                      ? borderSubtle
                                      : semanticWarning.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                stockGrams > 0
                                    ? 'Stock: ${stockGrams >= 1000 ? '${(stockGrams / 1000).toStringAsFixed(1)} kg' : '${stockGrams.toInt()} g'}'
                                    : 'Sin stock',
                                style: TextStyle(
                                  color: stockGrams > 0
                                      ? textSecondary
                                      : semanticWarning,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: pct.clamp(0.01, 1.0),
                          minHeight: 4,
                          backgroundColor: surfaceElevated,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              accentPetrol),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

          const SizedBox(height: 16),
          Divider(color: borderSubtle, height: 1),
          const SizedBox(height: 14),

          // 2. Chips Cromáticos de Colores
          Text(
            'COLORES MÁS UTILIZADOS',
            style: TextStyle(
              color: textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          if (colEntries.isEmpty)
            Text('Sin datos',
                style: TextStyle(color: textSecondary, fontSize: 11))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: colEntries.map((c) {
                final colObj = findVoxelColor(name: c.key);
                final pct = totalGrams > 0 ? (c.value / totalGrams) : 0.0;

                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                  decoration: BoxDecoration(
                    color: surfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderSubtle),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      colorSwatchCircle(
                        colObj.color,
                        size: 11,
                        isTransparent: colObj.isTransparent,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        c.key,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${c.value.toStringAsFixed(0)} g',
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '(${(pct * 100).toStringAsFixed(0)}%)',
                        style: TextStyle(
                          color: textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderSubtle),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart_outlined, size: 44, color: textMuted),
            const SizedBox(height: 12),
            Text(
              'No hay registros de producción en este periodo',
              style: TextStyle(
                color: textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Prueba seleccionando otro rango temporal en la barra superior.',
              style: TextStyle(
                color: textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthlyDataPoint {
  final String label;
  final int year;
  final double grams;
  final int pieces;

  _MonthlyDataPoint({
    required this.label,
    required this.year,
    required this.grams,
    required this.pieces,
  });
}

class _TopPieceStat {
  final String name;
  final double totalGrams;
  final int totalUnits;
  final int printCount;

  _TopPieceStat({
    required this.name,
    required this.totalGrams,
    required this.totalUnits,
    required this.printCount,
  });
}

// ==========================================
// 6. EXPORTAR DATOS (PDF / EXCEL)
// ==========================================
class _ExportSummaryRow {
  final String label;
  final int count;
  final double grams;

  const _ExportSummaryRow({
    required this.label,
    required this.count,
    required this.grams,
  });
}

List<excel_pkg.CellValue?> _toExcelRow(List<dynamic> values) =>
    values.map((value) {
      if (value is int) return excel_pkg.IntCellValue(value);
      if (value is double) return excel_pkg.DoubleCellValue(value);
      return excel_pkg.TextCellValue(value.toString());
    }).toList();

class ExportScreen extends StatefulWidget {
  final VoidCallback? onToggleMenu;
  final VoidCallback? onHoverMenu;
  final bool isPinned;
  final PrintViewModel vm;
  final InventoryViewModel? inventoryVm;
  const ExportScreen({
    super.key,
    this.onToggleMenu,
    this.onHoverMenu,
    this.isPinned = false,
    required this.vm,
    this.inventoryVm,
  });
  @override
  State<ExportScreen> createState() => _ExportState();
}

class _ExportState extends State<ExportScreen> {
  int tab = 0; // 0 = Impresiones, 1 = Inventario
  final selectedPrint = <int>{};
  final selectedInventory = <String>{};
  late final InventoryViewModel inventory;
  bool _ownsInventory = false;
  String period = 'ESTE MES';
  String searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  Future<void> _saveBytes(List<int> bytes, String fileName, String mimeType,
      String extension) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.windows) {
      await share_plus.SharePlus.instance.share(
        share_plus.ShareParams(
          files: [
            share_plus.XFile.fromData(Uint8List.fromList(bytes),
                mimeType: mimeType),
          ],
          fileNameOverrides: [fileName],
          downloadFallbackEnabled: true,
        ),
      );
      return;
    }

    final location = await getSaveLocation(
      suggestedName: fileName,
      acceptedTypeGroups: [
        XTypeGroup(label: extension.toUpperCase(), extensions: [extension]),
      ],
    );
    if (location == null) return;
    await XFile.fromData(Uint8List.fromList(bytes),
            name: fileName, mimeType: mimeType)
        .saveTo(location.path);
  }

  @override
  void initState() {
    super.initState();
    if (widget.inventoryVm != null) {
      inventory = widget.inventoryVm!;
    } else {
      inventory = InventoryViewModel(AppDatabase());
      _ownsInventory = true;
    }
    inventory.addListener(_refresh);
    selectedPrint.addAll(widget.vm.allRecords.map((r) => r.id));
    selectedInventory.addAll(inventory.inventoryItems.map((i) => i.id));
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    inventory.removeListener(_refresh);
    if (_ownsInventory) inventory.dispose();
    super.dispose();
  }

  List<PrintRecord> get _filteredPrints {
    final now = DateTime.now();
    return widget.vm.allRecords.where((r) {
      if (searchQuery.trim().isNotEmpty) {
        final q = searchQuery.toLowerCase().trim();
        final name = (r.projectName ?? r.pieceType).toLowerCase();
        final cat = r.figureCategory.toLowerCase();
        final req = (r.requesterName ?? '').toLowerCase();
        final mat = r.materials
            .map((m) => '${m.type} ${m.colorName ?? ''}')
            .join(' ')
            .toLowerCase();
        if (!name.contains(q) &&
            !cat.contains(q) &&
            !mat.contains(q) &&
            !req.contains(q)) {
          return false;
        }
      }

      final d = DateTime.fromMillisecondsSinceEpoch(r.date);
      if (period == 'HOY') {
        final startOfDay = DateTime(now.year, now.month, now.day);
        return d.isAfter(startOfDay.subtract(const Duration(seconds: 1)));
      } else if (period == '7 DÍAS') {
        final sevenDaysAgo = now.subtract(const Duration(days: 7));
        return d.isAfter(sevenDaysAgo);
      } else if (period == 'ESTE MES') {
        final startOfMonth = DateTime(now.year, now.month, 1);
        return d.isAfter(startOfMonth.subtract(const Duration(seconds: 1)));
      }
      return true; // 'TODOS'
    }).toList();
  }

  List<InventoryItem> get _filteredInventory {
    if (searchQuery.trim().isEmpty) return inventory.inventoryItems;
    final q = searchQuery.toLowerCase().trim();
    return inventory.inventoryItems.where((item) {
      return item.material.toLowerCase().contains(q) ||
          item.color.toLowerCase().contains(q) ||
          item.brand.toLowerCase().contains(q) ||
          (item.location ?? '').toLowerCase().contains(q);
    }).toList();
  }

  List<PrintRecord> get _availablePrints {
    final filtered = _filteredPrints;
    return filtered.where((record) => selectedPrint.contains(record.id)).toList();
  }

  List<InventoryItem> get _availableInventory {
    final filtered = _filteredInventory;
    return filtered.where((item) => selectedInventory.contains(item.id)).toList();
  }

  bool get _areAllVisibleSelected {
    if (tab == 0) {
      final list = _filteredPrints;
      if (list.isEmpty) return false;
      return list.every((r) => selectedPrint.contains(r.id));
    } else {
      final list = _filteredInventory;
      if (list.isEmpty) return false;
      return list.every((item) => selectedInventory.contains(item.id));
    }
  }

  void _toggleSelectAll() {
    setState(() {
      if (tab == 0) {
        final list = _filteredPrints;
        if (_areAllVisibleSelected) {
          for (final r in list) {
            selectedPrint.remove(r.id);
          }
        } else {
          for (final r in list) {
            selectedPrint.add(r.id);
          }
        }
      } else {
        final list = _filteredInventory;
        if (_areAllVisibleSelected) {
          for (final item in list) {
            selectedInventory.remove(item.id);
          }
        } else {
          for (final item in list) {
            selectedInventory.add(item.id);
          }
        }
      }
    });
  }

  String _monthName(int month) => const [
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

  List<_ExportSummaryRow> _buildSummaryRows(List<PrintRecord> records) {
    final grouped = <DateTime, double>{};
    final counts = <DateTime, int>{};

    for (final record in records) {
      final date = DateTime.fromMillisecondsSinceEpoch(record.date);
      final bucket = switch (period) {
        'HOY' => DateTime(date.year, date.month, date.day),
        '7 DÍAS' => date.subtract(Duration(days: date.weekday - 1)),
        _ => DateTime(date.year, date.month, 1),
      };

      grouped[bucket] = (grouped[bucket] ?? 0) + record.totalGrams;
      counts[bucket] = (counts[bucket] ?? 0) + record.cantidad;
    }

    final ordered = grouped.keys.toList()..sort();
    return ordered.map((date) {
      final end = period == '7 DÍAS' ? date.add(const Duration(days: 6)) : date;
      final label = switch (period) {
        'HOY' =>
          '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
        '7 DÍAS' =>
          '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} - ${end.day.toString().padLeft(2, '0')}/${end.month.toString().padLeft(2, '0')}/${end.year}',
        _ => '${_monthName(date.month)} ${date.year}',
      };

      return _ExportSummaryRow(
        label: label,
        count: counts[date] ?? 0,
        grams: grouped[date] ?? 0,
      );
    }).toList();
  }

  Future<void> _savePdf(
    List<_ExportSummaryRow> summaryRows,
    List<PrintRecord> prints,
    String title,
  ) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) => [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Generado el ${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year} · Total registros seleccionados: ${prints.length}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 14),
          pw.Text('RESUMEN POR PERIODO',
              style:
                  pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headers: ['PERIODO', 'PIEZAS TOTALES', 'CONSUMO TOTAL'],
            data: summaryRows
                .map((row) => [
                      row.label,
                      row.count.toString(),
                      '${row.grams.toStringAsFixed(1)} g'
                    ])
                .toList(),
            border: null,
            headerStyle:
                pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignment: pw.Alignment.centerLeft,
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
          ),
          pw.SizedBox(height: 16),
          pw.Text('DETALLE DE PIEZAS FABRICADAS',
              style:
                  pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headers: [
              'FECHA',
              'PIEZA',
              'MATERIAL / COLOR',
              'CANTIDAD',
              'GRAMOS C/U',
              'TOTAL GRAMOS'
            ],
            data: prints.map((r) {
              final matStr = r.materials.map((m) {
                final cName =
                    (m.colorName != null && m.colorName!.trim().isNotEmpty)
                        ? m.colorName!
                        : findVoxelColor(value: m.color).name;
                return '${m.type} ($cName)';
              }).join(', ');
              final date = DateTime.fromMillisecondsSinceEpoch(r.date);
              final dateStr =
                  '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
              return [
                dateStr,
                r.pieceType,
                matStr,
                '${r.cantidad}',
                '${r.unitGrams.toStringAsFixed(1)} g',
                '${r.totalGrams.toStringAsFixed(1)} g',
              ];
            }).toList(),
            border: null,
            headerStyle:
                pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellAlignment: pw.Alignment.centerLeft,
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
          ),
        ],
      ),
    );

    final bytes = await pdf.save();
    final cleanPeriod = period.toLowerCase().replaceAll(' ', '_');
    final fileName =
        'voxelcost3d_${cleanPeriod}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    await _saveBytes(bytes, fileName, 'application/pdf', 'pdf');
  }

  Future<void> _saveExcel(
    List<_ExportSummaryRow> summaryRows,
    List<PrintRecord> prints,
    String title,
  ) async {
    final excel = excel_pkg.Excel.createExcel();
    final sheetSummary = excel['Resumen'];
    sheetSummary.appendRow(_toExcelRow(['TITULO', title]));
    sheetSummary
        .appendRow(_toExcelRow(['PERIODO', 'PIEZAS TOTALES', 'CONSUMO TOTAL']));
    for (final row in summaryRows) {
      sheetSummary.appendRow(_toExcelRow(
          [row.label, row.count, '${row.grams.toStringAsFixed(1)} g']));
    }

    final sheetDetail = excel['Detalle Impresiones'];
    sheetDetail.appendRow(_toExcelRow([
      'FECHA',
      'ACTIVO / PIEZA',
      'SOLICITANTE',
      'TIPO SOLICITANTE',
      'NO. CONTROL / EMPLEADO',
      'IMPRESORA',
      'TIEMPO IMPRESIÓN',
      'CATEGORÍA',
      'MATERIAL Y COLOR',
      'CANTIDAD',
      'GRAMOS POR UNIDAD',
      'GRAMOS TOTALES',
      'OBSERVACIONES'
    ]));
    for (final r in prints) {
      final matStr = r.materials.map((m) {
        final cName = (m.colorName != null && m.colorName!.trim().isNotEmpty)
            ? m.colorName!
            : findVoxelColor(value: m.color).name;
        return '${m.type} ($cName)';
      }).join(', ');
      final date = DateTime.fromMillisecondsSinceEpoch(r.date);
      final dateStr =
          '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      sheetDetail.appendRow(_toExcelRow([
        dateStr,
        r.pieceType,
        r.requesterName ?? '',
        r.requesterType ?? '',
        r.requesterId ?? '',
        r.printerName ?? '',
        r.printTime ?? '',
        r.figureCategory,
        matStr,
        r.cantidad,
        '${r.unitGrams.toStringAsFixed(1)} g',
        '${r.totalGrams.toStringAsFixed(1)} g',
        r.notes ?? ''
      ]));
    }

    final bytes = excel.encode();
    if (bytes == null) {
      throw StateError('No se pudo serializar el archivo Excel');
    }

    final cleanPeriod = period.toLowerCase().replaceAll(' ', '_');
    final fileName =
        'voxelcost3d_${cleanPeriod}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    await _saveBytes(
        bytes,
        fileName,
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        'xlsx');
  }

  Future<void> _saveInventoryPdf(List<List<String>> rows) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          pw.Text(
            'VOXELCOST3D - INVENTARIO DE MATERIALES',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: ['MATERIAL', 'STOCK ACTUAL', 'STOCK INICIAL'],
            data: rows,
            border: null,
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.centerLeft,
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
          ),
        ],
      ),
    );

    final bytes = await pdf.save();
    final fileName =
        'voxelcost3d_inventario_${DateTime.now().millisecondsSinceEpoch}.pdf';
    await _saveBytes(bytes, fileName, 'application/pdf', 'pdf');
  }

  Future<void> _saveInventoryExcel(List<List<String>> rows) async {
    final excel = excel_pkg.Excel.createExcel();
    final sheet = excel['Inventario'];
    sheet.appendRow(_toExcelRow(['PRODUCTO', 'STOCK ACTUAL', 'STOCK INICIAL']));
    for (final row in rows) {
      sheet.appendRow(_toExcelRow(row));
    }

    final bytes = excel.encode();
    if (bytes == null) {
      throw StateError('No se pudo serializar el archivo Excel');
    }

    final fileName =
        'voxelcost3d_inventario_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    await _saveBytes(
        bytes,
        fileName,
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        'xlsx');
  }

  Future<void> _export(BuildContext context, String format) async {
    final count =
        tab == 0 ? _availablePrints.length : _availableInventory.length;
    if (count == 0) {
      toast(context, 'Selecciona al menos un registro para exportar',
          isError: true);
      return;
    }

    try {
      if (tab == 0) {
        final rows = _buildSummaryRows(_availablePrints);
        if (format == 'PDF') {
          await _savePdf(rows, _availablePrints,
              'VOXELCOST3D - REPORTE DE PRODUCCIÓN (${period.toUpperCase()})');
        } else {
          await _saveExcel(rows, _availablePrints,
              'VOXELCOST3D - REPORTE DE PRODUCCIÓN (${period.toUpperCase()})');
        }
      } else {
        final rows = _availableInventory
            .map((item) => [
                  '${item.material} (${item.color})',
                  '${item.stockActual.toStringAsFixed(1)} g',
                  '${item.stockInicial.toStringAsFixed(1)} g',
                ])
            .toList();
        if (format == 'PDF') {
          await _saveInventoryPdf(rows);
        } else {
          await _saveInventoryExcel(rows);
        }
      }
      if (!context.mounted) return;
      toast(context, 'Archivo $format exportado correctamente');
    } catch (_) {
      if (!context.mounted) return;
      toast(context, 'Error al generar el archivo $format', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prints = _filteredPrints;
    final inventoryList = _filteredInventory;
    final selectedCount =
        tab == 0 ? _availablePrints.length : _availableInventory.length;
    final visibleCount = tab == 0 ? prints.length : inventoryList.length;

    final totalPieces =
        tab == 0 ? _availablePrints.fold<int>(0, (s, r) => s + r.cantidad) : 0;
    final totalGrams =
        tab == 0 ? _availablePrints.fold<double>(0.0, (s, r) => s + r.totalGrams) : 0.0;
    final totalStock =
        tab == 1 ? _availableInventory.fold<double>(0.0, (s, i) => s + i.stockActual) : 0.0;

    return Scaffold(
      appBar: darkAppBar(
        'EXPORTAR DATOS',
        widget.onToggleMenu ?? () => goBack(context),
        leadingWidget:
            widget.onToggleMenu != null ? const SidebarToggleIcon() : null,
        leadingIcon: Icons.arrow_back,
        onHoverEnter: widget.onHoverMenu,
        hideLeading: widget.isPinned,
      ),
      backgroundColor: bgBase,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1300),
          child: Column(
            children: [
              // Segmented Tabs
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: surfaceCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderSubtle),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _tabButton(
                          'IMPRESIONES (${widget.vm.allRecords.length})',
                          0,
                          Icons.layers_outlined),
                    ),
                    Expanded(
                      child: _tabButton(
                          'INVENTARIO (${inventory.inventoryItems.length})',
                          1,
                          Icons.inventory_2_outlined),
                    ),
                  ],
                ),
              ),

              // Barra de Búsqueda y Filtros
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: surfaceCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderSubtle),
                ),
                child: Row(
                  children: [
                    // Campo de Búsqueda Rápida
                    Expanded(
                      flex: 3,
                      child: Container(
                        height: 36,
                        decoration: BoxDecoration(
                          color: surfaceElevated,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: borderSubtle),
                        ),
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: (v) => setState(() => searchQuery = v),
                          style: TextStyle(color: textPrimary, fontSize: 12),
                          decoration: InputDecoration(
                            hintText: tab == 0
                                ? 'Buscar por pieza, material o categoría...'
                                : 'Buscar por material, color o marca...',
                            hintStyle:
                                TextStyle(color: textMuted, fontSize: 12),
                            prefixIcon: Icon(Icons.search,
                                size: 16, color: textSecondary),
                            suffixIcon: searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.close,
                                        size: 14, color: textSecondary),
                                    onPressed: () {
                                      _searchCtrl.clear();
                                      setState(() => searchQuery = '');
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 9),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    // Selector de Periodo (solo en tab Impresiones)
                    if (tab == 0) ...[
                      Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: surfaceElevated,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: borderSubtle),
                        ),
                        child: DropdownButton<String>(
                          value: period,
                          underline: const SizedBox(),
                          dropdownColor: surfaceElevated,
                          icon: Icon(Icons.arrow_drop_down,
                              color: textSecondary, size: 18),
                          items: const [
                            DropdownMenuItem(
                                value: 'HOY',
                                child: Text('Hoy',
                                    style: TextStyle(fontSize: 12))),
                            DropdownMenuItem(
                                value: '7 DÍAS',
                                child: Text('Últimos 7 días',
                                    style: TextStyle(fontSize: 12))),
                            DropdownMenuItem(
                                value: 'ESTE MES',
                                child: Text('Este mes',
                                    style: TextStyle(fontSize: 12))),
                            DropdownMenuItem(
                                value: 'TODOS',
                                child: Text('Histórico completo',
                                    style: TextStyle(fontSize: 12))),
                          ],
                          onChanged: (v) =>
                              setState(() => period = v ?? 'ESTE MES'),
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],

                    // Botón Seleccionar Visibles
                    InkWell(
                      onTap: _toggleSelectAll,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: _areAllVisibleSelected
                              ? accentPetrol.withValues(alpha: 0.12)
                              : surfaceElevated,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _areAllVisibleSelected
                                ? accentPetrol
                                : borderSubtle,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _areAllVisibleSelected
                                  ? Icons.check_box
                                  : Icons.check_box_outline_blank,
                              size: 16,
                              color: _areAllVisibleSelected
                                  ? accentPetrol
                                  : textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _areAllVisibleSelected
                                  ? 'Deseleccionar'
                                  : 'Todos ($visibleCount)',
                              style: TextStyle(
                                color: _areAllVisibleSelected
                                    ? accentPetrol
                                    : textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // KPI Live Summary Bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: surfaceCard,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderSubtle),
                ),
                child: Row(
                  children: [
                    _kpiChip(
                      Icons.checklist_rounded,
                      '$selectedCount de $visibleCount seleccionados',
                      color: accentPetrol,
                    ),
                    const SizedBox(width: 18),
                    if (tab == 0) ...[
                      _kpiChip(Icons.layers_outlined, '$totalPieces piezas'),
                      const SizedBox(width: 18),
                      _kpiChip(Icons.scale_outlined,
                          '${totalGrams.toStringAsFixed(1)} g consumo'),
                    ] else ...[
                      _kpiChip(Icons.inventory_2_outlined,
                          '${totalStock.toStringAsFixed(0)} g stock'),
                    ],
                  ],
                ),
              ),

              // Lista Tabular de Registros
              Expanded(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  decoration: BoxDecoration(
                    color: surfaceCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderSubtle),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LayoutBuilder(builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 720;

                      if (tab == 0) {
                        if (prints.isEmpty) {
                          return _emptyState('No hay impresiones en este periodo o filtro');
                        }
                        return Column(
                          children: [
                            if (isWide) _printsTableHeader(),
                            Expanded(
                              child: ListView.separated(
                                itemCount: prints.length,
                                separatorBuilder: (_, __) =>
                                    Divider(height: 1, color: borderSubtle),
                                itemBuilder: (_, index) {
                                  final r = prints[index];
                                  final checked = selectedPrint.contains(r.id);
                                  return _printTableRow(r, checked, isWide);
                                },
                              ),
                            ),
                          ],
                        );
                      } else {
                        if (inventoryList.isEmpty) {
                          return _emptyState('No hay materiales en este filtro');
                        }
                        return Column(
                          children: [
                            if (isWide) _inventoryTableHeader(),
                            Expanded(
                              child: ListView.separated(
                                itemCount: inventoryList.length,
                                separatorBuilder: (_, __) =>
                                    Divider(height: 1, color: borderSubtle),
                                itemBuilder: (_, index) {
                                  final item = inventoryList[index];
                                  final checked =
                                      selectedInventory.contains(item.id);
                                  return _inventoryTableRow(
                                      item, checked, isWide);
                                },
                              ),
                            ),
                          ],
                        );
                      }
                    }),
                  ),
                ),
              ),

              // Bottom Action Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: surfaceCard,
                  border: Border(top: BorderSide(color: borderSubtle)),
                ),
                child: Row(
                  children: [
                    Text(
                      selectedCount == 0
                          ? 'Ningún registro seleccionado'
                          : '$selectedCount listo${selectedCount > 1 ? 's' : ''} para exportar',
                      style: TextStyle(
                        color: selectedCount > 0 ? textPrimary : textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: 175,
                      child: techButton(
                        'EXPORTAR PDF ($selectedCount)',
                        () => _export(context, 'PDF'),
                        icon: Icons.picture_as_pdf_outlined,
                        color: surfaceElevated,
                        foreground: textPrimary,
                        isOutlined: true,
                        height: 40,
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 185,
                      child: techButton(
                        'EXPORTAR EXCEL ($selectedCount)',
                        () => _export(context, 'Excel'),
                        icon: Icons.table_chart_outlined,
                        color: accentPetrol,
                        foreground: Colors.white,
                        height: 40,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kpiChip(IconData icon, String text, {Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color ?? textSecondary),
        const SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(
            color: color ?? textPrimary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _emptyState(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_outlined, size: 32, color: textMuted),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(color: textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _printsTableHeader() {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: surfaceElevated,
        border: Border(bottom: BorderSide(color: borderSubtle)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 28),
          SizedBox(
            width: 80,
            child: Text('FECHA',
                style: TextStyle(
                    color: textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5)),
          ),
          Expanded(
            flex: 3,
            child: Text('PIEZA / PROYECTO',
                style: TextStyle(
                    color: textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5)),
          ),
          SizedBox(
            width: 110,
            child: Text('CATEGORÍA',
                style: TextStyle(
                    color: textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5)),
          ),
          Expanded(
            flex: 3,
            child: Text('MATERIAL Y COLOR',
                style: TextStyle(
                    color: textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5)),
          ),
          SizedBox(
            width: 50,
            child: Text('CANT.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5)),
          ),
          SizedBox(
            width: 90,
            child: Text('TOTAL (g)',
                textAlign: TextAlign.right,
                style: TextStyle(
                    color: textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5)),
          ),
        ],
      ),
    );
  }

  Widget _printTableRow(PrintRecord r, bool checked, bool isWide) {
    final title = (r.projectName ?? '').trim().isNotEmpty
        ? r.projectName!
        : r.pieceType;

    return InkWell(
      onTap: () => setState(() {
        if (checked) {
          selectedPrint.remove(r.id);
        } else {
          selectedPrint.add(r.id);
        }
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        color: checked ? accentPetrol.withValues(alpha: 0.06) : Colors.transparent,
        child: isWide
            ? Row(
                children: [
                  Icon(
                    checked ? Icons.check_box : Icons.check_box_outline_blank,
                    size: 16,
                    color: checked ? accentPetrol : textSecondary,
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 80,
                    child: Text(
                      dateText(r.date, short: true),
                      style: TextStyle(color: textSecondary, fontSize: 11),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      title,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(
                    width: 110,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: surfaceElevated,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: borderSubtle),
                        ),
                        child: Text(
                          r.figureCategory.toUpperCase(),
                          style: TextStyle(color: textSecondary, fontSize: 9),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 2,
                      children: r.materials.map((m) {
                        final colorObj = findVoxelColor(value: m.color);
                        final colName = (m.colorName != null &&
                                m.colorName!.trim().isNotEmpty)
                            ? m.colorName!
                            : colorObj.name;
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            colorSwatchCircle(colorObj.color,
                                size: 8,
                                isTransparent: colorObj.isTransparent),
                            const SizedBox(width: 4),
                            Text(
                              '${m.type} $colName',
                              style: TextStyle(
                                  color: textSecondary, fontSize: 11),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                  SizedBox(
                    width: 50,
                    child: Text(
                      '×${r.cantidad}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: r.cantidad > 1 ? accentAmber : textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 90,
                    child: Text(
                      '${r.totalGrams.toStringAsFixed(1)} g',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  Icon(
                    checked ? Icons.check_box : Icons.check_box_outline_blank,
                    size: 16,
                    color: checked ? accentPetrol : textSecondary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${dateText(r.date, short: true)} · ${r.materials.map((m) => m.type).join(', ')}',
                          style: TextStyle(color: textMuted, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '×${r.cantidad} · ${r.totalGrams.toStringAsFixed(1)} g',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _inventoryTableHeader() {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: surfaceElevated,
        border: Border(bottom: BorderSide(color: borderSubtle)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 28),
          Expanded(
            flex: 3,
            child: Text('MATERIAL Y COLOR',
                style: TextStyle(
                    color: textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5)),
          ),
          Expanded(
            flex: 2,
            child: Text('MARCA / TIPO',
                style: TextStyle(
                    color: textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5)),
          ),
          SizedBox(
            width: 150,
            child: Text('STOCK ACTUAL',
                style: TextStyle(
                    color: textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5)),
          ),
          SizedBox(
            width: 90,
            child: Text('INICIAL',
                textAlign: TextAlign.right,
                style: TextStyle(
                    color: textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5)),
          ),
          SizedBox(
            width: 90,
            child: Text('ESTADO',
                textAlign: TextAlign.right,
                style: TextStyle(
                    color: textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5)),
          ),
        ],
      ),
    );
  }

  Widget _inventoryTableRow(InventoryItem item, bool checked, bool isWide) {
    final ratio = item.stockInicial > 0
        ? (item.stockActual / item.stockInicial).clamp(0.0, 1.0)
        : 0.0;
    final isLow = item.stockInicial <= 0 || ratio <= 0.2;

    return InkWell(
      onTap: () => setState(() {
        if (checked) {
          selectedInventory.remove(item.id);
        } else {
          selectedInventory.add(item.id);
        }
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        color: checked ? accentPetrol.withValues(alpha: 0.06) : Colors.transparent,
        child: isWide
            ? Row(
                children: [
                  Icon(
                    checked ? Icons.check_box : Icons.check_box_outline_blank,
                    size: 16,
                    color: checked ? accentPetrol : textSecondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: Row(
                      children: [
                        colorSwatchCircle(parseHex(item.colorHex), size: 10),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${item.material} - ${item.color}',
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      item.brand.isNotEmpty ? item.brand : 'Genérica',
                      style: TextStyle(color: textSecondary, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(
                    width: 150,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${item.stockActual.toInt()} g',
                              style: TextStyle(
                                color: isLow ? semanticDanger : textPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${(ratio * 100).toInt()}%',
                              style: TextStyle(
                                  color: textMuted, fontSize: 10),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: ratio,
                            minHeight: 4,
                            backgroundColor: surfaceElevated,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isLow ? semanticDanger : accentPetrol,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 90,
                    child: Text(
                      '${item.stockInicial.toInt()} g',
                      textAlign: TextAlign.right,
                      style: TextStyle(color: textSecondary, fontSize: 11),
                    ),
                  ),
                  SizedBox(
                    width: 90,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isLow
                              ? semanticDanger.withValues(alpha: 0.15)
                              : semanticSuccess.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isLow ? 'BAJO' : 'OK',
                          style: TextStyle(
                            color: isLow ? semanticDanger : semanticSuccess,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  Icon(
                    checked ? Icons.check_box : Icons.check_box_outline_blank,
                    size: 16,
                    color: checked ? accentPetrol : textSecondary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            colorSwatchCircle(parseHex(item.colorHex), size: 8),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${item.material} - ${item.color}',
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${item.brand} · ${item.stockActual.toInt()} g de ${item.stockInicial.toInt()} g',
                          style: TextStyle(color: textMuted, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _tabButton(String title, int targetTab, IconData icon) {
    final active = tab == targetTab;
    return InkWell(
      onTap: () => setState(() {
        tab = targetTab;
        searchQuery = '';
        _searchCtrl.clear();
      }),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: active ? surfaceElevated : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: active ? Border.all(color: borderSubtle) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: active ? accentPetrol : textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: active ? textPrimary : textSecondary,
                fontSize: 11,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 7. INVENTARIO DE MATERIALES
// ==========================================
class InventoryScreen extends StatefulWidget {
  final VoidCallback? onToggleMenu;
  final VoidCallback? onHoverMenu;
  final bool isPinned;
  final InventoryViewModel? vm;
  const InventoryScreen({
    super.key,
    this.onToggleMenu,
    this.onHoverMenu,
    this.isPinned = false,
    this.vm,
  });
  @override
  State<InventoryScreen> createState() => _InventoryState();
}

class _InventoryState extends State<InventoryScreen> {
  late final InventoryViewModel vm;
  bool _ownsVm = false;
  String search = '';
  final TextEditingController _searchCtrl = TextEditingController();
  String statusFilter = 'Todos'; // 'Todos', 'Activos', 'Bajo', 'Agotados'
  String materialFilter = 'Todos';
  bool isGridView = true;

  @override
  void initState() {
    super.initState();
    if (widget.vm != null) {
      vm = widget.vm!;
    } else {
      vm = InventoryViewModel(AppDatabase());
      _ownsVm = true;
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    if (_ownsVm) vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: vm,
        builder: (_, __) {
          final items = vm.inventoryItems.where((i) {
            // Filtro de búsqueda
            if (search.trim().isNotEmpty) {
              final q = search.trim().toLowerCase();
              final match = i.material.toLowerCase().contains(q) ||
                  i.color.toLowerCase().contains(q) ||
                  i.brand.toLowerCase().contains(q) ||
                  i.finish.toLowerCase().contains(q) ||
                  (i.location?.toLowerCase().contains(q) ?? false) ||
                  (i.notes?.toLowerCase().contains(q) ?? false);
              if (!match) return false;
            }

            // Filtro por Estado
            if (statusFilter == 'Activos' && i.isDepleted) return false;
            if (statusFilter == 'Bajo' && !i.isLowStock) return false;
            if (statusFilter == 'Agotados' && !i.isDepleted) return false;

            // Filtro por Material
            if (materialFilter != 'Todos' && i.material != materialFilter) {
              return false;
            }

            return true;
          }).toList();

          final availableMaterials = [
            'Todos',
            ...vm.inventoryItems.map((x) => x.material).toSet().toList()
          ];

          return Scaffold(
            appBar: darkAppBar(
              'INVENTARIO DE MATERIALES',
              widget.onToggleMenu ?? () => goBack(context),
              leadingWidget: widget.onToggleMenu != null
                  ? const SidebarToggleIcon()
                  : null,
              leadingIcon: Icons.arrow_back,
              onHoverEnter: widget.onHoverMenu,
              hideLeading: widget.isPinned,
              actions: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddProductScreen(vm: vm),
                      ),
                    ),
                    icon: Icon(Icons.add, size: 16, color: textPrimary),
                    label: Text(
                      'Nueva Bobina',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 0),
                      backgroundColor: accentPetrol,
                      foregroundColor: textPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ),
            backgroundColor: bgBase,
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1300),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (vm.error != null) ...[
                        _databaseError(vm.error!),
                        const SizedBox(height: 10),
                      ],

                      // 2. Barra de Búsqueda y Filtros Rápidos
                      Row(
                        children: [
                          // Buscador compacto
                          Expanded(
                            flex: 3,
                            child: SizedBox(
                              height: 38,
                              child: TextField(
                                controller: _searchCtrl,
                                onChanged: (x) => setState(() => search = x),
                                style:
                                    TextStyle(color: textPrimary, fontSize: 13),
                                decoration: InputDecoration(
                                  hintText:
                                      'Buscar material, color, marca o ubicación...',
                                  hintStyle:
                                      TextStyle(color: textMuted, fontSize: 12),
                                  prefixIcon: Icon(Icons.search,
                                      color: textSecondary, size: 17),
                                  suffixIcon: search.isNotEmpty
                                      ? IconButton(
                                          icon: Icon(Icons.clear,
                                              size: 14, color: textSecondary),
                                          onPressed: () {
                                            _searchCtrl.clear();
                                            setState(() => search = '');
                                          },
                                        )
                                      : null,
                                  filled: true,
                                  fillColor: surfaceCard,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 0),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: borderSubtle),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: borderSubtle),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                        color: accentPetrol, width: 1.2),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Selector de Vista (Cuadrícula / Lista)
                          Container(
                            height: 38,
                            decoration: BoxDecoration(
                              color: surfaceCard,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: borderSubtle),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Cuadrícula',
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6),
                                  icon: Icon(Icons.grid_view_rounded,
                                      size: 16,
                                      color: isGridView
                                          ? accentPetrol
                                          : textSecondary),
                                  onPressed: () =>
                                      setState(() => isGridView = true),
                                ),
                                IconButton(
                                  tooltip: 'Lista',
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6),
                                  icon: Icon(Icons.view_list_rounded,
                                      size: 16,
                                      color: !isGridView
                                          ? accentPetrol
                                          : textSecondary),
                                  onPressed: () =>
                                      setState(() => isGridView = false),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // 3. Fila de Filtros de Material y Estado Horizontal
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ...availableMaterials.map((mat) {
                              final isSel = materialFilter == mat;
                              final count = mat == 'Todos'
                                  ? vm.inventoryItems.length
                                  : vm.inventoryItems
                                      .where((i) => i.material == mat)
                                      .length;
                              return _filterChip(
                                '$mat ($count)',
                                isSel,
                                () => setState(() => materialFilter = mat),
                              );
                            }),
                            const SizedBox(width: 6),
                            Container(
                              height: 18,
                              width: 1,
                              color: borderSubtle,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                            ),
                            const SizedBox(width: 6),
                            _filterChip(
                              'Todos los estados',
                              statusFilter == 'Todos',
                              () => setState(() => statusFilter = 'Todos'),
                            ),
                            if (vm.lowStockCount > 0)
                              _filterChip(
                                'Bajo Stock (${vm.lowStockCount})',
                                statusFilter == 'Bajo',
                                () => setState(() => statusFilter = 'Bajo'),
                                isAlert: true,
                              ),
                            if (vm.depletedStockCount > 0)
                              _filterChip(
                                'Agotadas (${vm.depletedStockCount})',
                                statusFilter == 'Agotados',
                                () => setState(() => statusFilter = 'Agotados'),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 4. Catálogo de Bobinas (Grid o Tabla)
                      Expanded(
                        child: items.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.inventory_2_outlined,
                                      size: 40,
                                      color:
                                          textSecondary.withValues(alpha: 0.35),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      search.isNotEmpty ||
                                              statusFilter != 'Todos' ||
                                              materialFilter != 'Todos'
                                          ? 'No se encontraron bobinas con estos filtros'
                                          : 'No hay bobinas registradas',
                                      style: TextStyle(
                                          color: textSecondary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              )
                            : isGridView
                                ? GridView.builder(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    gridDelegate:
                                        const SliverGridDelegateWithMaxCrossAxisExtent(
                                      maxCrossAxisExtent: 380,
                                      mainAxisExtent: 178,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                    ),
                                    itemCount: items.length,
                                    itemBuilder: (_, index) =>
                                        _inventoryCard(items[index]),
                                  )
                                : _inventoryTable(items),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );


  Widget _databaseError(String message) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: semanticDanger.withValues(alpha: 0.12),
          border: Border.all(color: semanticDanger.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(message,
            style: const TextStyle(color: semanticDanger, fontSize: 12)),
      );

  Widget _filterChip(String label, bool isSelected, VoidCallback onTap,
      {bool isAlert = false}) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected
                ? (isAlert ? semanticDanger : accentPetrol)
                : surfaceCard,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? (isAlert ? semanticDanger : accentPetrol)
                  : borderSubtle,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? textPrimary : textSecondary,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _inventoryCard(InventoryItem item) {
    final ratio = item.remainingRatio;
    final low = item.isLowStock;
    final depleted = item.isDepleted;
    final spoolColor = parseHex(item.colorHex);
    final hasRealBrand =
        item.brand.trim().isNotEmpty && item.brand.trim() != 'Genérica';

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: depleted
              ? borderSubtle
              : low
                  ? semanticDanger.withValues(alpha: 0.5)
                  : borderSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 1. Fila Superior: Swatch + Nombre/Marca + Menú (...)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              colorSwatchCircle(spoolColor, size: 15),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasRealBrand)
                      Text(
                        item.brand.toUpperCase(),
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    Text(
                      '${item.material} · ${item.color}',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (depleted)
                _statusBadge('AGOTADO', semanticDanger)
              else if (low)
                _statusBadge('BAJO STOCK', semanticDanger),
              const SizedBox(width: 4),

              PopupMenuButton<String>(
                tooltip: 'Opciones',
                icon: Icon(Icons.more_horiz_rounded,
                    size: 18, color: textSecondary),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                color: surfaceElevated,
                onSelected: (val) async {
                  if (val == 'edit') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            AddProductScreen(vm: vm, itemToEdit: item),
                      ),
                    );
                  } else if (val == 'copy') {
                    await vm.duplicateItem(item);
                    if (!mounted) return;
                    toast(context, 'Bobina duplicada con éxito');
                  } else if (val == 'delete') {
                    _confirmDeleteItem(item);
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined,
                            size: 15, color: textSecondary),
                        const SizedBox(width: 8),
                        const Text('Editar bobina',
                            style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'copy',
                    child: Row(
                      children: [
                        Icon(Icons.copy_outlined,
                            size: 15, color: textSecondary),
                        const SizedBox(width: 8),
                        const Text('Duplicar ficha',
                            style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline,
                            size: 15, color: semanticDanger),
                        SizedBox(width: 8),
                        Text('Eliminar',
                            style:
                                TextStyle(fontSize: 12, color: semanticDanger)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // 2. Medidor Central de Stock
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${item.stockActual.toInt()} g',
                        style: TextStyle(
                          color: low ? semanticDanger : textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'de ${item.stockInicial.toInt()} g',
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${(ratio * 100).toInt()}%',
                    style: TextStyle(
                      color: low ? semanticDanger : textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 4,
                  backgroundColor: surfaceElevated,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    depleted
                        ? textMuted
                        : low
                            ? semanticDanger
                            : accentPetrol,
                  ),
                ),
              ),
            ],
          ),

          // 3. Fila de Datos Técnicos
          Row(
            children: [
              Text(
                '${item.diameter.toStringAsFixed(2)} mm',
                style: TextStyle(color: textSecondary, fontSize: 10),
              ),
              if (item.tempNozzle != null) ...[
                Text(' · ♨ ${item.tempNozzle}°C',
                    style: TextStyle(color: textSecondary, fontSize: 10)),
              ],
              if (item.location != null && item.location!.trim().isNotEmpty) ...[
                Text(' · 📍 ${item.location}',
                    style: TextStyle(color: textSecondary, fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ],
          ),

          // 4. Fila Inferior de Acciones Rápidas
          Row(
            children: [
              // Botón destacado para Báscula
              Expanded(
                child: InkWell(
                  onTap: () => _showWeighAndTareDialog(item),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    height: 28,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: surfaceElevated,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: borderSubtle),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.scale_outlined,
                            size: 13, color: textSecondary),
                        const SizedBox(width: 5),
                        Text(
                          'Pesar en báscula',
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Ajustes rápidos
              _adjustTextButton('-50g', () => vm.updateStock(item, -50)),
              const SizedBox(width: 4),
              _adjustTextButton('+50g', () => vm.updateStock(item, 50)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _inventoryTable(List<InventoryItem> items) => ListView.separated(
        padding: const EdgeInsets.only(bottom: 20),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 6),
        itemBuilder: (_, index) {
          final item = items[index];
          final ratio = item.remainingRatio;
          final low = item.isLowStock;
          final depleted = item.isDepleted;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: surfaceCard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color:
                    low ? semanticDanger.withValues(alpha: 0.5) : borderSubtle,
              ),
            ),
            child: Row(
              children: [
                colorSwatchCircle(parseHex(item.colorHex), size: 13),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${item.brand != 'Genérica' ? '[${item.brand}] ' : ''}${item.material} · ${item.color}',
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${item.diameter.toStringAsFixed(2)} mm'
                        '${item.tempNozzle != null ? ' · ♨ ${item.tempNozzle}°C' : ''}'
                        '${item.location != null && item.location!.isNotEmpty ? ' · 📍 ${item.location}' : ''}',
                        style: TextStyle(color: textSecondary, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${item.stockActual.toInt()} g disp.',
                            style: TextStyle(
                              color: low ? semanticDanger : textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${(ratio * 100).toInt()}%',
                            style: TextStyle(
                              color: low ? semanticDanger : textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: ratio,
                          minHeight: 4,
                          backgroundColor: surfaceElevated,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            depleted
                                ? textMuted
                                : low
                                    ? semanticDanger
                                    : accentPetrol,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  tooltip: 'Pesar en báscula',
                  icon: Icon(Icons.scale_outlined,
                      size: 16, color: textSecondary),
                  onPressed: () => _showWeighAndTareDialog(item),
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  tooltip: 'Editar',
                  icon: Icon(Icons.edit_outlined,
                      size: 16, color: textSecondary),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          AddProductScreen(vm: vm, itemToEdit: item),
                    ),
                  ),
                  visualDensity: VisualDensity.compact,
                ),
                PopupMenuButton<String>(
                  tooltip: 'Más opciones',
                  icon: Icon(Icons.more_horiz_rounded,
                      size: 18, color: textSecondary),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  color: surfaceElevated,
                  onSelected: (val) async {
                    if (val == 'copy') {
                      await vm.duplicateItem(item);
                      if (!mounted) return;
                      toast(context, 'Bobina duplicada');
                    } else if (val == 'delete') {
                      _confirmDeleteItem(item);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'copy',
                      child: Text('Duplicar', style: TextStyle(fontSize: 12)),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('Eliminar',
                          style:
                              TextStyle(fontSize: 12, color: semanticDanger)),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );

  Widget _statusBadge(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 8,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
        ),
      );

  Widget _adjustTextButton(String label, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          height: 28,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 7),
          decoration: BoxDecoration(
            color: surfaceElevated,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: borderSubtle),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );

  void _showWeighAndTareDialog(InventoryItem item) {
    var mode = 0; // 0 = Directo, 1 = Báscula con Tara
    final directCtrl = TextEditingController(
      text: item.stockActual.toStringAsFixed(item.stockActual % 1 == 0 ? 0 : 1),
    );
    final grossCtrl = TextEditingController();
    final tareCtrl = TextEditingController(
      text: item.tareWeight > 0 ? item.tareWeight.toStringAsFixed(0) : '200',
    );

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setModalState) {
          double? calculatedNet;
          final gross = double.tryParse(grossCtrl.text);
          final tare = double.tryParse(tareCtrl.text) ?? 200.0;
          if (gross != null && gross >= tare) {
            calculatedNet = gross - tare;
          }

          return AlertDialog(
            backgroundColor: surfaceCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: borderSubtle),
            ),
            title: Row(
              children: [
                colorSwatchCircle(parseHex(item.colorHex), size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ajustar Stock: [${item.brand}] ${item.material}',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 380,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Color: ${item.color} · Capacidad inicial: ${item.stockInicial.toInt()} g',
                    style: TextStyle(color: textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: borderSubtle),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setModalState(() => mode = 0),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              decoration: BoxDecoration(
                                color: mode == 0
                                    ? surfaceCard
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: mode == 0
                                    ? const [
                                        BoxShadow(
                                            color: Color(0x14000000),
                                            blurRadius: 4)
                                      ]
                                    : null,
                              ),
                              child: Text(
                                'Entrada directa',
                                style: TextStyle(
                                  color:
                                      mode == 0 ? textPrimary : textSecondary,
                                  fontSize: 12,
                                  fontWeight: mode == 0
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () => setModalState(() => mode = 1),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              decoration: BoxDecoration(
                                color: mode == 1
                                    ? surfaceCard
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: mode == 1
                                    ? const [
                                        BoxShadow(
                                            color: Color(0x14000000),
                                            blurRadius: 4)
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.scale_outlined,
                                      size: 13,
                                      color: mode == 1
                                          ? accentPetrol
                                          : textSecondary),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Báscula + Tara',
                                    style: TextStyle(
                                      color: mode == 1
                                          ? textPrimary
                                          : textSecondary,
                                      fontSize: 12,
                                      fontWeight: mode == 1
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (mode == 0) ...[
                    TextField(
                      controller: directCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      autofocus: true,
                      style: TextStyle(color: textPrimary, fontSize: 14),
                      decoration: fieldDecoration(
                        'Gramos netos disponibles',
                        hint: 'Ej: 750.0',
                        suffix: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 12),
                          child: Text('gramos',
                              style: TextStyle(
                                  color: textSecondary, fontSize: 12)),
                        ),
                      ),
                    ),
                  ] else ...[
                    TextField(
                      controller: grossCtrl,
                      onChanged: (_) => setModalState(() {}),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      autofocus: true,
                      style: TextStyle(color: textPrimary, fontSize: 14),
                      decoration: fieldDecoration(
                        'Peso total en báscula',
                        hint: 'Ej: 950 (rollo con plástico)',
                        suffix: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 12),
                          child: Text('gramos',
                              style: TextStyle(
                                  color: textSecondary, fontSize: 12)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: tareCtrl,
                      onChanged: (_) => setModalState(() {}),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(color: textPrimary, fontSize: 13),
                      decoration: fieldDecoration(
                        'Tara (peso del carrete plástico vacío)',
                        hint: 'Ej: 200',
                        suffix: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 12),
                          child: Text('gramos',
                              style: TextStyle(
                                  color: textSecondary, fontSize: 12)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: accentPetrol.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: accentPetrol.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Filamento neto restante:',
                            style:
                                TextStyle(color: textSecondary, fontSize: 12),
                          ),
                          Text(
                            calculatedNet != null
                                ? '${calculatedNet.toStringAsFixed(1)} g'
                                : '--',
                            style: const TextStyle(
                              color: accentPetrol,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: Text('Cancelar', style: TextStyle(color: textSecondary)),
              ),
              ElevatedButton(
                onPressed: () {
                  double? finalStock;
                  if (mode == 0) {
                    finalStock = double.tryParse(directCtrl.text);
                  } else {
                    final g = double.tryParse(grossCtrl.text);
                    final t = double.tryParse(tareCtrl.text) ?? 0.0;
                    if (g != null) finalStock = g - t;
                  }

                  if (finalStock == null || finalStock < 0) {
                    toast(context, 'Ingresa una cantidad válida',
                        isError: true);
                    return;
                  }
                  Navigator.pop(dialogCtx);
                  vm.setExactStock(item, finalStock);
                  toast(context,
                      'Stock actualizado a ${finalStock.toStringAsFixed(1)} g');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentPetrol,
                  foregroundColor: textPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDeleteItem(InventoryItem item) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: borderSubtle),
        ),
        title: Text(
          'Eliminar Bobina',
          style: TextStyle(
            color: textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          '¿Deseas eliminar "${item.brand} - ${item.material} (${item.color})" del inventario?',
          style: TextStyle(color: textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('Cancelar', style: TextStyle(color: textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              vm.deleteItem(item);
              toast(context, 'Bobina eliminada del inventario');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: semanticDanger,
              foregroundColor: textPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 8. AGREGAR / EDITAR BOBINA O MATERIAL
// ==========================================
class AddProductScreen extends StatefulWidget {
  final InventoryViewModel vm;
  final InventoryItem? itemToEdit;
  const AddProductScreen({super.key, required this.vm, this.itemToEdit});

  @override
  State<AddProductScreen> createState() => _AddProductState();
}

class _AddProductState extends State<AddProductScreen> {
  // Marca
  String brand = 'Genérica';
  bool customBrand = false;
  final brandText = TextEditingController();

  // Material
  String material = 'PLA';
  bool customMaterial = false;
  final materialText = TextEditingController();

  // Acabado / Variante
  String finish = 'Estándar';

  // Color
  String color = '';
  String colorHex = '#FFFFFF';
  bool customColor = false;
  final colorText = TextEditingController();

  // Peso y Tara
  final initialWeightText = TextEditingController(text: '1000');
  final currentWeightText = TextEditingController(text: '1000');
  final tareText = TextEditingController(text: '200');

  // Costo
  final priceText = TextEditingController(text: '0.00');

  // Parámetros técnicos
  double diameter = 1.75;
  final nozzleTempText = TextEditingController();
  final bedTempText = TextEditingController();
  final locationText = TextEditingController();
  final notesText = TextEditingController();

  bool _saving = false;

  static const List<Map<String, String>> _recommendedColors = [
    {'name': 'Blanco', 'hex': '#FFFFFF'},
    {'name': 'Negro', 'hex': '#111111'},
    {'name': 'Gris', 'hex': '#808080'},
    {'name': 'Silver', 'hex': '#C0C0C0'},
    {'name': 'Rojo', 'hex': '#E53935'},
    {'name': 'Naranja', 'hex': '#FB8C00'},
    {'name': 'Amarillo', 'hex': '#FDD835'},
    {'name': 'Verde', 'hex': '#43A047'},
    {'name': 'Verde militar', 'hex': '#556B2F'},
    {'name': 'Azul', 'hex': '#1E88E5'},
    {'name': 'Azul marino', 'hex': '#1A237E'},
    {'name': 'Celeste', 'hex': '#4FC3F7'},
    {'name': 'Petrol', 'hex': '#2E8B98'},
    {'name': 'Morado', 'hex': '#8E24AA'},
    {'name': 'Rosa', 'hex': '#EC407A'},
    {'name': 'Café / Cobre', 'hex': '#6D4C41'},
    {'name': 'Oro', 'hex': '#D4AF37'},
    {'name': 'Beige / Piel', 'hex': '#D7C4A3'},
  ];

  @override
  void initState() {
    super.initState();
    final edit = widget.itemToEdit;
    if (edit != null) {
      brand = edit.brand;
      if (!widget.vm.allBrands.contains(brand)) {
        customBrand = true;
        brandText.text = brand;
      }

      material = edit.material;
      if (!widget.vm.materialCatalog.any((m) => m.nombre == material)) {
        customMaterial = true;
        materialText.text = material;
      }

      finish = edit.finish;
      color = edit.color;
      colorHex = edit.colorHex;
      colorText.text = edit.color;

      initialWeightText.text = edit.stockInicial.toInt().toString();
      currentWeightText.text = edit.stockActual % 1 == 0
          ? edit.stockActual.toInt().toString()
          : edit.stockActual.toStringAsFixed(1);
      tareText.text =
          edit.tareWeight > 0 ? edit.tareWeight.toStringAsFixed(0) : '200';

      priceText.text = edit.price > 0 ? edit.price.toStringAsFixed(2) : '0.00';
      diameter = edit.diameter;

      if (edit.tempNozzle != null) {
        nozzleTempText.text = edit.tempNozzle.toString();
      }
      if (edit.tempBed != null) {
        bedTempText.text = edit.tempBed.toString();
      }
      if (edit.location != null) {
        locationText.text = edit.location!;
      }
      if (edit.notes != null) {
        notesText.text = edit.notes!;
      }
    } else {
      if (widget.vm.colorCatalog.isNotEmpty) {
        color = widget.vm.colorCatalog.first.nombre;
        colorHex = widget.vm.colorCatalog.first.hex;
      } else {
        color = 'Negro';
        colorHex = '#111111';
      }
    }
  }

  @override
  void dispose() {
    brandText.dispose();
    materialText.dispose();
    colorText.dispose();
    initialWeightText.dispose();
    currentWeightText.dispose();
    tareText.dispose();
    priceText.dispose();
    nozzleTempText.dispose();
    bedTempText.dispose();
    locationText.dispose();
    notesText.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.itemToEdit != null;

    return Scaffold(
      appBar: darkAppBar(
        isEditing ? 'EDITAR BOBINA' : 'AGREGAR BOBINA / MATERIAL',
        () => goBack(context),
      ),
      backgroundColor: bgBase,
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 1. IDENTIFICACIÓN DEL MATERIAL
          // 1. IDENTIFICACIÓN DEL MATERIAL
          formCard(
            title: '1. Identificación del Material',
            subtitle: 'Marca, polímero y acabado de la bobina',
            child: LayoutBuilder(
              builder: (context, constraints) {
                final fieldWidth =
                    (constraints.maxWidth * 0.25).clamp(180.0, 320.0);
                return Wrap(
                  spacing: 16,
                  runSpacing: 14,
                  crossAxisAlignment: WrapCrossAlignment.start,
                  children: [
                    // Selector de Marca (cuarta parte)
                    SizedBox(
                      width: fieldWidth,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: customBrand ? '__custom' : brand,
                            dropdownColor: surfaceElevated,
                            style: TextStyle(color: textPrimary, fontSize: 13),
                            iconEnabledColor: textSecondary,
                            items: [
                              ...widget.vm.allBrands.map((b) =>
                                  DropdownMenuItem(
                                      value: b,
                                      child: Text(b,
                                          overflow: TextOverflow.ellipsis))),
                              const DropdownMenuItem(
                                  value: '__custom',
                                  child: Text('+ Otra marca',
                                      overflow: TextOverflow.ellipsis)),
                            ],
                            onChanged: (val) {
                              setState(() {
                                customBrand = val == '__custom';
                                if (val != '__custom') {
                                  brand = val!;
                                }
                              });
                            },
                            decoration: fieldDecoration('Marca del fabricante',
                                prefix: Icon(Icons.branding_watermark_outlined,
                                    size: 16, color: textSecondary)),
                          ),
                          if (customBrand) ...[
                            const SizedBox(height: 10),
                            TextField(
                              controller: brandText,
                              style:
                                  TextStyle(color: textPrimary, fontSize: 13),
                              decoration: fieldDecoration(
                                'Nombre de la marca',
                                hint: 'Ej: Polymaker, eSun...',
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Selector de Material / Polímero (cuarta parte)
                    SizedBox(
                      width: fieldWidth,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: customMaterial ? '__custom' : material,
                            dropdownColor: surfaceElevated,
                            style: TextStyle(color: textPrimary, fontSize: 13),
                            iconEnabledColor: textSecondary,
                            items: [
                              ...widget.vm.materialCatalog.map((m) =>
                                  DropdownMenuItem(
                                      value: m.nombre,
                                      child: Text(m.nombre,
                                          overflow: TextOverflow.ellipsis))),
                              const DropdownMenuItem(
                                  value: '__custom',
                                  child: Text('+ Otro polímero',
                                      overflow: TextOverflow.ellipsis)),
                            ],
                            onChanged: (val) {
                              setState(() {
                                customMaterial = val == '__custom';
                                if (val != '__custom') {
                                  material = val!;
                                }
                              });
                            },
                            decoration: fieldDecoration('Tipo de polímero',
                                prefix: Icon(Icons.category_outlined,
                                    size: 16, color: textSecondary)),
                          ),
                          if (customMaterial) ...[
                            const SizedBox(height: 10),
                            TextField(
                              controller: materialText,
                              style:
                                  TextStyle(color: textPrimary, fontSize: 13),
                              decoration: fieldDecoration(
                                'Nombre del material',
                                hint: 'Ej: PETG-CF, ASA...',
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Acabado / Variante (cuarta parte)
                    SizedBox(
                      width: fieldWidth,
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: finish,
                        dropdownColor: surfaceElevated,
                        style: TextStyle(color: textPrimary, fontSize: 13),
                        iconEnabledColor: textSecondary,
                        items: InventoryViewModel.defaultFinishes
                            .map((f) => DropdownMenuItem(
                                value: f,
                                child: Text(f,
                                    overflow: TextOverflow.ellipsis)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => finish = val);
                        },
                        decoration: fieldDecoration('Acabado o variante visual',
                            prefix: Icon(Icons.auto_awesome_outlined,
                                size: 16, color: textSecondary)),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // 2. COLOR Y ASPECTO VISUAL
          formCard(
            title: '2. Color del Filamento',
            subtitle: 'Selecciona el tono de la paleta y nombra el color',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Malla de colores rápidos
                Text(
                  'Tono visual de la bobina:',
                  style: TextStyle(
                      color: textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _recommendedColors.map((c) {
                    final hex = c['hex']!;
                    final isSelected =
                        colorHex.toUpperCase() == hex.toUpperCase();
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          colorHex = hex;
                          color = c['name']!;
                          colorText.text = c['name']!;
                        });
                      },
                      child: Tooltip(
                        message: c['name']!,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: parseHex(hex),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? accentPetrol : borderStrong,
                              width: isSelected ? 2.5 : 1.0,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color:
                                          accentPetrol.withValues(alpha: 0.4),
                                      blurRadius: 6,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                // Nombre del color (reducido a una tercera parte)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final fieldWidth =
                        (constraints.maxWidth * 0.333).clamp(220.0, 420.0);
                    return SizedBox(
                      width: fieldWidth,
                      child: TextField(
                        controller: colorText,
                        onChanged: (x) {
                          final entered = x.trim();
                          final matchingPreset = _recommendedColors.firstWhere(
                            (preset) =>
                                preset['name']!.toLowerCase() ==
                                entered.toLowerCase(),
                            orElse: () => const <String, String>{},
                          );
                          final enteredHex = entered.startsWith('#')
                              ? entered.substring(1)
                              : entered;
                          final isHex =
                              (enteredHex.length == 6 ||
                                      enteredHex.length == 8) &&
                                  int.tryParse(enteredHex, radix: 16) != null;
                          setState(() {
                            color = x;
                            if (matchingPreset.isNotEmpty) {
                              colorHex = matchingPreset['hex']!;
                            } else if (isHex) {
                              colorHex = '#${enteredHex.toUpperCase()}';
                            }
                          });
                        },
                        style: TextStyle(color: textPrimary, fontSize: 13),
                        decoration: fieldDecoration(
                          'Nombre comercial del color',
                          hint: 'Ej: Rojo Carmesí, Gris Galáctico...',
                          prefix: Padding(
                            padding: const EdgeInsets.all(10),
                            child: KeyedSubtree(
                              key: const ValueKey('product_color_preview'),
                              child: colorSwatchCircle(
                                parseHex(colorHex),
                                size: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. CAPACIDAD Y PESAJE
          formCard(
            title: '3. Capacidad y Pesaje',
            subtitle: 'Gramos netos de la bobina y tara para báscula de taller',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Botones rápidos para peso inicial
                Text(
                  'Capacidad inicial estándar:',
                  style: TextStyle(
                      color: textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: ['250', '500', '750', '1000', '2500'].map((g) {
                    return ActionChip(
                      label: Text('$g g'),
                      labelStyle: TextStyle(
                          color: textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                      backgroundColor: surfaceElevated,
                      side: BorderSide(color: borderSubtle),
                      onPressed: () {
                        setState(() {
                          initialWeightText.text = g;
                          if (!isEditing) {
                            currentWeightText.text = g;
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                // Campos visibles para 5 caracteres
                Wrap(
                  spacing: 24,
                  runSpacing: 14,
                  crossAxisAlignment: WrapCrossAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Peso inicial (g)',
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: 95,
                          child: TextField(
                            controller: initialWeightText,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            onChanged: (_) => setState(() {}),
                            style: TextStyle(
                                color: textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w700),
                            decoration: InputDecoration(
                              hintText: '1000',
                              hintStyle:
                                  TextStyle(color: textMuted, fontSize: 13),
                              filled: true,
                              fillColor: surfaceElevated,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: borderSubtle),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: borderSubtle),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Peso actual disponible (g)',
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: 95,
                          child: TextField(
                            controller: currentWeightText,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w700),
                            decoration: InputDecoration(
                              hintText: '1000',
                              hintStyle:
                                  TextStyle(color: textMuted, fontSize: 13),
                              filled: true,
                              fillColor: surfaceElevated,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: borderSubtle),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: borderSubtle),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tara carrete plástico vacío (g)',
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: 95,
                          child: TextField(
                            controller: tareText,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w700),
                            decoration: InputDecoration(
                              hintText: '200',
                              hintStyle:
                                  TextStyle(color: textMuted, fontSize: 13),
                              filled: true,
                              fillColor: surfaceElevated,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: borderSubtle),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: borderSubtle),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Botón de Guardar
          techButton(
            isEditing
                ? 'ACTUALIZAR FICHA DE BOBINA'
                : 'GUARDAR BOBINA EN INVENTARIO',
            _save,
            icon: Icons.save_outlined,
            height: 48,
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_saving) return;

    final finalBrand = customBrand ? brandText.text.trim() : brand.trim();
    final finalMaterial =
        customMaterial ? materialText.text.trim() : material.trim();
    final finalColor = customColor || colorText.text.trim().isNotEmpty
        ? colorText.text.trim()
        : color.trim();

    final initialGrams = double.tryParse(initialWeightText.text) ?? 0;
    final currentGrams =
        double.tryParse(currentWeightText.text) ?? initialGrams;
    final tare = double.tryParse(tareText.text) ?? 0;
    final price = double.tryParse(priceText.text) ?? 0;
    final nozzle = int.tryParse(nozzleTempText.text);
    final bed = int.tryParse(bedTempText.text);
    final location =
        locationText.text.trim().isEmpty ? null : locationText.text.trim();
    final notes = notesText.text.trim().isEmpty ? null : notesText.text.trim();

    if (finalBrand.isEmpty) {
      toast(context, 'La marca es obligatoria', isError: true);
      return;
    }
    if (finalMaterial.isEmpty) {
      toast(context, 'El nombre del material es obligatorio', isError: true);
      return;
    }
    if (finalColor.isEmpty) {
      toast(context, 'El color es obligatorio', isError: true);
      return;
    }
    if (initialGrams <= 0) {
      toast(context, 'Ingresa un peso inicial válido en gramos', isError: true);
      return;
    }

    setState(() => _saving = true);
    try {
      if (widget.itemToEdit != null) {
        final updated = widget.itemToEdit!.copyWith(
          brand: finalBrand,
          material: finalMaterial,
          finish: finish,
          color: finalColor,
          colorHex: colorHex,
          stockInicial: initialGrams,
          stockActual: currentGrams,
          tareWeight: tare,
          price: price,
          diameter: diameter,
          tempNozzle: nozzle,
          tempBed: bed,
          location: location,
          notes: notes,
        );
        await widget.vm.updateItem(updated);
        if (!mounted) return;
        toast(context, 'Ficha de bobina actualizada');
      } else {
        final newItem = InventoryItem(
          brand: finalBrand,
          material: finalMaterial,
          finish: finish,
          color: finalColor,
          colorHex: colorHex,
          stockInicial: initialGrams,
          stockActual: currentGrams,
          tareWeight: tare,
          price: price,
          diameter: diameter,
          tempNozzle: nozzle,
          tempBed: bed,
          location: location,
          notes: notes,
        );
        await widget.vm.addItem(newItem);
        if (!mounted) return;
        toast(context, 'Bobina agregada al inventario');
      }
      Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
