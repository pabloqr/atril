import 'package:flutter/material.dart';

const _kItemSpacing = 4.0;

const _kAnimationDuration = Duration(milliseconds: 300);
const _kAnimationCurve = Curves.easeInOutCubicEmphasized;

final class BottomToolbarCollapsibleItem {
  BottomToolbarCollapsibleItem({required this.icon, required this.label, required this.onPressed});

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
}

class BottomToolbar extends StatelessWidget {
  const BottomToolbar({
    super.key,
    this.showFab = false,
    this.onFabTap,
    this.fabChild,
    required this.collapsibleItems,
    required this.children,
  }) : assert(!showFab || (fabChild != null && onFabTap != null));

  final bool showFab;

  final VoidCallback? onFabTap;
  final Widget? fabChild;

  final List<BottomToolbarCollapsibleItem> collapsibleItems;

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _BottomToolbar(collapsibleItems: collapsibleItems, children: children),
        if (fabChild != null)
          TweenAnimationBuilder<double>(
            tween: Tween(end: showFab ? 1.0 : 0.0),
            duration: _kAnimationDuration,
            curve: _kAnimationCurve,
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: FloatingActionButton(onPressed: onFabTap, child: fabChild),
            ),
            builder: (context, visibility, child) => IgnorePointer(
              ignoring: !showFab,
              child: ExcludeSemantics(
                excluding: !showFab,
                child: _CollapsingChild(visibility: visibility, child: child!),
              ),
            ),
          ),
      ],
    );
  }
}

class _BottomToolbar extends StatefulWidget {
  const _BottomToolbar({required this.collapsibleItems, required this.children});

  final List<BottomToolbarCollapsibleItem> collapsibleItems;
  final List<Widget> children;

  @override
  State<_BottomToolbar> createState() => _BottomToolbarState();
}

class _BottomToolbarState extends State<_BottomToolbar> with SingleTickerProviderStateMixin {
  static const _collapseThreshold = 600.0;

  late final AnimationController _controller;
  late final CurvedAnimation _collapseAnimation;

  bool _collapsed = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _kAnimationDuration);
    _collapseAnimation = CurvedAnimation(parent: _controller, curve: _kAnimationCurve);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final shouldCollapse = MediaQuery.sizeOf(context).width < _collapseThreshold;

    if (!_initialized) {
      _initialized = true;
      _collapsed = shouldCollapse;
      _controller.value = shouldCollapse ? 1.0 : 0.0;
      return;
    }

    if (shouldCollapse != _collapsed) {
      _collapsed = shouldCollapse;
      shouldCollapse ? _controller.forward() : _controller.reverse();
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

    return Container(
      padding: const EdgeInsets.all(8.0),
      height: 64.0,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(32.0),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(60), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: IconButtonTheme(
        data: IconButtonThemeData(style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.padded)),
        child: AnimatedSize(
          duration: _kAnimationDuration,
          curve: _kAnimationCurve,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: _kItemSpacing,
            children: [
              ...widget.children,
              if (widget.collapsibleItems.isNotEmpty)
                RepaintBoundary(
                  child: AnimatedBuilder(animation: _controller, builder: (context, _) => _buildCollapsibleGroup()),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsibleGroup() {
    switch (_controller.status) {
      case AnimationStatus.dismissed:
        return Row(
          mainAxisSize: MainAxisSize.min,
          spacing: _kItemSpacing,
          children: [for (final item in widget.collapsibleItems) _buildActionButton(item)],
        );

      case AnimationStatus.completed:
        return _OverflowMenuButton(items: widget.collapsibleItems);

      case AnimationStatus.forward:
      case AnimationStatus.reverse:
        return _buildTransitionGroup();
    }
  }

  Widget _buildActionButton(BottomToolbarCollapsibleItem item, [Key? key]) {
    return IconButton(key: key, onPressed: item.onPressed, icon: Icon(item.icon));
  }

  Widget _buildTransitionGroup() {
    final t = _collapseAnimation.value;
    final actionsVisibility = 1.0 - t;
    final overflowVisibility = t;

    final actionsGroup = Row(
      mainAxisSize: MainAxisSize.min,
      spacing: _kItemSpacing,
      children: [for (final item in widget.collapsibleItems) _buildActionButton(item)],
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _CollapsingChild(visibility: actionsVisibility, child: actionsGroup),
        SizedBox(
          width: _kItemSpacing * (actionsVisibility < overflowVisibility ? actionsVisibility : overflowVisibility),
        ),
        _CollapsingChild(
          visibility: overflowVisibility,
          child: _OverflowMenuButton(items: widget.collapsibleItems),
        ),
      ],
    );
  }
}

class _CollapsingChild extends StatelessWidget {
  const _CollapsingChild({required this.visibility, required this.child});

  final double visibility;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: visibility,
      child: Align(alignment: Alignment.centerLeft, widthFactor: visibility, heightFactor: 1.0, child: child),
    );
  }
}

class _OverflowMenuButton extends StatelessWidget {
  const _OverflowMenuButton({required this.items});

  final List<BottomToolbarCollapsibleItem> items;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return MenuAnchor(
      animated: true,
      consumeOutsideTap: true,
      alignmentOffset: const Offset(-80.0, 12.0),
      menuChildren: [
        for (final action in items)
          MenuItemButton(onPressed: action.onPressed, leadingIcon: Icon(action.icon), child: Text(action.label)),
      ],
      builder: (context, controller, child) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: IconButton(
          key: ValueKey(controller.isOpen),
          style: IconButton.styleFrom(
            backgroundColor: controller.isOpen ? colorScheme.secondaryContainer : colorScheme.surfaceContainer,
          ),
          color: controller.isOpen ? colorScheme.onSecondaryContainer : colorScheme.onSurfaceVariant,
          onPressed: () => controller.isOpen ? controller.close() : controller.open(),
          icon: const Icon(Icons.more_vert_rounded),
        ),
      ),
    );
  }
}
