import 'dart:math' as math;

import 'package:atril/core/routing/route_observer.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

enum FabSize { small, regular, medium, large }

extension on FabSize {
  double get iconSize => switch (this) {
    FabSize.small => 24.0,
    FabSize.regular => 24.0,
    FabSize.medium => 28.0,
    FabSize.large => 36.0,
  };

  BorderRadius get borderRadius => switch (this) {
    FabSize.small => BorderRadius.circular(16.0),
    FabSize.regular => BorderRadius.circular(16.0),
    FabSize.medium => BorderRadius.circular(20.0),
    FabSize.large => BorderRadius.circular(28.0),
  };
}

class FabMenuItem {
  const FabMenuItem({required this.icon, required this.label, required this.onPressed});

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
}

class _FabMenuItemButton extends AnimatedWidget {
  const _FabMenuItemButton({
    required Animation<double> animation,
    required this.interval,
    required this.item,
    required this.expandFromRight,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.textStyle,
    required this.onPressed,
  }) : super(listenable: animation);

  final Interval interval;
  final FabMenuItem item;
  final bool expandFromRight;
  final Color backgroundColor;
  final Color foregroundColor;
  final TextStyle? textStyle;
  final VoidCallback onPressed;

  Animation<double> get _animation => listenable as Animation<double>;

