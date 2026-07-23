import 'package:atril/core/routing/route_observer.dart';
import 'package:atril/core/routing/routes.dart';
import 'package:atril/data/services/song/source_editor.dart';
import 'package:atril/features/dashboard/view_model/song_list_view_model.dart';
import 'package:atril/features/dashboard/widgets/song_list_screen.dart';
import 'package:atril/features/loading/view_model/loading_view_model.dart';
import 'package:atril/features/loading/widgets/loading_screen.dart';
import 'package:atril/features/workspace/view_model/editor_view_model.dart';
import 'package:atril/features/workspace/view_model/workspace_view_model.dart';
import 'package:atril/features/workspace/widgets/editor_screen.dart';
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
  observers: [appRouteObserver],
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
      path: AppRoutes.workspaceRoute().path,
      name: AppRoutes.workspaceRoute().name,
      builder: (context, state) {
        final filename = state.pathParameters['filename']!;

        final workspaceViewModel = WorkspaceViewModel(songRepository: context.read(), filename: filename);
        final editorViewModel = EditorViewModel(
          workspaceViewModel: workspaceViewModel,
          sourceEditor: const SourceEditor(),
        );

        return LoadingScreen(
          viewModel: LoadingViewModel(songRepository: context.read(), filename: filename),
          child: WorkspaceScaffold(
            key: ValueKey(filename),
            viewModel: workspaceViewModel,
            editorViewModel: editorViewModel,
            // editorScreen: const Center(child: Text('Editor')),
            editorScreen: EditorScreen(viewModel: editorViewModel),
            previewScreen: const Center(child: Text('Preview')),
          ),
        );
      },
    ),
  ],
);
