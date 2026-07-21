class AppVersion {
  const AppVersion._();

  static const name = String.fromEnvironment(
    'APP_VERSION_NAME',
    defaultValue: '1.0.155',
  );
  static const build = String.fromEnvironment(
    'APP_VERSION_BUILD',
    defaultValue: '156',
  );
  static const label = 'Version $name ($build)';
}
