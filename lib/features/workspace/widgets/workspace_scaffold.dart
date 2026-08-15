import 'package:atril/core/extensions/string.dart';
import 'package:atril/core/routing/routes.dart';
import 'package:atril/data/services/chord/chromatic_transposition.dart';
import 'package:atril/data/services/song/source_editor.dart';
import 'package:atril/domain/models/song.dart';
import 'package:atril/features/core/extensions/directive_type.dart';
import 'package:atril/features/core/utils/widget_utilities.dart';
import 'package:atril/features/core/widgets/dialog.dart';
import 'package:atril/features/core/widgets/fab_menu.dart';
import 'package:atril/features/core/widgets/toolbar.dart';
import 'package:atril/features/core/widgets/widget_anchor.dart';
import 'package:atril/features/workspace/view_model/editor_view_model.dart';
import 'package:atril/features/workspace/view_model/workspace_view_model.dart';
import 'package:atril/features/workspace/widgets/editor_screen.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';

const _kCompactBreakpoint = 600.0;

enum _WorkspacePage {
  editor,
  preview;

  String get title => switch (this) {
    _WorkspacePage.editor => 'Editor',
    _WorkspacePage.preview => 'Preview',
  };
}

class WorkspaceScaffold extends StatefulWidget {
  const WorkspaceScaffold({super.key, required this.viewModel, required this.editorViewModel});

  final WorkspaceViewModel viewModel;
  final EditorViewModel editorViewModel;

  @override
  State<WorkspaceScaffold> createState() => _WorkspaceScaffoldState();
}

class _WorkspaceScaffoldState extends State<WorkspaceScaffold> {
  late final PageController _pageController;
  var _selectedPage = _WorkspacePage.editor;

  late final FocusNode _focusNode;
  late final UndoHistoryController _historyController;

  final _filenameController = TextEditingController();

  int _transposeSemitones = 0;

  @override
  void initState() {
    super.initState();

    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

    _pageController = PageController(initialPage: _selectedPage.index);

    _focusNode = FocusNode();
    _historyController = UndoHistoryController();
  }

  @override
  void dispose() {
    _pageController.dispose();

    _focusNode.dispose();
    _historyController.dispose();

    _filenameController.dispose();

    SystemChrome.setPreferredOrientations([]);

    super.dispose();
  }

  bool get _isPreview => _selectedPage == _WorkspacePage.preview;

  void _closeWorkspace() => context.canPop() ? context.pop() : context.goNamed(AppRoutes.homeRoute.name);

  void _togglePage() {
    final target = _isPreview ? _WorkspacePage.editor : _WorkspacePage.preview;

    if (target == _WorkspacePage.preview) {
      FocusManager.instance.primaryFocus?.unfocus();
    }

    _pageController.animateToPage(
      target.index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubicEmphasized,
    );
  }

  void _handlePageChanged(int index) {
    final selectedTab = _WorkspacePage.values[index];

    if (selectedTab == _selectedPage) return;

    setState(() => _selectedPage = selectedTab);
  }

  String _messageFor(SourceEditRejection reason) {
    return switch (reason) {
      SourceEditRejection.noSelection => 'Place the cursor where you want to perform this action.',
      SourceEditRejection.invalidSelection => 'The current selection is no longer valid.',
      SourceEditRejection.multilineSelection => 'This action cannot be applied across multiple lines.',
      SourceEditRejection.directiveLine => 'Chords cannot be inserted in directive lines.',
      SourceEditRejection.unsupportedDirective => 'This directive cannot be inserted here.',
    };
  }

