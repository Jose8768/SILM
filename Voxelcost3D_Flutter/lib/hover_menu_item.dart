import 'package:flutter/material.dart';

class HoverMenuItem extends StatefulWidget {
  const HoverMenuItem({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool selected;

  @override
  State<HoverMenuItem> createState() => _HoverMenuItemState();
}

class _HoverMenuItemState extends State<HoverMenuItem> {
  bool _hovered = false;
  bool _pressed = false;

  void _setHover(bool hovered) {
    if (!mounted) return;
    setState(() => _hovered = hovered);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final indicatorVisible = widget.selected || _hovered;
    final iconColor = widget.selected || _hovered || _pressed
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant;
    final textColor = widget.selected || _hovered || _pressed
        ? colorScheme.primary
        : colorScheme.onSurface;
    final chevronColor = widget.selected || _hovered || _pressed
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant.withAlpha(180);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => _setHover(true),
        onExit: (_) => _setHover(false),
        child: GestureDetector(
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final contentWidth =
                  (constraints.maxWidth - 24).clamp(0.0, double.infinity);
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.fromLTRB(12, 10, 16, 10),
                decoration: BoxDecoration(
                  color: widget.selected
                      ? colorScheme.primary.withAlpha(36)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: indicatorVisible
                      ? [
                          BoxShadow(
                            color: colorScheme.primary.withAlpha(24),
                            blurRadius: 8,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(
                            begin: 0,
                            end: indicatorVisible ? 1 : 0,
                          ),
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                          builder: (context, progress, _) {
                            return Align(
                              alignment: Alignment.centerLeft,
                              widthFactor: progress,
                              child: SizedBox(
                                width: contentWidth,
                                child: ColoredBox(
                                  color: colorScheme.primary.withAlpha(32),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        width: indicatorVisible ? 3 : 0,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          widget.icon,
                          size: 20,
                          color: iconColor,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.title,
                            maxLines: 1,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 13,
                              fontWeight: widget.selected || _hovered
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              letterSpacing: 0.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: chevronColor,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
