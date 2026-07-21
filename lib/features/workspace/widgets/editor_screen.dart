import 'package:atril/features/workspace/view_model/editor_view_model.dart';
import 'package:flutter/material.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key, required this.viewModel});

  final EditorViewModel viewModel;

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  int _line = 0;
  int _column = 0;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(text: widget.viewModel.source);
    _focusNode = FocusNode();

    _controller.addListener(_handleEditorChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      widget.viewModel.start = widget.viewModel.start.clamp(0, _controller.text.length);
      widget.viewModel.end = widget.viewModel.end.clamp(0, _controller.text.length);

      _controller.selection = TextSelection(baseOffset: widget.viewModel.start, extentOffset: widget.viewModel.end);
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleEditorChanged)
      ..dispose();
    _focusNode.dispose();

    super.dispose();
  }

  void _handleEditorChanged() {
    final selection = _controller.selection;

    if (!selection.isValid) {
      return;
    }

    widget.viewModel.start = selection.start.clamp(0, _controller.text.length);
    widget.viewModel.end = selection.end.clamp(0, _controller.text.length);

    final textBeforeCursor = _controller.text.substring(0, widget.viewModel.start);
    final lines = textBeforeCursor.split('\n');

    setState(() {
      _line = lines.length;
      _column = lines.last.length + 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final charsText = widget.viewModel.start != widget.viewModel.end
        ? '${widget.viewModel.end - widget.viewModel.start} of ${_controller.text.length} characters'
        : '${_controller.text.length} characters';

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
                focusNode: _focusNode,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(28.0),
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  border: InputBorder.none,
                ),
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