  void _handleInsertResult(SourceEditResult result, bool isCompact) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isPreview) return;
      _focusNode.requestFocus();

      if (result case SourceEditRejected(:final reason)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_messageFor(reason)),
            margin: isCompact ? .fromLTRB(16.0, 16.0, 16.0, 96.0) : null,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  void _handleTransposeResult(int semitones, String? error, bool isCompact) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isPreview) return;
      _focusNode.requestFocus();

      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            margin: isCompact ? .fromLTRB(16.0, 16.0, 16.0, 160.0) : null,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        setState(() => _transposeSemitones += semitones);
      }
    });
  }

  void _selectNextIssue(bool isCompact) {
    final selected = widget.editorViewModel.selectNextIssue();
    if (!selected) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isPreview) return;
      _focusNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel.load,
      builder: (context, child) {
        return Scaffold(
          appBar: _buildAppbar(context),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < _kCompactBreakpoint;

              return Stack(
                children: [
                  SafeArea(
                    child: Padding(
                      padding: .only(bottom: isCompact ? 88.0 : 0.0),
                      child: PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        onPageChanged: _handlePageChanged,
                        children: [
                          // const Center(child: Text('Editor')),
                          EditorScreen(
                            viewModel: widget.editorViewModel,
                            focusNode: _focusNode,
                            historyController: _historyController,
                          ),
                          const Center(child: Text('Preview')),
                        ],
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) => _ToolbarSlideTransition(
                        animation: animation,
                        isCompact: (child.key! as ValueKey<bool>).value,
                        child: child,
                      ),
                      child: Align(
                        key: ValueKey(isCompact),
                        alignment: isCompact ? .bottomCenter : .centerRight,
                        child: Padding(
                          padding: isCompact
                              ? const .fromLTRB(16.0, 0.0, 16.0, 24.0)
                              : const .fromLTRB(0.0, 16.0, 24.0, 16.0),
                          child: SafeArea(
                            child: ListenableBuilder(
                              listenable: widget.viewModel,
                              builder: (context, child) {
                                final dx = isCompact ? -72.0 : -4.0;
                                final dy = isCompact ? -4.0 : 236.0;

                                return WidgetAnchor(
                                  targetAlignment: isCompact ? .topRight : .topLeft,
                                  followerAlignment: isCompact ? .bottomRight : .bottomRight,
                                  alignmentOffset: Offset(dx, dy),
                                  child: isCompact
                                      ? FabMenu(
                                          fabTooltip: 'Add musical component',
                                          fabIcon: Symbols.music_note_add_rounded,
                                          items: [
                                            FabMenuItem(
                                              icon: Symbols.music_note_2_rounded,
                                              label: 'Add chord',
                                              onPressed: () {
                                                final result = widget.editorViewModel.insertChord();
                                                _handleInsertResult(result, isCompact);
                                              },
                                            ),
                                            FabMenuItem(
                                              icon: Symbols.data_object_rounded,
                                              label: 'Add directive',
                                              onPressed: () async {
                                                final selectedDirective = await showModalBottomSheet<DirectiveType>(
                                                  enableDrag: false,
                                                  isScrollControlled: true,
                                                  useSafeArea: true,
                                                  context: context,
                                                  builder: (context) => const _DirectivePickerSheet(),
                                                );

                                                if (selectedDirective == null) return;

                                                final result = widget.editorViewModel.insertDirective(
                                                  selectedDirective,
                                                );
                                                _handleInsertResult(result, isCompact);
                                              },
                                            ),
                                          ],
                                        )
                                      : MenuAnchor(
                                          style: const MenuStyle(alignment: .topStart),
                                          alignmentOffset: Offset(-182.0, 0.0),
                                          animated: true,
                                          menuChildren: [
                                            SubmenuButton(
                                              animated: true,
                                              leadingIcon: const Icon(Symbols.data_object_rounded),
                                              menuChildren: List.generate(DirectiveType.values.length - 1, (index) {
                                                final directive = DirectiveType.values[index];

                                                return MenuItemButton(
                                                  onPressed: () {
                                                    final result = widget.editorViewModel.insertDirective(directive);
                                                    _handleInsertResult(result, isCompact);
                                                  },
                                                  leadingIcon: Icon(directive.icon),
                                                  child: Text(directive.name.toCapitalised()),
                                                );
                                              }),
                                              child: const Text('Add directive'),
                                            ),
                                            MenuItemButton(
                                              onPressed: () {
                                                final result = widget.editorViewModel.insertChord();
                                                _handleInsertResult(result, isCompact);
                                              },
                                              leadingIcon: const Icon(Symbols.music_note_2_rounded),
                                              child: const Text('Add chord'),
                                            ),
                                          ],
                                          builder: (context, controller, _) => FloatingActionButton(
                                            onPressed: () => controller.isOpen ? controller.close() : controller.open(),
                                            tooltip: 'Add musical component',
                                            child: const Icon(Symbols.music_note_add_rounded),
                                          ),
                                        ),

                                  widgetBuilder: (context) => _TransposeControls(
                                    direction: isCompact ? .horizontal : .vertical,
                                    semitones: _transposeSemitones,
                                    onTransposeDownPressed: () {
                                      final error = widget.editorViewModel.transpose(BySemitones(-1));
                                      _handleTransposeResult(-1, error, isCompact);
                                    },
                                    onTransposeUpPressed: () {
                                      final error = widget.editorViewModel.transpose(BySemitones(1));
                                      _handleTransposeResult(1, error, isCompact);
                                    },
                                    onResetPressed: () {
                                      final error = widget.editorViewModel.transpose(
                                        BySemitones(_transposeSemitones * -1),
                                      );
                                      _handleTransposeResult(_transposeSemitones * -1, error, isCompact);
                                    },
                                  ),
                                  builder: (context, controller, child) => Toolbar(
                                    direction: isCompact ? .horizontal : .vertical,
                                    showFab: !_isPreview,
                                    floatingActionButton: child,
                                    children: [
                                      ToolbarIconButton(
                                        key: ValueKey(_isPreview),
                                        animate: true,
                                        onPressed: _togglePage,
                                        icon: Symbols.visibility_rounded,
                                        selectedIcon: Symbols.visibility_off_rounded,
                                        isSelected: _isPreview,
                                        label: 'Switch view',
                                      ),
                                      ToolbarSeparator(),
                                      ToolbarIconButton(
                                        onPressed: () => _isPreview ? null : _historyController.undo(),
                                        icon: Symbols.undo_rounded,
                                        label: 'Undo',
                                      ),
                                      ToolbarIconButton(
                                        onPressed: () => _isPreview ? null : _historyController.redo(),
                                        icon: Symbols.redo_rounded,
                                        label: 'Redo',
                                      ),
                                      ToolbarCollapsibleItem(
                                        key: ValueKey(controller.isOpen),
                                        animate: true,
                                        onPressed: controller.toggle,
                                        icon: Icons.swap_vert_rounded,
                                        isSelected: controller.isOpen,
                                        label: 'Transpose',
                                      ),
                                      if (!_isPreview) ...[
                                        ToolbarCollapsibleItem(
                                          onPressed: widget.viewModel.issuesCount > 0
                                              ? () => _selectNextIssue(isCompact)
                                              : null,
                                          icon: Icons.spellcheck_rounded,
                                          badgeCount: widget.viewModel.issuesCount > 0
                                              ? widget.viewModel.issuesCount
                                              : null,
                                          label: 'Issues',
                                        ),
                                      ] else ...[
                                        ToolbarCollapsibleItem(
                                          onPressed: () {},
                                          icon: Symbols.discover_tune_rounded,
                                          label: 'Advanced options',
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppbar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final menuOffsetX = switch (Theme.of(context).visualDensity) {
      VisualDensity.standard => -132.0,
      VisualDensity.compact => -126.0,
      _ => 0.0,
    };

    return AppBar(
      leading: IconButton(
        style: IconButton.styleFrom(tapTargetSize: .padded),
        onPressed: _closeWorkspace,
        icon: const Icon(Symbols.close_rounded),
      ),
      title: Text(_selectedPage.title),
      actions: [
        FilledButton(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            minimumSize: const Size(0.0, 48.0),
            fixedSize: const Size.fromHeight(48.0),
          ),
          onPressed: () {},
          child: const Text('Save'),
        ),
        const SizedBox(width: 4.0),
        MenuAnchor(
          style: const MenuStyle(alignment: .bottomStart),
          alignmentOffset: Offset(menuOffsetX, 4.0),
          consumeOutsideTap: true,
          animated: true,
          menuChildren: [
            MenuItemButton(
              onPressed: () {},
              leadingIcon: const Icon(Symbols.file_export_rounded),
              child: const Text('Export song'),
            ),
            MenuItemButton(
              onPressed: () async {
                _filenameController.text = widget.viewModel.filename;

                await showCustomDialog<void>(
                  context,
                  title: const Text('Rename song'),
                  content: Column(
                    mainAxisSize: .min,
                    spacing: 16.0,
                    children: [
                      TextField(
                        controller: _filenameController,
                        style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Filename',
                          suffixText: '.cho',
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(onPressed: () => context.pop(), child: const Text('Cancel')),
                    TextButton(
                      onPressed: () {
                        // widget.onRenameFile(_filenameController.text);
                        context.pop();
                      },
                      child: const Text('Rename'),
                    ),
                  ],
                );
              },
              leadingIcon: const Icon(Symbols.info_rounded),
              child: const Text('See information'),
            ),
            MenuItemButton(
              style: ButtonStyle(
                backgroundColor: WidgetStatePropertyAll(colorScheme.errorContainer.withAlpha(30)),
                foregroundColor: WidgetStatePropertyAll(colorScheme.onErrorContainer),
                overlayColor: WidgetStatePropertyAll(colorScheme.errorContainer.withAlpha(90)),
                iconColor: WidgetStatePropertyAll(colorScheme.onErrorContainer),
              ),
              onPressed: () async {
                await showCustomDialog<void>(
                  context,
                  title: const Text('Delete song?'),
                  content: const Text('You are about to permanently delete the song. This action is irreversible.'),
                  actions: [
                    TextButton(onPressed: () => context.pop(), child: const Text('Cancel')),
                    TextButton(
                      style: ButtonStyle(
                        foregroundColor: WidgetStatePropertyAll(colorScheme.error),
                        overlayColor: WidgetStatePropertyAll(colorScheme.onError.withAlpha(90)),
                      ),
                      onPressed: () {
                        // widget.onDelete();
                        context.pop();
                      },
                      child: const Text('Delete'),
                    ),
                  ],
                );
              },
              leadingIcon: const Icon(Symbols.delete_forever_rounded),
              child: const Text('Delete'),
            ),
          ],
          builder: (context, controller, _) => IconButton(
            style: IconButton.styleFrom(minimumSize: const Size(0.0, 48.0)),
            onPressed: () => controller.isOpen ? controller.close() : controller.open(),
            icon: const Icon(Icons.more_vert_rounded),
          ),
        ),
        const SizedBox(width: 8.0),
      ],
    );
  }
}

class _ToolbarSlideTransition extends AnimatedWidget {
  const _ToolbarSlideTransition({required Animation<double> animation, required this.isCompact, required this.child})
    : super(listenable: animation);

  final bool isCompact;
  final Widget child;

  Animation<double> get _animation => listenable as Animation<double>;

  @override
  Widget build(BuildContext context) {
    final isOutgoing = _animation.status == AnimationStatus.reverse;
    final progress = isOutgoing
        ? Curves.easeInOutCubicEmphasized.transform(1.0 - _animation.value)
        : 1.0 - Curves.easeInOutCubicEmphasized.transform(_animation.value);
    final safePadding = MediaQuery.paddingOf(context);
    final distance = 88.0 + (isCompact ? safePadding.bottom : safePadding.right);
    final offset = isCompact ? Offset(0.0, distance * progress) : Offset(distance * progress, 0.0);

    return IgnorePointer(
      ignoring: isOutgoing,
      child: ExcludeSemantics(
        excluding: isOutgoing,
        child: Transform.translate(offset: offset, child: child),
      ),
    );
  }
}

class _DirectivePickerSheet extends StatefulWidget {
  const _DirectivePickerSheet();

  @override
  State<_DirectivePickerSheet> createState() => _DirectivePickerSheetState();
}

class _DirectivePickerSheetState extends State<_DirectivePickerSheet> {
  static const _initialSize = 0.4;
  static const _minSize = 0.25;
  static const _maxSize = 1.0;
  static const _snapSizes = [_minSize, _initialSize, _maxSize];
  static const _flingVelocity = 500.0;
  static const _snapTolerance = 0.001;

  final _sheetController = DraggableScrollableController();

  Future<void> _snapSheet({double velocity = 0.0}) async {
    if (!_sheetController.isAttached) return;

    final currentSize = _sheetController.size;
    final targetSize = switch (velocity) {
      < -_flingVelocity => _snapSizes.firstWhere((size) => size > currentSize, orElse: () => _maxSize),
      > _flingVelocity => _snapSizes.lastWhere((size) => size < currentSize, orElse: () => _minSize),
      _ => _snapSizes.reduce(
        (closest, size) => (size - currentSize).abs() < (closest - currentSize).abs() ? size : closest,
      ),
    };

    if ((targetSize - currentSize).abs() < _snapTolerance) return;

    await _sheetController.animateTo(
      targetSize,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  bool _handleListScrollEnd(ScrollEndNotification notification) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _snapSheet(velocity: notification.dragDetails?.primaryVelocity ?? 0.0);
    });
    return false;
  }

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        return DraggableScrollableSheet(
          controller: _sheetController,
          initialChildSize: _initialSize,
          minChildSize: _minSize,
          maxChildSize: _maxSize,
          expand: false,
          builder: (context, scrollController) => MouseRegion(
            cursor: SystemMouseCursors.resizeUpDown,
            child: GestureDetector(
              behavior: .opaque,
              onVerticalDragUpdate: (details) {
                if (!_sheetController.isAttached || !constraints.hasBoundedHeight) return;

                final targetSize = (_sheetController.size - details.delta.dy / constraints.maxHeight)
                    .clamp(_minSize, _maxSize)
                    .toDouble();
                _sheetController.jumpTo(targetSize);
              },
              onVerticalDragEnd: (details) => _snapSheet(velocity: details.primaryVelocity ?? 0.0),
              child: Column(
                crossAxisAlignment: .stretch,
                children: [
                  Center(
                    child: Container(
                      width: 32.0,
                      height: 4.0,
                      margin: const .symmetric(vertical: 12.0),
                      decoration: BoxDecoration(color: colorScheme.onSurfaceVariant, borderRadius: .circular(2.0)),
                    ),
                  ),
                  Padding(
                    padding: const .fromLTRB(16.0, 0.0, 16.0, 16.0),
                    child: Text('Add directive', style: textTheme.titleMedium),
                  ),
                  Expanded(
                    child: ScrollConfiguration(
                      behavior: ScrollConfiguration.of(context).copyWith(
                        scrollbars: false,
                        dragDevices: {...ScrollConfiguration.of(context).dragDevices, PointerDeviceKind.mouse},
                      ),
                      child: NotificationListener<ScrollEndNotification>(
                        onNotification: _handleListScrollEnd,
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: DirectiveType.values.length - 1,
                          itemBuilder: (context, index) {
                            final directive = DirectiveType.values[index];
                            return Card.filled(
                              margin: .fromLTRB(
                                16.0,
                                index == 0 ? 0.0 : 1.0,
                                16.0,
                                index == DirectiveType.values.length - 2 ? 16.0 : 1.0,
                              ),
                              color: colorScheme.surfaceContainer,
                              shape: RoundedRectangleBorder(
                                borderRadius: WidgetUtilities.calculateBorderRadius(
                                  WidgetUtilities.calculateListWidgetSide(index, DirectiveType.values.length - 1),
                                ),
                              ),
                              child: InkWell(
                                onTap: () => context.pop(directive),
                                child: Padding(
                                  padding: const .all(16.0),
                                  child: Row(
                                    spacing: 12.0,
                                    children: [
                                      Icon(directive.icon),
                                      Text(
                                        directive.name.toCapitalised(),
                                        style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TransposeControls extends StatelessWidget {
  const _TransposeControls({
    required this.direction,
    required this.onTransposeDownPressed,
    required this.onTransposeUpPressed,
    required this.onResetPressed,
    required this.semitones,
  });

  final Axis direction;

  final VoidCallback onTransposeDownPressed;
  final VoidCallback onTransposeUpPressed;
  final VoidCallback onResetPressed;

  final int semitones;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final content = Flex(
      direction: direction,
      mainAxisSize: .min,
      spacing: 4.0,
      children: [
        if (direction == .horizontal)
          IconButton.filledTonal(
            style: WidgetStyleUtilities.iconButtonStyle(ButtonWidth.narrow),
            onPressed: semitones > -12 ? onTransposeDownPressed : null,
            icon: const Icon(Symbols.remove_rounded),
          )
        else
          IconButton.filledTonal(
            style: WidgetStyleUtilities.iconButtonStyle(ButtonWidth.wide),
            onPressed: semitones < 12 ? onTransposeUpPressed : null,
            icon: const Icon(Symbols.add_rounded),
          ),
        Container(
          padding: const .all(8.0),
          decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest, borderRadius: .circular(12.0)),
          child: Column(
            mainAxisSize: .min,
            children: [
              Text('$semitones', style: textTheme.bodyLarge),
              Text('semitones', style: textTheme.labelSmall),
            ],
          ),
        ),
        if (direction == .horizontal)
          IconButton.filledTonal(
            style: WidgetStyleUtilities.iconButtonStyle(ButtonWidth.narrow),
            onPressed: semitones < 12 ? onTransposeUpPressed : null,
            icon: const Icon(Symbols.add_rounded),
          )
        else
          IconButton.filledTonal(
            style: WidgetStyleUtilities.iconButtonStyle(ButtonWidth.wide),
            onPressed: semitones > -12 ? onTransposeDownPressed : null,
            icon: const Icon(Symbols.remove_rounded),
          ),
        if (semitones != 0) ...[
          direction == Axis.horizontal
              ? const VerticalDivider(width: 8.0, thickness: 1.0, indent: 8.0, endIndent: 8.0)
              : const Divider(height: 8.0, thickness: 1.0, indent: 8.0, endIndent: 8.0),
          IconButton(
            style: WidgetStyleUtilities.iconButtonStyle(
              direction == .horizontal ? ButtonWidth.narrow : ButtonWidth.wide,
            ),
            onPressed: onResetPressed,
            icon: const Icon(Symbols.restart_alt_rounded),
          ),
        ],
      ],
    );

    return Material(
      elevation: 3.0,
      color: colorScheme.surfaceContainer,
      borderRadius: .circular(16.0),
      clipBehavior: .antiAlias,
      child: Padding(
        padding: const .all(4.0),
        child: direction == .horizontal ? IntrinsicHeight(child: content) : IntrinsicWidth(child: content),
      ),
    );
  }
}
