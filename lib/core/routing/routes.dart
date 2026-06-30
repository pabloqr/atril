// ignore_for_file: unused_element

// -------------------------------------------------------------------------------------------------------------------//
// COMMON ROUTES
// -------------------------------------------------------------------------------------------------------------------//
const String _authRelative = '/auth';
const String _songsRelative = '/songs';
const String _usersRelative = '/users';

// abstract final class ServerRoutes {
//   static const String signUpRoute = '$_authRelative/signup';
//   static const String signInRoute = '$_authRelative/signin';
//   static const String refreshAuthRoute = '$_authRelative/refresh-token';
//   static const String signOutRoute = '$_authRelative/signout';
// }

abstract final class AppRoutes {
  // static const String _clientRelative = '/client';
  // static const String _adminRelative = '/admin';

  static const String _homeRelative = '/home';
  // static const String _exploreRelative = '/explore';
  static const String _profileRelative = '/profile';
  static const String _settingsRelative = '/settings';

  // static const String welcomeRoute = '/welcome';

  // static const String signUpRoute = '/signup';
  // static const String signInRoute = '/signin';

  static const String dashboardRoute = _homeRelative;
  static const String songsRoute = _songsRelative;
  static const String clientProfileRoute = _profileRelative;
  static const String clientSettingsRoute = _settingsRelative;

  static const String songEditorRoute = '$_songsRelative/editor';
  static const String songPreviewRoute = '$_songsRelative/preview';
}
