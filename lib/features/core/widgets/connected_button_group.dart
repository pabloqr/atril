import 'package:atril/domain/models/settings/app_settings.dart';
import 'package:atril/features/core/theme/atril_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

/// Data describing a button of a [ConnectedButtonGroup].
class ButtonGroupItem<T> {
  /// Construct a [ButtonGroupItem].
  ///
  /// One of [icon] or [label] must be non-null.
  const ButtonGroupItem({required this.value, this.icon, this.label, this.tooltip, this.enabled = true})
    : assert(icon != null || label != null);

  /// Value used to identify the button.
  ///
  /// This value must be unique across all buttons in a [ConnectedButtonGroup].
  final T value;

  /// Optional icon displayed in the button.
  final Widget? icon;

  /// Optional label displayed in the button.
  final Widget? label;

  /// Optional tooltip for the button.
  final String? tooltip;

  /// Determines if the button is available for selection.
  final bool enabled;
}

class ConnectedButtonGroup<T> extends StatefulWidget {
  const ConnectedButtonGroup({
    super.key,
    required this.buttons,
    required this.selected,
    this.onSelectionChanged,
    this.multiSelectionEnabled = false,
    this.emptySelectionAllowed = false,
  }) : assert(buttons.length > 0),
       assert(selected.length > 0 || emptySelectionAllowed),
       assert(selected.length < 2 || multiSelectionEnabled);

  final List<ButtonGroupItem<T>> buttons;

  final Set<T> selected;

  final void Function(Set<T>)? onSelectionChanged;

  final bool multiSelectionEnabled;

  final bool emptySelectionAllowed;

  @override
  State<ConnectedButtonGroup<T>> createState() => _ConnectedButtonGroupState<T>();
}

class _ConnectedButtonGroupState<T> extends State<ConnectedButtonGroup<T>> {
  bool get _enabled => widget.onSelectionChanged != null;
  // ignore: unused_field
  bool _hovering = false;
  // ignore: unused_field
  bool _focused = false;
  // ignore: unused_element
  bool get _selected => widget.selected.isNotEmpty;

  // Set<WidgetState> get _states => <WidgetState>{
  //   if (!_enabled) WidgetState.disabled,
  //   if (_hovering) WidgetState.hovered,
  //   if (_focused) WidgetState.focused,
  //   if (_selected) WidgetState.selected,
  // };

  @visibleForTesting
  final Map<ButtonGroupItem<T>, WidgetStatesController> statesControllers =
      <ButtonGroupItem<T>, WidgetStatesController>{};

  @override
  void didUpdateWidget(covariant ConnectedButtonGroup<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget != widget) {
      statesControllers.removeWhere((ButtonGroupItem<T> button, WidgetStatesController controller) {
        if (widget.buttons.contains(button)) {
          return false;
        } else {
          controller.dispose();
          return true;
        }
      });
    }
  }

  @override
  void dispose() {
    for (final controller in statesControllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  void _handleOnPressed(T buttonValue) {
    if (!_enabled) {
      return;
    }
    final onlySelectedSegment = widget.selected.length == 1 && widget.selected.contains(buttonValue);
    final validChange = widget.emptySelectionAllowed || !onlySelectedSegment;
    if (validChange) {
      final toggle = widget.multiSelectionEnabled || (widget.emptySelectionAllowed && onlySelectedSegment);
      final pressedSegment = <T>{buttonValue};
      late final Set<T> updatedSelection;
      if (toggle) {
        updatedSelection = widget.selected.contains(buttonValue)
            ? widget.selected.difference(pressedSegment)
            : widget.selected.union(pressedSegment);
      } else {
        updatedSelection = pressedSegment;
      }
      if (!setEquals(updatedSelection, widget.selected)) {
        widget.onSelectionChanged!(updatedSelection);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    BorderRadius calculateBorderRadius(int index) {
      if (index == 0) return const BorderRadius.horizontal(left: Radius.circular(48.0), right: Radius.circular(8.0));

      if (index == widget.buttons.length - 1) {
        return const BorderRadius.horizontal(left: Radius.circular(8.0), right: Radius.circular(48.0));
      }

      return const BorderRadius.all(Radius.circular(8.0));
    }

    Widget buttonFor(int index) {
      final item = widget.buttons[index];

      final label = item.label ?? item.icon ?? const SizedBox.shrink();

      final buttonSelected = widget.selected.contains(item.value);

      final icon = item.label != null ? item.icon : null;

      final controller = statesControllers.putIfAbsent(item, () => WidgetStatesController());
      controller.update(WidgetState.selected, buttonSelected);

      var content = label;
      if (icon != null) {
        content = Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            icon,
            Flexible(child: label),
          ],
        );
      }

      final shape = RoundedRectangleBorder(
        borderRadius: buttonSelected ? BorderRadius.circular(48.0) : calculateBorderRadius(index),
      );
      final style = FilledButton.styleFrom(
        minimumSize: const Size(56.0, 52.0),
        padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 14.0),
        shape: shape,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      );

      final button = buttonSelected
          ? FilledButton(
              statesController: controller,
              style: style,
              onHover: (bool hovering) => setState(() => _hovering = hovering),
              onFocusChange: (bool focused) => setState(() => _focused = focused),
              onPressed: _enabled && item.enabled ? () => _handleOnPressed(item.value) : null,
              child: content,
            )
          : FilledButton.tonal(
              statesController: controller,
              style: style,
              onHover: (bool hovering) => setState(() => _hovering = hovering),
              onFocusChange: (bool focused) => setState(() => _focused = focused),
              onPressed: _enabled && item.enabled ? () => _handleOnPressed(item.value) : null,
              child: content,
            );

      final buttonWithTooltip = button.tooltip != null ? Tooltip(message: button.tooltip, child: button) : button;

      return Expanded(
        child: MergeSemantics(
          child: Semantics(
            selected: buttonSelected,
            inMutuallyExclusiveGroup: widget.multiSelectionEnabled ? null : true,
            child: buttonWithTooltip,
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.max,
      spacing: 2.0,
      children: [for (var i = 0; i < widget.buttons.length; ++i) buttonFor(i)],
    );
  }
}

@Preview(name: 'Connected button group', group: 'Core', size: Size(360, 112))
Widget connectedButtonGroupPreview() {
  return MaterialApp(
    theme: AtrilTheme.light(),
    home: Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ConnectedButtonGroup<LibrarySortOrder>(
          buttons: [
            ButtonGroupItem<LibrarySortOrder>(
              value: LibrarySortOrder.title,
              icon: const Icon(Icons.sort_by_alpha_rounded),
              label: const Text('Title'),
            ),
            ButtonGroupItem<LibrarySortOrder>(
              value: LibrarySortOrder.artist,
              icon: const Icon(Icons.person_rounded),
              label: const Text('Artist'),
            ),
          ],
          selected: {LibrarySortOrder.title},
          onSelectionChanged: (p0) {},
        ),
      ),
    ),
  );
}
