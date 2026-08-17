import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';

const _kCollapseBreakpoint = 600.0;

const _kItemSpacing = 4.0;

const _kAnimationDuration = Duration(milliseconds: 300);
const _kAnimationCurve = Curves.easeInOutCubicEmphasized;

typedef ToolbarSeparatorBuilder = Widget Function(BuildContext context, Axis direction, ToolbarSeparator item);

typedef ToolbarIconButtonBuilder = Widget Function(BuildContext context, ToolbarIconButton item);

sealed class const ToolbarItem({final Key? key});

class ToolbarSeparator extends ToolbarItem;

class const ToolbarIconButton({
  super.key,
  final bool animate = false,
  required final VoidCallback? onPressed,
  required final IconData icon,
  final IconData? selectedIcon,
  final int? badgeCount,
  final bool isSelected = false,
  required final String label,
}) extends ToolbarItem;

class const ToolbarCollapsibleItem({
  super.key,
  super.animate = false,
  required super.onPressed,
  required super.icon,
  super.selectedIcon,
  super.badgeCount,
  super.isSelected = false,
  required super.label,
}) extends ToolbarIconButton;

class const Toolbar({
  super.key,
  final Axis direction = .horizontal,
  final Offset? menuAnchorOffset,
  final bool showFab = false,
  final Widget? floatingActionButton,
  final ToolbarSeparatorBuilder separatorBuilder = _buildSeparator,
  final ToolbarIconButtonBuilder iconButtonBuilder = _buildIconButton,
  required final List<ToolbarItem> children,
}) extends StatelessWidget {
  this : assert(!showFab || floatingActionButton != null);

  static Widget _buildSeparator(BuildContext context, Axis direction, ToolbarSeparator item) {
    return SizedBox(
      width: direction == .vertical ? 48.0 : null,
      height: direction == .horizontal ? 48.0 : null,
      child: direction == .horizontal
          ? const VerticalDivider(width: 20.0, thickness: 1.0, indent: 8.0, endIndent: 8.0)
          : const Divider(height: 20.0, thickness: 1.0, indent: 8.0, endIndent: 8.0),
    );
  }

  static Widget _buildIconButton(BuildContext context, ToolbarIconButton item) {
    final colorScheme = Theme.of(context).colorScheme;

    final icon = Icon(item.icon);

    final button = IconButton(
      key: item.key,
      style: IconButton.styleFrom(
        backgroundColor: item.isSelected ? colorScheme.secondaryContainer : colorScheme.surfaceContainer,
        foregroundColor: item.isSelected ? colorScheme.onSecondaryContainer : colorScheme.onSurfaceVariant,
        tapTargetSize: .padded,
      ),
      isSelected: item.isSelected,
      onPressed: item.onPressed,
      tooltip: item.label,
      icon: item.badgeCount != null ? Badge.count(count: item.badgeCount!, child: icon) : icon,
      selectedIcon: Icon(item.selectedIcon ?? item.icon),
    );

    return item.animate
        ? AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            switchInCurve: _kAnimationCurve,
            switchOutCurve: _kAnimationCurve,
            child: button,
          )
        : button;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableExtent = direction == .horizontal ? constraints.maxWidth : constraints.maxHeight;

        final shouldCollapse = availableExtent.isFinite && availableExtent < _kCollapseBreakpoint;

        return Flex(
          direction: direction,
          mainAxisSize: .min,
          children: [
            _BottomToolbar(
              shouldCollapse: shouldCollapse,
              direction: direction,
              menuAnchorOffset: menuAnchorOffset,
              separatorBuilder: separatorBuilder,
              iconButtonBuilder: iconButtonBuilder,
              children: children,
            ),
            if (floatingActionButton != null)
              TweenAnimationBuilder<double>(
                tween: Tween(end: showFab ? 1.0 : 0.0),
                duration: _kAnimationDuration,
                curve: _kAnimationCurve,
                child: Padding(
                  padding: EdgeInsetsDirectional.only(
                    start: direction == .horizontal ? 8.0 : 0.0,
                    top: direction == .vertical ? 8.0 : 0.0,
                  ),
                  child: floatingActionButton,
                ),
                builder: (context, visibility, child) =>
                    _CollapsingChild(direction: direction, active: showFab, visibility: visibility, child: child!),
              ),
          ],
        );
      },
    );
  }
}

class const _BottomToolbar({
  required final bool shouldCollapse,
  required final Axis direction,
  final Offset? menuAnchorOffset,
  required final ToolbarSeparatorBuilder separatorBuilder,
  required final ToolbarIconButtonBuilder iconButtonBuilder,
  required final List<ToolbarItem> children,
}) extends StatefulWidget {
  @override
  State<_BottomToolbar> createState() => _BottomToolbarState();
}

