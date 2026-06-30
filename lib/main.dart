import 'dart:io';

import 'package:atril/core/config/dependencies.dart';
import 'package:atril/core/routing/router.dart';
import 'package:atril/features/core/theme/atril_theme.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

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

class AtrilApp extends StatelessWidget {
  const AtrilApp({super.key});

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
