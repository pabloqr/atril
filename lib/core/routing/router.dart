import 'package:atril/core/routing/routes.dart';
import 'package:atril/data/repositories/song/song_repository.dart';
import 'package:atril/features/dashboard/view_model/song_list_view_model.dart';
import 'package:atril/features/dashboard/widgets/song_list_screen.dart';
import 'package:atril/features/loading/view_model/loading_view_model.dart';
import 'package:atril/features/loading/widgets/loading_screen.dart';
import 'package:atril/features/workspace/view_model/workspace_view_model.dart';
import 'package:atril/features/workspace/widgets/workspace_scaffold.dart';
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
      builder: (context, state) => SongListScreen(viewModel: SongListViewModel(songRepository: context.read())),
    ),
    GoRoute(
      path: AppRoutes.settingsRoute.path,
      name: AppRoutes.settingsRoute.name,
      builder: (context, state) => const Center(child: Text('Settings')),
    ),

    GoRoute(
      path: AppRoutes.songItemRoute.path,
      name: AppRoutes.songItemRoute.name,
      builder: (context, state) => LoadingScreen(
        viewModel: LoadingViewModel(
          songRepository: context.read<SongRepository>(),
          filename: state.pathParameters['filename']!,
        ),
      ),
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) => WorkspaceScaffold(
            navigationShell: navigationShell,
            viewModel: WorkspaceViewModel(songRepository: context.read(), filename: state.pathParameters['filename']!),
          ),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.workspaceEditorRoute.path,
                  name: AppRoutes.workspaceEditorRoute.name,
                  builder: (context, state) => const Center(child: Text('Editor')),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.workspacePreviewRoute.path,
                  name: AppRoutes.workspacePreviewRoute.name,
                  builder: (context, state) => const Center(child: Text('Preview')),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);
