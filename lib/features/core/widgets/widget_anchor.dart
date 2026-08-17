import 'package:material_ui/material_ui.dart';

const _kDefaultAnimationStyle = AnimationStyle(
  duration: Duration(milliseconds: 200),
  reverseDuration: Duration(milliseconds: 150),
  curve: Curves.easeOutCubic,
  reverseCurve: Curves.easeInCubic,
);

typedef WidgetAnchorBuilder = Widget Function(BuildContext context, WidgetAnchorController controller, Widget? child);

abstract interface class WidgetAnchorController {
  bool get isOpen;

  AnimationStatus get animationStatus;

  void toggle();
  void open();
  void close();
}

class const WidgetAnchor({
  super.key,
  required final Alignment targetAlignment,
  required final Alignment followerAlignment,
  final Offset alignmentOffset = .zero,
  final Widget? child,
  required final WidgetBuilder widgetBuilder,
  required final WidgetAnchorBuilder builder,
  final AnimationStyle animationStyle = _kDefaultAnimationStyle,
}) extends StatefulWidget {
  @override
  State<WidgetAnchor> createState() => _WidgetAnchorState();
}

class _WidgetAnchorState extends State<WidgetAnchor>
    with SingleTickerProviderStateMixin
    implements WidgetAnchorController {
  final _overlayController = OverlayPortalController(debugLabel: 'Anchored popover');

  final _layerLink = LayerLink();

  late final AnimationController _animationController;
  late final CurvedAnimation _animation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: widget.animationStyle.duration,
      reverseDuration: widget.animationStyle.reverseDuration,
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: widget.animationStyle.curve ?? Curves.linear,
      reverseCurve: widget.animationStyle.reverseCurve ?? widget.animationStyle.curve ?? Curves.linear,
    );

    _scaleAnimation = Tween<double>(begin: 0.94, end: 1.0).animate(_animation);

    _animationController.addStatusListener(_handleAnimationStatusChanged);
  }

  @override
  void didUpdateWidget(WidgetAnchor oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.animationStyle != widget.animationStyle) {
      _animationController
        ..duration = widget.animationStyle.duration
        ..reverseDuration = widget.animationStyle.reverseDuration;

      _animation
        ..curve = widget.animationStyle.curve ?? Curves.linear
        ..reverseCurve = widget.animationStyle.reverseCurve ?? widget.animationStyle.curve ?? Curves.linear;
    }
  }

  @override
  void dispose() {
    _animationController
      ..removeStatusListener(_handleAnimationStatusChanged)
      ..dispose();

    _animation.dispose();

    super.dispose();
  }

  @override
  bool get isOpen => _overlayController.isShowing;

  @override
  AnimationStatus get animationStatus => _animationController.status;

  @override
  void toggle() => _animationController.isForwardOrCompleted ? close() : open();

  @override
  void open() {
    if (!_overlayController.isShowing) _overlayController.show();
    _animationController.forward();
  }

  @override
  void close() {
    if (!_overlayController.isShowing) return;
    _animationController.reverse();
  }

  void _handleAnimationStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.dismissed && _overlayController.isShowing) {
      _overlayController.hide();
    }

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: _overlayController,
      overlayChildBuilder: _buildOverlay,
      child: CompositedTransformTarget(link: _layerLink, child: widget.builder(context, this, widget.child)),
    );
  }

  Widget _buildOverlay(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        children: [
          Positioned.fill(
            child: ModalBarrier(
              color: Colors.transparent,
              dismissible: true,
              onDismiss: close,
              semanticsLabel: 'Close popover',
            ),
          ),
          CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            targetAnchor: widget.targetAlignment,
            followerAnchor: widget.followerAlignment,
            offset: widget.alignmentOffset,
            child: AnimatedBuilder(
              animation: _animation,
              child: FadeTransition(
                opacity: _animation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  alignment: widget.followerAlignment,
                  child: widget.widgetBuilder(context),
                ),
              ),
              builder: (context, child) {
                final isClosing = _animationController.status == AnimationStatus.reverse;

                return IgnorePointer(
                  ignoring: isClosing,
                  child: ExcludeSemantics(excluding: isClosing, child: child),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
