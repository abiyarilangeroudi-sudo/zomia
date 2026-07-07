class AppVersion {
  const AppVersion._();

  static const name = String.fromEnvironment(
    'APP_VERSION_NAME',
    defaultValue: '1.0.129',
  );
  static const build = String.fromEnvironment(
    'APP_VERSION_BUILD',
    defaultValue: '130',
  );
  static const label = 'Version $name ($build)';
}
