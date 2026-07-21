import 'package:flutter/material.dart';

const _kCollapseBreakpoint = 600.0;

const _kItemSpacing = 4.0;

const _kAnimationDuration = Duration(milliseconds: 300);
const _kAnimationCurve = Curves.easeInOutCubicEmphasized;

typedef ToolbarSeparatorBuilder = Widget Function(BuildContext context, Axis direction, ToolbarSeparator item);

typedef ToolbarIconButtonBuilder = Widget Function(BuildContext context, ToolbarIconButton item);

sealed class ToolbarItem {
  const ToolbarItem({this.key});

  final Key? key;
}

class ToolbarSeparator extends ToolbarItem {}

class ToolbarIconButton extends ToolbarItem {
  const ToolbarIconButton({
    super.key,
    this.animate = false,
    required this.onPressed,
    required this.icon,
    this.selectedIcon,
    this.isSelected = false,
    required this.label,
  });

  final bool animate;

  final VoidCallback? onPressed;

  final IconData icon;
  final IconData? selectedIcon;

  final bool isSelected;

  final String label;
}

class ToolbarCollapsibleItem extends ToolbarIconButton {
  const ToolbarCollapsibleItem({
    super.key,
    super.animate = false,
    required super.onPressed,
    required super.icon,
    super.selectedIcon,
    super.isSelected = false,
    required super.label,
  });
}

class Toolbar extends StatelessWidget {
  const Toolbar({
    super.key,
    this.direction = Axis.horizontal,
    this.showFab = false,
    this.floatingActionButton,
    this.separatorBuilder = _buildSeparator,
    this.iconButtonBuilder = _buildIconButton,
    required this.children,
  }) : assert(!showFab || floatingActionButton != null);

  final Axis direction;

  final bool showFab;
  final Widget? floatingActionButton;

  final ToolbarSeparatorBuilder separatorBuilder;
  final ToolbarIconButtonBuilder iconButtonBuilder;

  final List<ToolbarItem> children;

  static Widget _buildSeparator(BuildContext context, Axis direction, ToolbarSeparator item) {
    return SizedBox(
      width: direction == Axis.vertical ? 48.0 : null,
      height: direction == Axis.horizontal ? 48.0 : null,
      child: direction == Axis.horizontal
          ? VerticalDivider(width: 20.0, thickness: 1.0, indent: 8.0, endIndent: 8.0)
          : Divider(height: 20.0, thickness: 1.0, indent: 8.0, endIndent: 8.0),
    );
  }

  static Widget _buildIconButton(BuildContext context, ToolbarIconButton item) {
    final colorScheme = Theme.of(context).colorScheme;

    final button = IconButton(
      key: item.key,
      style: IconButton.styleFrom(
        backgroundColor: item.isSelected ? colorScheme.secondaryContainer : colorScheme.surfaceContainer,
        foregroundColor: item.isSelected ? colorScheme.onSecondaryContainer : colorScheme.onSurfaceVariant,
        tapTargetSize: MaterialTapTargetSize.padded,
      ),
      isSelected: item.isSelected,
      onPressed: item.onPressed,
      tooltip: item.label,
      icon: Icon(item.icon),
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
        final availableExtent = direction == Axis.horizontal ? constraints.maxWidth : constraints.maxHeight;

        final shouldCollapse = availableExtent.isFinite && availableExtent < _kCollapseBreakpoint;

        return Flex(
          direction: direction,
          mainAxisSize: MainAxisSize.min,
          children: [
            _BottomToolbar(
              shouldCollapse: shouldCollapse,
              direction: direction,
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
                    start: direction == Axis.horizontal ? 8.0 : 0.0,
                    top: direction == Axis.vertical ? 8.0 : 0.0,
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

class _BottomToolbar extends StatefulWidget {
  const _BottomToolbar({
    required this.shouldCollapse,
    required this.direction,
    required this.separatorBuilder,
    required this.iconButtonBuilder,
    required this.children,
  });

  final bool shouldCollapse;

  final Axis direction;

  final ToolbarSeparatorBuilder separatorBuilder;
  final ToolbarIconButtonBuilder iconButtonBuilder;

  final List<ToolbarItem> children;

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
        ? _OverflowMenuButton(direction: widget.direction, items: collapsibleItems)
        : null;

    return Container(
      padding: const EdgeInsets.all(12.0),
      width: widget.direction == Axis.vertical ? 64.0 : null,
      height: widget.direction == Axis.horizontal ? 64.0 : null,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(32.0),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(60), blurRadius: 4.0, offset: const Offset(0.0, 2.0))],
      ),
      child: Flex(
        direction: widget.direction,
        mainAxisSize: MainAxisSize.min,
        spacing: _kItemSpacing,
        children: [
          ...fixedWidgets,
          if (collapsibleItems.isNotEmpty)
            RepaintBoundary(
              child: AnimatedBuilder(
                animation: _controller,
                child: Flex(
                  direction: widget.direction,
                  mainAxisSize: MainAxisSize.min,
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
      case AnimationStatus.dismissed:
        return actionsGroup;

      case AnimationStatus.completed:
        return overflowButton;

      case AnimationStatus.forward:
      case AnimationStatus.reverse:
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
      mainAxisSize: MainAxisSize.min,
      children: [
        _CollapsingChild(
          direction: widget.direction,
          active: actionsActive,
          visibility: actionsVisibility,
          child: actionsGroup,
        ),
        SizedBox(
          width: widget.direction == Axis.horizontal ? spacing : 0.0,
          height: widget.direction == Axis.vertical ? spacing : 0.0,
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

class _CollapsingChild extends StatelessWidget {
  const _CollapsingChild({
    required this.direction,
    required this.active,
    required this.visibility,
    required this.child,
  });

  final Axis direction;

  final bool active;
  final double visibility;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !active,
      child: ExcludeSemantics(
        excluding: !active,
        child: Opacity(
          opacity: visibility,
          child: Align(
            alignment: direction == Axis.horizontal ? AlignmentDirectional.centerStart : Alignment.topCenter,
            widthFactor: direction == Axis.horizontal ? visibility : 1.0,
            heightFactor: direction == Axis.vertical ? visibility : 1.0,
            child: child,
          ),
        ),
      ),
    );
  }
}

class _OverflowMenuButton extends StatelessWidget {
  const _OverflowMenuButton({required this.direction, required this.items});

  final Axis direction;

  final List<ToolbarCollapsibleItem> items;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textDirection = Directionality.of(context);

    final sign = textDirection == TextDirection.ltr ? -1.0 : 1.0;

    final dx = (direction == Axis.horizontal ? 80.0 : 142.0) * sign;
    final dy = direction == Axis.horizontal ? 16.0 : -88.0;

    return MenuAnchor(
      alignmentOffset: Offset(dx, dy),
      animated: true,
      menuChildren: [
        for (final item in items)
          MenuItemButton(onPressed: item.onPressed, leadingIcon: Icon(item.icon), child: Text(item.label)),
      ],
      builder: (context, controller, child) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: IconButton(
          key: ValueKey(controller.isOpen),
          style: IconButton.styleFrom(
            backgroundColor: controller.isOpen ? colorScheme.secondaryContainer : colorScheme.surfaceContainer,
            foregroundColor: controller.isOpen ? colorScheme.onSecondaryContainer : colorScheme.onSurfaceVariant,
            // fixedSize: Size.square(48.0),
          ),
          onPressed: () => controller.isOpen ? controller.close() : controller.open(),
          tooltip: 'More actions',
          icon: const Icon(Icons.more_vert_rounded),
        ),
      ),
    );
  }
}
