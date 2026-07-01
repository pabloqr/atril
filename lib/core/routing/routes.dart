// ignore_for_file: unused_element

final class AppRoute {
  AppRoute({required this.name, required this.path}) : assert(name.isNotEmpty), assert(path.isNotEmpty);

  final String name;
  final String path;
}

// -------------------------------------------------------------------------------------------------------------------//
// COMMON ROUTES
// -------------------------------------------------------------------------------------------------------------------//
const _authRelative = '/auth';
const _songsRelative = '/songs';
const _usersRelative = '/users';

// abstract final class ServerRoutes {
//   static const signUpRoute = '$_authRelative/signup';
//   static const signInRoute = '$_authRelative/signin';
//   static const refreshAuthRoute = '$_authRelative/refresh-token';
//   static const signOutRoute = '$_authRelative/signout';
// }

abstract final class AppRoutes {
  // static const _clientRelative = '/client';
  // static const _adminRelative = '/admin';

  static const _homeRelative = '/';
  // static const _exploreRelative = '/explore';
  // static const _profileRelative = '/profile';
  static const _settingsRelative = '/settings';

  // static final welcomeRoute = '/welcome';

  // static final signUpRoute = '/signup';
  // static final signInRoute = '/signin';

  static final notFoundRoute = AppRoute(name: 'not-found', path: '/__not-found');

  static final homeRoute = AppRoute(name: 'home', path: _homeRelative);
  // static final profileRoute = _profileRelative;
  static final settingsRoute = AppRoute(name: 'settings', path: _settingsRelative);

  static final songItemRoute = AppRoute(name: 'song', path: '$_songsRelative/:filename');

  static final songPreviewRoute = AppRoute(name: 'song-preview', path: '${songItemRoute.path}/preview');
  static final songEditorRoute = AppRoute(name: 'song-editor', path: '${songItemRoute.path}/editor');
}
