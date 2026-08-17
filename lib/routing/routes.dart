class AppRoutes {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String home = '/home';
  static const String recommendations = '/recommendations';
  static const String activityDetail = '/activity/:id';
  static const String favorites = '/favorites';
  static const String history = '/history';
  static const String profile = '/profile';
  static const String settings = '/settings';

  static String buildActivityDetailPath(String id) => '/activity/$id';
}
