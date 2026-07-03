import 'package:atril/core/routing/routes.dart';
import 'package:atril/features/loading/view_model/loading_view_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key, required this.viewModel});

  final LoadingViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel.load,
      builder: (context, _) {
        if (viewModel.load.running) return const Scaffold(body: Center(child: CircularProgressIndicator()));

        if (viewModel.load.error) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('${AppRoutes.notFoundRoute.path}?reason=error');
          });
        }

        if (viewModel.load.completed) {
          if (viewModel.hasError) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.go('${AppRoutes.notFoundRoute.path}?reason=error');
            });
          } else if (!viewModel.exists) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.go('${AppRoutes.notFoundRoute.path}?reason=not-found');
            });
          } else {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.goNamed(AppRoutes.workspaceEditorRoute.name, pathParameters: {'filename': viewModel.filename});
            });
          }
        }

        return const SizedBox.shrink();
      },
    );
  }
}
