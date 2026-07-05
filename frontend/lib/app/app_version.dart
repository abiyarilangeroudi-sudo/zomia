class AppVersion {
  const AppVersion._();

  static const name = String.fromEnvironment(
    'APP_VERSION_NAME',
    defaultValue: '1.0.126',
  );
  static const build = String.fromEnvironment(
    'APP_VERSION_BUILD',
    defaultValue: '127',
  );
  static const label = 'Version $name ($build)';
}
