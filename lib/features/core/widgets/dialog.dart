import 'package:flutter/material.dart';

Future<T?> showCustomDialog<T>(
  BuildContext context, {
  required Widget title,
  required Widget content,
  required List<Widget> actions,
}) async {
  final colorScheme = Theme.of(context).colorScheme;
  final textTheme = Theme.of(context).textTheme;

  return showDialog<T>(
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
