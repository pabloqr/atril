import 'package:atril/core/routing/routes.dart';
import 'package:atril/features/core/widgets/dialog.dart';
import 'package:atril/features/core/widgets/toolbar.dart';
import 'package:atril/features/workspace/view_model/workspace_view_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

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
          body: Stack(
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
              Align(
                alignment: AlignmentGeometry.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 24.0),
                  child: SafeArea(
                    child: Toolbar(
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
                          ToolbarCollapsibleItem(onPressed: () {}, icon: Icons.swap_vert_rounded, label: 'Transpose'),
                          ToolbarCollapsibleItem(onPressed: () {}, icon: Icons.spellcheck_rounded, label: 'Issues'),
                        ] else ...[
                          ToolbarCollapsibleItem(onPressed: () {}, icon: Icons.swap_vert_rounded, label: 'Semitones'),
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
            ],
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