class _BottomToolbarState extends State<_BottomToolbar> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _collapseAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: _kAnimationDuration,
      value: widget.shouldCollapse ? 1.0 : 0.0,
    );
    _collapseAnimation = CurvedAnimation(parent: _controller, curve: _kAnimationCurve);
  }

  @override
  void didUpdateWidget(covariant _BottomToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.shouldCollapse != widget.shouldCollapse) {
      widget.shouldCollapse ? _controller.forward() : _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final fixedWidgets = <Widget>[];
    final collapsibleItems = <ToolbarCollapsibleItem>[];

    for (final item in widget.children) {
      switch (item) {
        case ToolbarCollapsibleItem():
          collapsibleItems.add(item);

        case ToolbarSeparator():
          fixedWidgets.add(widget.separatorBuilder(context, widget.direction, item));

        case ToolbarIconButton():
          fixedWidgets.add(widget.iconButtonBuilder(context, item));
      }
    }

    final overflowButton = collapsibleItems.isNotEmpty
        ? _OverflowMenuButton(
            direction: widget.direction,
            menuAnchorOffset: widget.menuAnchorOffset,
            items: collapsibleItems,
          )
        : null;

    return Container(
      padding: const EdgeInsets.all(12.0),
      width: widget.direction == .vertical ? 64.0 : null,
      height: widget.direction == .horizontal ? 64.0 : null,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(32.0),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(60), blurRadius: 4.0, offset: const Offset(0.0, 2.0))],
      ),
      child: Flex(
        direction: widget.direction,
        mainAxisSize: .min,
        spacing: _kItemSpacing,
        children: [
          ...fixedWidgets,
          if (collapsibleItems.isNotEmpty)
            RepaintBoundary(
              child: AnimatedBuilder(
                animation: _controller,
                child: Flex(
                  direction: widget.direction,
                  mainAxisSize: .min,
                  spacing: _kItemSpacing,
                  children: [for (final item in collapsibleItems) widget.iconButtonBuilder(context, item)],
                ),
                builder: (context, actionsGroup) =>
                    _buildCollapsibleGroup(actionsGroup: actionsGroup!, overflowButton: overflowButton!),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCollapsibleGroup({required Widget actionsGroup, required Widget overflowButton}) {
    switch (_controller.status) {
      case .dismissed:
        return actionsGroup;

      case .completed:
        return overflowButton;

      case .forward:
      case .reverse:
        return _buildTransitionGroup(actionsGroup, overflowButton);
    }
  }

  Widget _buildTransitionGroup(Widget actionsGroup, Widget overflowButton) {
    final t = _collapseAnimation.value;
    final actionsVisibility = 1.0 - t;
    final overflowVisibility = t;

    final spacing = _kItemSpacing * (actionsVisibility < overflowVisibility ? actionsVisibility : overflowVisibility);

    final actionsActive = actionsVisibility > overflowVisibility;
    final overflowActive = !actionsActive;

    return Flex(
      direction: widget.direction,
      mainAxisSize: .min,
      children: [
        _CollapsingChild(
          direction: widget.direction,
          active: actionsActive,
          visibility: actionsVisibility,
          child: actionsGroup,
        ),
        SizedBox(
          width: widget.direction == .horizontal ? spacing : 0.0,
          height: widget.direction == .vertical ? spacing : 0.0,
        ),
        _CollapsingChild(
          direction: widget.direction,
          active: overflowActive,
          visibility: overflowVisibility,
          child: overflowButton,
        ),
      ],
    );
  }
}

class const _CollapsingChild({
  required final Axis direction,
  required final bool active,
  required final double visibility,
  required final Widget child,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !active,
      child: ExcludeSemantics(
        excluding: !active,
        child: Opacity(
          opacity: visibility,
          child: Align(
            alignment: direction == .horizontal ? .centerStart : .topCenter,
            widthFactor: direction == .horizontal ? visibility : 1.0,
            heightFactor: direction == .vertical ? visibility : 1.0,
            child: child,
          ),
        ),
      ),
    );
  }
}

class const _OverflowMenuButton({
  required final Axis direction,
  final Offset? menuAnchorOffset,
  required final List<ToolbarCollapsibleItem> items,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textDirection = Directionality.of(context);

    final sign = textDirection == TextDirection.ltr ? 1.0 : -1.0;

    final dx = (direction == Axis.horizontal ? 0.0 : 56.0) * sign;
    final dy = direction == Axis.horizontal ? 16.0 : -88.0;

    var hasBadge = false;

    return Directionality(
      textDirection: TextDirection.values[(textDirection.index + 1) % TextDirection.values.length],
      child: MenuAnchor(
        alignmentOffset: menuAnchorOffset ?? Offset(dx, dy),
        animated: true,
        menuChildren: List.generate(items.length, (index) {
          final item = items[index];

          hasBadge = hasBadge || item.badgeCount != null;

          return Directionality(
            textDirection: textDirection,
            child: MenuItemButton(
              onPressed: item.onPressed,
              leadingIcon: Icon(item.icon),
              trailingIcon: item.badgeCount != null ? Badge.count(count: item.badgeCount!) : null,
              child: Text(item.label),
            ),
          );
        }),
        builder: (context, controller, child) {
          final icon = const Icon(Symbols.more_vert_rounded);

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Directionality(
              textDirection: textDirection,
              child: IconButton(
                key: ValueKey(controller.isOpen),
                style: IconButton.styleFrom(
                  backgroundColor: controller.isOpen ? colorScheme.secondaryContainer : colorScheme.surfaceContainer,
                  foregroundColor: controller.isOpen ? colorScheme.onSecondaryContainer : colorScheme.onSurfaceVariant,
                  // fixedSize: Size.square(48.0),
                ),
                onPressed: () => controller.isOpen ? controller.close() : controller.open(),
                tooltip: 'More actions',
                icon: hasBadge ? Badge(child: icon) : icon,
              ),
            ),
          );
        },
      ),
    );
  }
}