  @override
  Widget build(BuildContext context) {
    final progress = interval.transform(_animation.value);
    final backgroundExtent = math.max(0.0, Curves.easeOutBack.transform(progress));
    final backgroundOpacity = Curves.easeOut.transform(progress);
    final contentOpacity = Interval(0.25, 1.0, curve: Curves.easeOut).transform(progress);

    return IgnorePointer(
      ignoring: _animation.status != AnimationStatus.completed,
      child: ExcludeSemantics(
        excluding: progress == 0.0,
        child: Semantics(
          button: true,
          child: Tooltip(
            message: item.label,
            excludeFromSemantics: true,
            child: CustomPaint(
              painter: _FabMenuItemBackgroundPainter(
                extent: backgroundExtent,
                opacity: backgroundOpacity,
                expandFromRight: expandFromRight,
                color: backgroundColor,
              ),
              child: Material(
                type: MaterialType.transparency,
                shape: StadiumBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onPressed,
                  child: Opacity(
                    opacity: contentOpacity,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 8.0,
                        children: [
                          Icon(item.icon, size: 24.0, color: foregroundColor),
                          Text(item.label, style: textStyle?.copyWith(color: foregroundColor)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FabMenuItemBackgroundPainter extends CustomPainter {
  const _FabMenuItemBackgroundPainter({
    required this.extent,
    required this.opacity,
    required this.expandFromRight,
    required this.color,
  });

  final double extent;
  final double opacity;
  final bool expandFromRight;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (extent <= 0.0 || size.isEmpty) return;

    final width = size.width * extent;
    final left = expandFromRight ? size.width - width : 0.0;
    final rect = Rect.fromLTWH(left, 0.0, width, size.height);
    final radius = math.min(width, size.height) / 2.0;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius)),
      Paint()..color = color.withValues(alpha: color.a * opacity),
    );
  }

  @override
  bool shouldRepaint(covariant _FabMenuItemBackgroundPainter oldDelegate) {
    return oldDelegate.extent != extent ||
        oldDelegate.opacity != opacity ||
        oldDelegate.expandFromRight != expandFromRight ||
        oldDelegate.color != color;
  }
}

enum FabMenuAnchor { bottomRight, bottomLeft }

class FabMenu extends StatefulWidget {
  FabMenu({
    super.key,
    this.size = FabSize.regular,
    this.anchor = FabMenuAnchor.bottomRight,
    this.showScrim = false,
    required this.fabTooltip,
    this.fabIcon,
    required List<FabMenuItem> items,
  }) : items = List.unmodifiable(items);

  final FabSize size;
  final FabMenuAnchor anchor;
  final bool showScrim;

  final String fabTooltip;
  final IconData? fabIcon;

  final List<FabMenuItem> items;

  @override
  State<FabMenu> createState() => _FabMenuState();
}

class _FabMenuState extends State<FabMenu> with SingleTickerProviderStateMixin, WidgetsBindingObserver, RouteAware {
  static const Duration _openDuration = Duration(milliseconds: 350);
  static const Duration _closeDuration = Duration(milliseconds: 250);

  final GlobalKey _fabAnchorKey = GlobalKey();

  bool _expanded = false;
  OverlayEntry? _overlayEntry;
  ModalRoute<Object?>? _route;

  late final AnimationController _menuController;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _menuController = AnimationController(vsync: this, duration: _openDuration, reverseDuration: _closeDuration);
  }

  @override
  void didUpdateWidget(covariant FabMenu oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!identical(oldWidget.items, widget.items)) {
      _overlayEntry?.markNeedsBuild();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final route = ModalRoute.of(context);
    if (route == _route) return;

    if (_route != null) {
      appRouteObserver.unsubscribe(this);
    }

    _route = route;

    if (route != null) {
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void didPushNext() {
    if (_expanded) {
      _close();
    }
  }

  @override
  void didChangeMetrics() {
    _overlayEntry?.markNeedsBuild();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    appRouteObserver.unsubscribe(this);

    _removeOverlay();

    _menuController.dispose();

    super.dispose();
  }

  void _toggle() => _expanded ? _close() : _open();

  void _open() {
    if (_expanded) return;

    setState(() => _expanded = true);

    _insertOverlay();
    _menuController.forward();
  }

  void _close() {
    if (!_expanded) return;

    setState(() => _expanded = false);

    _menuController.reverse().whenCompleteOrCancel(() {
      if (!mounted) return;

      if (!_expanded && _menuController.isDismissed) {
        _removeOverlay();
      }
    });
  }

  void _selectItem(FabMenuItem item) {
    _toggle();
    item.onPressed();
  }

  void _insertOverlay() {
    if (_overlayEntry != null) return;
    _overlayEntry = OverlayEntry(builder: _buildOverlayContent);
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(key: _fabAnchorKey, child: _buildAnchorFab(context));
  }

  Widget _buildOverlayContent(BuildContext overlayContext) {
    final renderBox = _fabAnchorKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.attached) {
      return const SizedBox.shrink();
    }

    final topLeft = renderBox.localToGlobal(Offset.zero);
    final fabSize = renderBox.size;
    final screenSize = MediaQuery.sizeOf(overlayContext);
    final alignRight = widget.anchor == FabMenuAnchor.bottomRight;

    return Stack(
      children: [
        if (widget.showScrim)
          AnimatedBuilder(
            animation: _menuController,
            builder: (context, _) {
              final opacity = (_menuController.value * 0.4 * 255).round().clamp(0, 255);
              if (opacity == 0) return const SizedBox.shrink();
              return Positioned.fill(
                child: IgnorePointer(
                  ignoring: !_expanded,
                  child: GestureDetector(
                    onTap: _toggle,
                    child: Container(color: Colors.black.withAlpha(opacity)),
                  ),
                ),
              );
            },
          ),
        Positioned(
          bottom: screenSize.height - (topLeft.dy + fabSize.height),
          right: alignRight ? screenSize.width - (topLeft.dx + fabSize.width) : null,
          left: alignRight ? null : topLeft.dx,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            spacing: 8.0,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                spacing: 4.0,
                children: [
                  for (var i = widget.items.length - 1; i >= 0; i--) _buildMenuItem(overlayContext, i, alignRight),
                ],
              ),
              _buildAnchorFab(overlayContext),
            ],
          ),
        ),
      ],
    );
  }

  ({double start, double end}) _itemInterval(int index, int itemCount) {
    if (itemCount <= 1) {
      return (start: 0.0, end: 1.0);
    }

    const staggerPortion = 0.35;
    const animationPortion = 0.65;

    final start = (index / (itemCount - 1)) * staggerPortion;
    final end = math.min(1.0, start + animationPortion);

    return (start: start, end: end);
  }

  Widget _buildMenuItem(BuildContext context, int index, bool alignRight) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final item = widget.items[index];

    final interval = _itemInterval(index, widget.items.length);

    return _FabMenuItemButton(
      animation: _menuController,
      interval: Interval(interval.start, interval.end),
      item: item,
      expandFromRight: alignRight,
      backgroundColor: colorScheme.primaryContainer,
      foregroundColor: colorScheme.onPrimaryContainer,
      textStyle: textTheme.bodyLarge,
      onPressed: () => _selectItem(item),
    );
  }

  Widget _buildAnchorFab(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _menuController,
      builder: (context, _) {
        final t = _menuController.value.clamp(0.0, 1.0);
        final outgoingProgress = (t * 2.0).clamp(0.0, 1.0);
        final incomingProgress = ((t - 0.5) * 2.0).clamp(0.0, 1.0);

        final tooltip = _expanded ? 'Close menu' : widget.fabTooltip;

        final foregroundColor = Color.lerp(colorScheme.onPrimaryContainer, colorScheme.onPrimary, t);
        final backgroundColor = Color.lerp(colorScheme.primaryContainer, colorScheme.primary, t);

        final shape = ShapeBorder.lerp(
          RoundedRectangleBorder(borderRadius: widget.size.borderRadius),
          const StadiumBorder(),
          t,
        );

        final child = widget.fabIcon != null
            ? Stack(
                alignment: Alignment.center,
                children: [
                  Opacity(
                    opacity: 1.0 - outgoingProgress,
                    child: Transform.scale(
                      scale: 1.0 - outgoingProgress,
                      child: Icon(widget.fabIcon, size: widget.size.iconSize),
                    ),
                  ),
                  Opacity(
                    opacity: incomingProgress,
                    child: Transform.scale(
                      scale: incomingProgress,
                      child: Icon(Symbols.close_rounded, size: widget.size.iconSize),
                    ),
                  ),
                ],
              )
            : Transform.rotate(
                angle: t * math.pi / 1.33,
                child: Icon(Symbols.add_rounded, size: widget.size.iconSize),
              );

        return switch (widget.size) {
          FabSize.small => FloatingActionButton.small(
            tooltip: tooltip,
            foregroundColor: foregroundColor,
            backgroundColor: backgroundColor,
            shape: shape,
            clipBehavior: Clip.antiAlias,
            onPressed: _toggle,
            child: child,
          ),
          FabSize.regular || FabSize.medium => FloatingActionButton(
            tooltip: tooltip,
            foregroundColor: foregroundColor,
            backgroundColor: backgroundColor,
            shape: shape,
            clipBehavior: Clip.antiAlias,
            onPressed: _toggle,
            child: child,
          ),
          FabSize.large => FloatingActionButton.large(
            tooltip: tooltip,
            foregroundColor: foregroundColor,
            backgroundColor: backgroundColor,
            shape: shape,
            clipBehavior: Clip.antiAlias,
            onPressed: _toggle,
            child: child,
          ),
        };
      },
    );
  }
}
