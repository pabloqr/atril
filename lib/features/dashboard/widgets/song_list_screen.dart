import 'package:atril/data/services/song/song_codec.dart';
import 'package:atril/domain/models/settings/app_settings.dart';
import 'package:atril/features/core/theme/atril_theme.dart';
import 'package:atril/features/core/utils/widget_utilities.dart';
import 'package:atril/features/core/widgets/connected_button_group.dart';
import 'package:atril/features/dashboard/view_model/song_list_view_model.dart';
import 'package:atril/features/song/song_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/widget_previews.dart';

class SongListScreen extends StatefulWidget {
  const SongListScreen({super.key, required this.viewModel});

  final SongListViewModel viewModel;

  @override
  State<SongListScreen> createState() => _SongListScreenState();
}

class _SongListScreenState extends State<SongListScreen> with SingleTickerProviderStateMixin {
  // final _appBarHeight = kToolbarHeight;
  final _bannerHeight = 92.0;
  final _controlsHeight = 156.0;

  final _scrollController = ScrollController();

  var _showBannerIconButton = false;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(_updateLibraryShortcut);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_updateLibraryShortcut)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Atril'),
        actions: [
          _LibraryIconButton(visible: _showBannerIconButton, onPressed: () {}),
          const SizedBox(width: 4.0),
          IconButton.filledTonal(
            style: WidgetStyleUtilities.iconButtonStyle(ButtonWidth.narrow),
            tooltip: 'Import song',
            onPressed: () {},
            icon: const Icon(Icons.file_open_rounded),
          ),
          const SizedBox(width: 4.0),
          IconButton(
            style: WidgetStyleUtilities.iconButtonStyle(ButtonWidth.regular),
            tooltip: 'Settings',
            onPressed: () {},
            icon: const Icon(Icons.settings_rounded),
          ),
          const SizedBox(width: 8.0),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_rounded),
        label: const Text('New song'),
        onPressed: () {},
      ),
      body: SafeArea(
        child: NestedScrollView(
          controller: _scrollController,
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(toolbarHeight: _bannerHeight, flexibleSpace: const _LibraryBanner(songCount: 4)),
              SliverAppBar(
                floating: true,
                snap: true,
                toolbarHeight: _controlsHeight,
                flexibleSpace: _LibraryControls(viewModel: widget.viewModel),
              ),
            ];
          },
          body: ListenableBuilder(
            listenable: widget.viewModel,
            builder: (context, child) {
              final filteredSongFiles = widget.viewModel.filteredSongFiles;
              final filteredSongs = widget.viewModel.filteredSongs;

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(8.0, 0.0, 8.0, 80.0),
                itemCount: filteredSongs.length,
                itemBuilder: (context, index) {
                  final songFile = filteredSongFiles[index];
                  final song = filteredSongs[index];

                  return SongListTile(
                    borderRadius: WidgetUtilities.calculateBorderRadius(
                      WidgetUtilities.calculateListWidgetSide(index, filteredSongs.length),
                    ),
                    filename: songFile.filename,
                    song: filteredSongs[index],
                    onRenameTitle: (title) {
                      widget.viewModel.saveSong.execute(songFile.filename, songCodec.encode(song.withTitle(title)));
                    },
                    onDelete: () => widget.viewModel.deleteSong.execute(songFile.filename),
                    onRenameFile: (filename) {
                      widget.viewModel.saveSong.execute(filename, songFile.source);
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _updateLibraryShortcut() {
    final shouldShow = _scrollController.offset >= _bannerHeight;
    if (shouldShow == _showBannerIconButton) {
      return;
    }
    setState(() => _showBannerIconButton = shouldShow);
  }
}

class _LibraryIconButton extends StatefulWidget {
  const _LibraryIconButton({required this.visible, required this.onPressed});

  final bool visible;
  final VoidCallback onPressed;

  @override
  State<_LibraryIconButton> createState() => _LibraryIconButtonState();
}

class _LibraryIconButtonState extends State<_LibraryIconButton> with TickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final AnimationController _opacityController;

  static final SpringDescription _enterSpatial = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 800,
    ratio: 0.6,
  );

  static final SpringDescription _effects = SpringDescription.withDampingRatio(mass: 1, stiffness: 3800, ratio: 1.0);

  static final SpringDescription _exitSpatial = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 1200,
    ratio: 1.0,
  );

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController.unbounded(vsync: this, value: widget.visible ? 1.0 : 0.0);
    _opacityController = AnimationController.unbounded(vsync: this, value: widget.visible ? 1.0 : 0.0);
  }

  @override
  void didUpdateWidget(covariant _LibraryIconButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.visible == widget.visible) return;

    final target = widget.visible ? 1.0 : 0.0;

    _scaleController.animateWith(
      SpringSimulation(widget.visible ? _enterSpatial : _exitSpatial, _scaleController.value, target, 0),
    );

    _opacityController.animateWith(
      SpringSimulation(widget.visible ? _effects : _exitSpatial, _opacityController.value, target, 0),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _opacityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: Listenable.merge([_scaleController, _opacityController]),
      child: IconButton.filled(
        style: WidgetStyleUtilities.iconButtonStyle(ButtonWidth.narrow)?.copyWith(
          backgroundColor: WidgetStatePropertyAll(colorScheme.primaryContainer),
          foregroundColor: WidgetStatePropertyAll(colorScheme.onPrimaryContainer),
        ),
        onPressed: widget.onPressed,
        icon: const Icon(Icons.music_note_rounded),
      ),
      builder: (context, child) {
        final opacity = _opacityController.value.clamp(0.0, 1.0);
        final scale = _scaleController.value.clamp(0.0, 1.08);

        return IgnorePointer(
          ignoring: opacity <= 0.01,
          child: Opacity(
            opacity: opacity,
            child: Transform.scale(scale: scale, child: child),
          ),
        );
      },
    );
  }
}

