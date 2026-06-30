import 'package:atril/data/repositories/song/song_repository.dart';
import 'package:atril/data/services/persistence/persistence_service.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

List<SingleChildWidget> getAppProviders({required String baseDirPath}) {
  return [
    // ---------------------------------------------------------------------------------------------------------------//
    // BASE DEPENDENCIES
    // ---------------------------------------------------------------------------------------------------------------//
    // Provider<http.Client>(create: (_) => http.Client(), dispose: (_, client) => client.close()),

    // Provider<FlutterSecureStorage>(create: (_) => const FlutterSecureStorage()),
    // Provider<SharedPreferences>.value(value: sharedPreferences),

    // ---------------------------------------------------------------------------------------------------------------//
    // SERVICES LEVEL 1 (No dependencies on other custom services)
    // ---------------------------------------------------------------------------------------------------------------//
    Provider<PersistenceService>(create: (context) => LocalPersistenceService(baseDirPath: baseDirPath)),

    // ---------------------------------------------------------------------------------------------------------------//
    // REPOSITORIES LEVEL 1 (Depend on services from level 1)
    // ---------------------------------------------------------------------------------------------------------------//
    Provider<SongRepository>(create: (context) => SongRepositoryImpl(service: context.read()) as SongRepository),

    // ---------------------------------------------------------------------------------------------------------------//
    // SERVICES LEVEL 2 (Depend on repositories or services from level 1)
    // ---------------------------------------------------------------------------------------------------------------//

    // ---------------------------------------------------------------------------------------------------------------//
    // REPOSITORIES LEVEL 2 (Depend on services from level 2)
    // ---------------------------------------------------------------------------------------------------------------//

    // ---------------------------------------------------------------------------------------------------------------//
    // PROVIDERS (ChangeNotifiers)
    // ---------------------------------------------------------------------------------------------------------------//
  ];
}
