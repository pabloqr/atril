import 'package:atril/core/routing/routes.dart';
import 'package:atril/core/utils/result.dart';
import 'package:atril/data/repositories/song/song_repository.dart';
import 'package:atril/features/dashboard/view_model/song_list_view_model.dart';
import 'package:atril/features/dashboard/widgets/song_list_screen.dart';
import 'package:atril/features/loading/view_model/loading_view_model.dart';
import 'package:atril/features/loading/widgets/loading_screen.dart';
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
  initialLocation: AppRoutes.homeRoute.path,
  debugLogDiagnostics: true,
  routes: [
    GoRoute(
      path: AppRoutes.homeRoute.path,
      name: AppRoutes.homeRoute.name,
      builder: (context, state) {
        return SongListScreen(viewModel: SongListViewModel(songRepository: context.read()));
      },
    ),
    GoRoute(path: AppRoutes.settingsRoute.path, name: AppRoutes.settingsRoute.name),

    GoRoute(
      path: AppRoutes.songItemRoute.path,
      name: AppRoutes.songItemRoute.name,
      builder: (context, state) => LoadingScreen(
        viewModel: LoadingViewModel(
          songRepository: context.read<SongRepository>(),
          filename: state.pathParameters['filename']!,
        ),
      ),
    ),

    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return const Placeholder();
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.songEditorRoute.path,
              name: AppRoutes.songEditorRoute.name,
              redirect: _redirectIfNotExisting,
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: AppRoutes.songPreviewRoute.path, name: AppRoutes.songPreviewRoute.name)],
        ),
      ],
    ),
  ],
);

Future<String?> _redirectIfNotExisting(BuildContext context, GoRouterState state) async {
  final filename = state.pathParameters['filename']!;

  final result = await context.read<SongRepository>().existsSong(filename);
  return switch (result) {
    Ok<bool>(value: true) => null,
    Ok<bool>(value: false) => '${AppRoutes.notFoundRoute.path}?reason=not-found',
    Error<bool>() => '${AppRoutes.notFoundRoute.path}?reason=error',
  };
}
