import 'package:atril/domain/models/song.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SongListTile extends StatefulWidget {
  const SongListTile({
    super.key,
    required this.borderRadius,
    required this.filename,
    required this.song,
    required this.onRenameTitle,
    required this.onDelete,
    required this.onRenameFile,
  });

  final BorderRadius borderRadius;

  final String filename;
  final Song song;

  final void Function(String title) onRenameTitle;
  final VoidCallback onDelete;
  final void Function(String filename) onRenameFile;

  @override
  State<SongListTile> createState() => _SongListTileState();
}

class _SongListTileState extends State<SongListTile> {
  final _titleController = TextEditingController();
  final _filenameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final metadata = widget.song.metadata;

    return Card.filled(
      margin: const EdgeInsets.symmetric(vertical: 1.0),
      shape: RoundedRectangleBorder(borderRadius: widget.borderRadius),
      child: InkWell(
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            spacing: 16.0,
            children: [
              Container(
                width: 48.0,
                height: 48.0,
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.music_note_rounded, color: colorScheme.onSecondaryContainer),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2.0,
                  children: [
                    Text(
                      metadata.title ?? 'Untitled song',
                      style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurface),
                    ),
                    if (metadata.artist != null)
                      Text(
                        metadata.artist!,
                        style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                  ],
                ),
              ),
              Row(
                children: [
                  if (metadata.key != null) ...[
                    Chip(label: Text('Key: ${metadata.key}')),
                    // Text('Key: ${metadata.key}', style: textTheme.bodyMedium?.copyWith(color: colorScheme.tertiary)),
                    const SizedBox(width: 4.0),
                  ],
                  MenuAnchor(
                    animated: true,
                    consumeOutsideTap: true,
                    alignmentOffset: Offset(-124.0, 0.0),
                    menuChildren: [
                      MenuItemButton(
                        onPressed: () async {
                          _titleController.text = widget.song.metadata.title ?? '';

                          await _showDialog(
                            context,
                            title: const Text('Rename song'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              spacing: 16.0,
                              children: [
                                TextField(
                                  controller: _titleController,
                                  style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
                                  decoration: InputDecoration(border: OutlineInputBorder(), labelText: 'Title'),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(onPressed: () => context.pop(), child: const Text('Cancel')),
                              TextButton(
                                onPressed: () {
                                  widget.onRenameTitle(_titleController.text);
                                  context.pop();
                                },
                                child: const Text('Rename'),
                              ),
                            ],
                          );
                        },
                        leadingIcon: const Icon(Icons.drive_file_rename_outline_rounded),
                        child: const Text('Rename'),
                      ),
                      MenuItemButton(
                        onPressed: () async {
                          _filenameController.text = widget.filename;

                          await _showDialog(
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
                                  widget.onRenameFile(_filenameController.text);
                                  context.pop();
                                },
                                child: const Text('Rename'),
                              ),
                            ],
                          );
                        },
                        leadingIcon: const Icon(Icons.info_rounded),
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
                          await _showDialog(
                            context,
                            title: const Text('Delete song?'),
                            content: const Text(
                              'You are about to permanently delete the song. This action is irreversible.',
                            ),
                            actions: [
                              TextButton(onPressed: () => context.pop(), child: const Text('Cancel')),
                              TextButton(
                                style: ButtonStyle(
                                  foregroundColor: WidgetStatePropertyAll(colorScheme.error),
                                  overlayColor: WidgetStatePropertyAll(colorScheme.onError.withAlpha(90)),
                                ),
                                onPressed: () {
                                  widget.onDelete();
                                  context.pop();
                                },
                                child: const Text('Delete'),
                              ),
                            ],
                          );
                        },
                        leadingIcon: const Icon(Icons.delete_forever_rounded),
                        child: const Text('Delete'),
                      ),
                    ],
                    builder: (context, controller, child) => IconButton(
                      style: IconButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                      ),
                      onPressed: () {
                        if (controller.isOpen) {
                          controller.close();
                        } else {
                          controller.open();
                        }
                      },
                      icon: const Icon(Icons.more_vert_rounded),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDialog(
    BuildContext context, {
    required Widget title,
    required Widget content,
    required List<Widget> actions,
  }) async {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        constraints: const BoxConstraints(minWidth: 280.0, maxWidth: 560.0),
        titleTextStyle: textTheme.headlineSmall?.copyWith(color: colorScheme.onSurface),
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
        title: title,
        content: SizedBox(width: double.maxFinite, child: content),
        actions: actions,
      ),
    );
  }
}
