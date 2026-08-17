import 'dart:io';

import 'package:atril/core/config/dependencies.dart';
import 'package:atril/core/routing/router.dart';
import 'package:atril/features/core/theme/atril_theme.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

/// Initializes application storage and dependency providers, then starts Atril.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final baseDirectory = await getApplicationDocumentsDirectory();

  runApp(
    MultiProvider(
      providers: getAppProviders(baseDirPath: '${baseDirectory.path}${Platform.pathSeparator}Atril'),
      child: const AtrilApp(),
    ),
  );
}

/// The root Atril application widget.
class const AtrilApp({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Atril',
      theme: AtrilTheme.light(),
      darkTheme: AtrilTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: router(),
    );
  }
}
