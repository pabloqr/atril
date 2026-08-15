import 'package:atril/core/routing/routes.dart';
import 'package:atril/features/loading/view_model/loading_view_model.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key, required this.viewModel, required this.child});

  final LoadingViewModel viewModel;

  final Widget child;

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
          if (!viewModel.exists) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.go('${AppRoutes.notFoundRoute.path}?reason=not-found');
            });
          } else {
            final state = GoRouterState.of(context);
            final workspacePath = AppRoutes.workspaceRoute(viewModel.filename).path;

            if (state.uri.path == workspacePath) {
              return child;
            }
          }
        }

        return const SizedBox.shrink();
      },
    );
  }
}