class _LibraryBanner extends StatelessWidget {
  const _LibraryBanner({required this.songCount});

  final int songCount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card.filled(
      color: colorScheme.primaryContainer,
      margin: const EdgeInsets.fromLTRB(8.0, 0.0, 8.0, 4.0),
      child: InkWell(
        splashColor: colorScheme.primary.withAlpha(30),
        overlayColor: WidgetStatePropertyAll(colorScheme.primary.withAlpha(30)),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            spacing: 16.0,
            children: [
              Container(
                width: 56.0,
                height: 56.0,
                decoration: BoxDecoration(color: colorScheme.primary, borderRadius: BorderRadius.circular(20.0)),
                child: Icon(Icons.library_music_rounded, color: colorScheme.onPrimary, size: 32.0),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2.0,
                  children: [
                    Text('Your repertoire', style: textTheme.titleLarge?.copyWith(color: colorScheme.onSurface)),
                    Text(
                      '$songCount ${songCount == 1 ? 'song' : 'songs'} ready to play',
                      style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _LibraryControls extends StatefulWidget {
  const _LibraryControls({required this.viewModel});

  final SongListViewModel viewModel;

  @override
  State<_LibraryControls> createState() => _LibraryControlsState();
}

class _LibraryControlsState extends State<_LibraryControls> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card.filled(
      margin: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 12.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8.0,
          children: [
            SearchBar(
              padding: WidgetStatePropertyAll(const EdgeInsets.symmetric(horizontal: 16.0)),
              elevation: WidgetStatePropertyAll(0.0),
              controller: _searchController,
              leading: const Icon(Icons.search_rounded),
              hintText: 'Search title or artist',
              onChanged: (value) => widget.viewModel.searchQuery = value,
            ),
            ListenableBuilder(
              listenable: widget.viewModel,
              builder: (context, child) => ConnectedButtonGroup<LibrarySortOrder>(
                buttons: [
                  ButtonGroupItem(
                    value: LibrarySortOrder.title,
                    label: const Text('Title'),
                    icon: const Icon(Icons.sort_by_alpha_rounded),
                  ),
                  ButtonGroupItem(
                    value: LibrarySortOrder.artist,
                    label: const Text('Artist'),
                    icon: const Icon(Icons.person_rounded),
                  ),
                ],
                selected: {widget.viewModel.sortOrder},
                onSelectionChanged: (selection) => widget.viewModel.sortOrder = selection.single,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _PreviewSettingsStyle { filledTonal, transparent }

enum _PreviewLibraryTone { primary, primaryContainer }

class _MainAppBarPreviewVariant {
  const _MainAppBarPreviewVariant({
    required this.name,
    required this.primaryWidth,
    required this.secondaryWidth,
    required this.settingsStyle,
    required this.libraryTone,
  });

  final String name;
  final ButtonWidth primaryWidth;
  final ButtonWidth secondaryWidth;
  final _PreviewSettingsStyle settingsStyle;
  final _PreviewLibraryTone libraryTone;
}

const _mainAppBarPreviewVariants = [
  _MainAppBarPreviewVariant(
    name: 'Regular buttons + tonal settings',
    primaryWidth: ButtonWidth.regular,
    secondaryWidth: ButtonWidth.regular,
    settingsStyle: _PreviewSettingsStyle.filledTonal,
    libraryTone: _PreviewLibraryTone.primaryContainer,
  ),
  _MainAppBarPreviewVariant(
    name: 'Regular buttons + transparent settings',
    primaryWidth: ButtonWidth.regular,
    secondaryWidth: ButtonWidth.regular,
    settingsStyle: _PreviewSettingsStyle.transparent,
    libraryTone: _PreviewLibraryTone.primaryContainer,
  ),
  _MainAppBarPreviewVariant(
    name: 'Regular primary buttons + tonal wide settings',
    primaryWidth: ButtonWidth.regular,
    secondaryWidth: ButtonWidth.wide,
    settingsStyle: _PreviewSettingsStyle.filledTonal,
    libraryTone: _PreviewLibraryTone.primaryContainer,
  ),
  _MainAppBarPreviewVariant(
    name: 'Regular primary buttons + transparent wide settings',
    primaryWidth: ButtonWidth.regular,
    secondaryWidth: ButtonWidth.wide,
    settingsStyle: _PreviewSettingsStyle.transparent,
    libraryTone: _PreviewLibraryTone.primaryContainer,
  ),
  _MainAppBarPreviewVariant(
    name: 'Compact buttons + tonal settings',
    primaryWidth: ButtonWidth.narrow,
    secondaryWidth: ButtonWidth.narrow,
    settingsStyle: _PreviewSettingsStyle.filledTonal,
    libraryTone: _PreviewLibraryTone.primaryContainer,
  ),
  _MainAppBarPreviewVariant(
    name: 'Compact buttons + transparent settings',
    primaryWidth: ButtonWidth.narrow,
    secondaryWidth: ButtonWidth.narrow,
    settingsStyle: _PreviewSettingsStyle.transparent,
    libraryTone: _PreviewLibraryTone.primaryContainer,
  ),
  _MainAppBarPreviewVariant(
    name: 'Compact primary buttons + tonal regular settings',
    primaryWidth: ButtonWidth.narrow,
    secondaryWidth: ButtonWidth.regular,
    settingsStyle: _PreviewSettingsStyle.filledTonal,
    libraryTone: _PreviewLibraryTone.primaryContainer,
  ),
  _MainAppBarPreviewVariant(
    name: 'Compact primary buttons + transparent regular settings',
    primaryWidth: ButtonWidth.narrow,
    secondaryWidth: ButtonWidth.regular,
    settingsStyle: _PreviewSettingsStyle.transparent,
    libraryTone: _PreviewLibraryTone.primaryContainer,
  ),
  _MainAppBarPreviewVariant(
    name: 'Compact primary buttons + tonal wide settings',
    primaryWidth: ButtonWidth.narrow,
    secondaryWidth: ButtonWidth.wide,
    settingsStyle: _PreviewSettingsStyle.filledTonal,
    libraryTone: _PreviewLibraryTone.primaryContainer,
  ),
  _MainAppBarPreviewVariant(
    name: 'Compact primary buttons + transparent wide settings',
    primaryWidth: ButtonWidth.narrow,
    secondaryWidth: ButtonWidth.wide,
    settingsStyle: _PreviewSettingsStyle.transparent,
    libraryTone: _PreviewLibraryTone.primaryContainer,
  ),
];

@Preview(name: 'Main app bar variants', group: 'Dashboard', size: Size(412, 936))
Widget mainAppBarVariantsPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AtrilTheme.light(),
    darkTheme: AtrilTheme.dark(),
    home: Scaffold(
      body: ListView.separated(
        padding: const EdgeInsets.all(12.0),
        itemCount: _mainAppBarPreviewVariants.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12.0),
        itemBuilder: (context, index) {
          final variant = _mainAppBarPreviewVariants[index];

          return _MainAppBarPreviewFrame(variant: variant);
        },
      ),
    ),
  );
}

class _MainAppBarPreviewFrame extends StatelessWidget {
  const _MainAppBarPreviewFrame({required this.variant});

  final _MainAppBarPreviewVariant variant;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 4.0,
      children: [
        Text(variant.name, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: colorScheme.onSurface)),
        DecoratedBox(
          decoration: BoxDecoration(border: Border.all(color: colorScheme.outlineVariant)),
          child: SizedBox(
            height: kToolbarHeight,
            child: _PreviewMainAppBar(variant: variant),
          ),
        ),
      ],
    );
  }
}

class _PreviewMainAppBar extends StatelessWidget {
  const _PreviewMainAppBar({required this.variant});

  final _MainAppBarPreviewVariant variant;

  @override
  Widget build(BuildContext context) {
    final libraryStyle = (WidgetStyleUtilities.iconButtonStyle(variant.primaryWidth) ?? const ButtonStyle()).merge(
      _libraryColorStyleFor(context),
    );
    final importStyle = WidgetStyleUtilities.iconButtonStyle(variant.primaryWidth);
    final settingsStyle = WidgetStyleUtilities.iconButtonStyle(variant.secondaryWidth);

    return AppBar(
      title: const Text('Atril'),
      actions: [
        IconButton.filled(
          style: libraryStyle,
          tooltip: 'Library',
          onPressed: () {},
          icon: const Icon(Icons.music_note_rounded),
        ),
        const SizedBox(width: 4.0),
        IconButton.filledTonal(
          style: importStyle,
          tooltip: 'Import song',
          onPressed: () {},
          icon: const Icon(Icons.file_open_rounded),
        ),
        const SizedBox(width: 4.0),
        _SettingsPreviewButton(style: settingsStyle, variant: variant.settingsStyle),
        const SizedBox(width: 8.0),
      ],
    );
  }

  ButtonStyle _libraryColorStyleFor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return switch (variant.libraryTone) {
      _PreviewLibraryTone.primary => IconButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      _PreviewLibraryTone.primaryContainer => IconButton.styleFrom(
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
      ),
    };
  }
}

class _SettingsPreviewButton extends StatelessWidget {
  const _SettingsPreviewButton({required this.style, required this.variant});

  final ButtonStyle? style;
  final _PreviewSettingsStyle variant;

  @override
  Widget build(BuildContext context) {
    return switch (variant) {
      _PreviewSettingsStyle.filledTonal => IconButton.filledTonal(
        style: style,
        tooltip: 'Settings',
        onPressed: () {},
        icon: const Icon(Icons.settings_rounded),
      ),
      _PreviewSettingsStyle.transparent => IconButton(
        style: style,
        tooltip: 'Settings',
        onPressed: () {},
        icon: const Icon(Icons.settings_rounded),
      ),
    };
  }
}
