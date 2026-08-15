import 'package:atril/data/services/song/source_editor.dart';
import 'package:atril/domain/models/song/parse_issue.dart';
import 'package:atril/features/workspace/view_model/editor_view_model.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key, required this.viewModel, required this.focusNode, required this.historyController});

  final EditorViewModel viewModel;

  final FocusNode focusNode;
  final UndoHistoryController historyController;

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> with AutomaticKeepAliveClientMixin {
  late final TextEditingController _controller;

  bool _updatingControllerFromViewModel = false;

  int _line = 0;
  int _column = 0;
  int _selectedCharacterCount = 0;
  int _characterCount = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController.fromValue(
      TextEditingValue(
        text: widget.viewModel.source,
        selection: _selectionToTextSelection(widget.viewModel.selection, widget.viewModel.source.length),
      ),
    );

    widget.viewModel.addListener(_handleViewModelChanged);
    _controller.addListener(_handleControllerChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (!_controller.selection.isValid) {
        _controller.selection = const TextSelection.collapsed(offset: 0);
      }

      _updateSelection(_controller.value);

      widget.focusNode.requestFocus();
    });
  }

  @override
  void didUpdateWidget(EditorScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.viewModel == widget.viewModel) return;

    oldWidget.viewModel.removeListener(_handleViewModelChanged);
    widget.viewModel.addListener(_handleViewModelChanged);

    _handleViewModelChanged();
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_handleViewModelChanged);
    _controller
      ..removeListener(_handleControllerChanged)
      ..dispose();

    super.dispose();
  }

  void _handleViewModelChanged() {
    final source = widget.viewModel.source;
    final nextValue = TextEditingValue(
      text: source,
      selection: _selectionToTextSelection(widget.viewModel.selection, source.length),
    );

    if (_controller.value == nextValue) return;

    _updatingControllerFromViewModel = true;
    try {
      _controller.value = nextValue;
    } finally {
      _updatingControllerFromViewModel = false;
    }

    _updateSelection(nextValue);
  }

  void _handleControllerChanged() {
    if (_updatingControllerFromViewModel) return;

    final value = _controller.value;

    widget.viewModel.update(value.text, _textSelectionToSelection(value.selection, value.text.length));

    _updateSelection(value);
  }

  void _updateSelection(TextEditingValue value) {
    final selection = value.selection;
    if (!selection.isValid) {
      setState(() {
        _characterCount = value.text.length;
        _selectedCharacterCount = 0;
      });

      return;
    }

    final cursorOffset = selection.extentOffset.clamp(0, value.text.length);

    final textBeforeCursor = value.text.substring(0, cursorOffset);
    final lines = textBeforeCursor.split('\n');

    setState(() {
      _line = lines.length;
      _column = lines.last.length + 1;
      _characterCount = value.text.length;
      _selectedCharacterCount = selection.end - selection.start;
    });
  }

  Selection _textSelectionToSelection(TextSelection selection, int sourceLength) {
    if (!selection.isValid) {
      return const NoSelection();
    }

    final start = selection.start.clamp(0, sourceLength);
    final end = selection.end.clamp(0, sourceLength);

    if (start == end) {
      return PositionSelection(selection.extentOffset.clamp(0, sourceLength));
    }

    return RangeSelection(start, end);
  }

  TextSelection _selectionToTextSelection(Selection selection, int sourceLength) {
    return switch (selection) {
      NoSelection() => const TextSelection.collapsed(offset: -1),
      PositionSelection(:final position) => TextSelection.collapsed(offset: position.clamp(0, sourceLength)),
      RangeSelection(:final start, :final end) => TextSelection(
        baseOffset: start.clamp(0, sourceLength),
        extentOffset: end.clamp(0, sourceLength),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final charsText = _selectedCharacterCount > 0
        ? '$_selectedCharacterCount of $_characterCount characters'
        : '$_characterCount characters';

    final issue = widget.viewModel.activeIssue;
    final issueNumber = widget.viewModel.activeIssueNumber;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOutCubicEmphasized,
      padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Column(
        spacing: 2.0,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28.0), bottom: Radius.circular(2.0)),
              ),
              child: TextField(
                controller: _controller,
                focusNode: widget.focusNode,
                undoController: widget.historyController,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(28.0),
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  border: InputBorder.none,
                ),
                style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
                expands: true,
                minLines: null,
                maxLines: null,
                // onChanged: (value) => _handleEditorChanged(),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(28.0, 12.0, 28.0, 16.0),
            width: double.infinity,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainer,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(2.0), bottom: Radius.circular(28.0)),
            ),
            child: DefaultTextStyle.merge(
              style: textTheme.labelMedium?.copyWith(color: colorScheme.onSurfaceVariant),
              child: Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: [
                  Text('Line $_line · Column $_column'),
                  SizedBox(height: 16.0, child: const VerticalDivider(width: 16.0, thickness: 1.0)),
                  Text(charsText),
                  if (issue != null) ...[
                    const SizedBox(height: 16.0, child: VerticalDivider(width: 16.0, thickness: 1.0)),
                    Row(
                      mainAxisAlignment: .start,
                      mainAxisSize: .min,
                      crossAxisAlignment: .start,
                      spacing: 8.0,
                      children: [
                        Icon(
                          issue.severity == .warning ? Symbols.warning_amber_rounded : Symbols.error_outline_rounded,
                          size: 18.0,
                          color: issue.severity == .warning ? colorScheme.tertiary : colorScheme.error,
                        ),
                        Flexible(
                          child: Text(
                            '$issueNumber of ${widget.viewModel.issuesCount}'
                            ' · ${issue.code.message}: ${issue.message}',
                            style: textTheme.labelMedium?.copyWith(
                              color: issue.severity == .warning ? colorScheme.tertiary : colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
