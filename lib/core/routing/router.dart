import 'package:atril/core/routing/routes.dart';
import 'package:atril/features/dashboard/view_model/song_list_view_model.dart';
import 'package:atril/features/dashboard/widgets/song_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

Widget withSystemUiOverlay(BuildContext context, {required Widget child}) {
  final colorScheme = Theme.of(context).colorScheme;
  final brightness = Theme.brightnessOf(context) == Brightness.light ? Brightness.dark : Brightness.light;

  return AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: brightness == Brightness.light
          ? colorScheme.surfaceContainerHigh
          : colorScheme.surfaceContainerLowest,
      systemNavigationBarDividerColor: Colors.transparent,

      statusBarIconBrightness: brightness,
      systemNavigationBarIconBrightness: brightness,
    ),
    child: child,
  );
}

GoRouter router() => GoRouter(
  initialLocation: AppRoutes.dashboardRoute,
  debugLogDiagnostics: true,
  routes: [
    GoRoute(
      path: AppRoutes.dashboardRoute,
      builder: (context, state) {
        return SongListScreen(viewModel: SongListViewModel(songRepository: context.read()));
      },
    ),
    GoRoute(path: AppRoutes.songEditorRoute, builder: (context, state) => const Placeholder()),
    GoRoute(path: AppRoutes.songPreviewRoute, builder: (context, state) => const Placeholder()),
  ],
);
