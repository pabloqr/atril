import 'package:atril/core/routing/routes.dart';
import 'package:atril/features/core/widgets/dialog.dart';
import 'package:atril/features/core/widgets/toolbar.dart';
import 'package:atril/features/workspace/view_model/workspace_view_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

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
  const WorkspaceScaffold({super.key, required this.viewModel});

  final WorkspaceViewModel viewModel;

  @override
  State<WorkspaceScaffold> createState() => _WorkspaceScaffoldState();
}

class _WorkspaceScaffoldState extends State<WorkspaceScaffold> {
  late final PageController _pageController;
  var _selectedPage = _WorkspacePage.editor;

  final _filenameController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _pageController = PageController(initialPage: _selectedPage.index);
  }

  @override
  void dispose() {
    _pageController.dispose();

    _filenameController.dispose();

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
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      onPageChanged: _handlePageChanged,
                      children: [
                        const Center(child: Text('Editor')),
                        const Center(child: Text('Preview')),
                      ],
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
                        alignment: isCompact ? Alignment.bottomCenter : Alignment.centerRight,
                        child: Padding(
                          padding: isCompact
                              ? const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 24.0)
                              : const EdgeInsets.fromLTRB(0.0, 16.0, 24.0, 16.0),
                          child: SafeArea(
                            child: Toolbar(
                              direction: isCompact ? Axis.horizontal : Axis.vertical,
                              showFab: !_isPreview,
                              floatingActionButton: FloatingActionButton(
                                onPressed: () {},
                                tooltip: 'Add musical component',
                                child: const Icon(Symbols.music_note_add_rounded),
                              ),
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
                                ToolbarIconButton(onPressed: () {}, icon: Symbols.undo_rounded, label: 'Undo'),
                                ToolbarIconButton(onPressed: () {}, icon: Symbols.redo_rounded, label: 'Redo'),
                                if (!_isPreview) ...[
                                  ToolbarCollapsibleItem(
                                    onPressed: () {},
                                    icon: Icons.swap_vert_rounded,
                                    label: 'Transpose',
                                  ),
                                  ToolbarCollapsibleItem(
                                    onPressed: () {},
                                    icon: Icons.spellcheck_rounded,
                                    label: 'Issues',
                                  ),
                                ] else ...[
                                  ToolbarCollapsibleItem(
                                    onPressed: () {},
                                    icon: Icons.swap_vert_rounded,
                                    label: 'Semitones',
                                  ),
                                  ToolbarCollapsibleItem(
                                    onPressed: () {},
                                    icon: Symbols.discover_tune_rounded,
                                    label: 'Advanced options',
                                  ),
                                ],
                              ],
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

    return AppBar(
      leading: IconButton(onPressed: _closeWorkspace, icon: const Icon(Icons.close_rounded)),
      title: Text(_selectedPage.title),
      actions: [
        FilledButton(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            minimumSize: const Size(0.0, 48.0),
          ),
          onPressed: () {},
          child: const Text('Save'),
        ),
        const SizedBox(width: 4.0),
        MenuAnchor(
          animated: true,
          consumeOutsideTap: true,
          alignmentOffset: Offset(-124.0, 4.0),
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
                    mainAxisSize: MainAxisSize.min,
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
          builder: (context, controller, child) => IconButton(
            style: IconButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0))),
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
