import 'package:atril/core/routing/routes.dart';
import 'package:atril/features/loading/view_model/loading_view_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key, required this.viewModel});

  final LoadingViewModel viewModel;

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_onViewModelChanged);
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_onViewModelChanged);
    super.dispose();
  }

  void _onViewModelChanged() {
    final viewModel = widget.viewModel;
    if (viewModel.isLoading) return;

    if (viewModel.hasError) {
      context.go('${AppRoutes.notFoundRoute.path}?reason=error');
    } else if (viewModel.exists) {
      context.goNamed(AppRoutes.songEditorRoute.name, pathParameters: {'filename': viewModel.filename});
    } else {
      context.go('${AppRoutes.notFoundRoute.path}?reason=not-found');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
