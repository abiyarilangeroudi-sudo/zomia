class AppFeatures {
  const AppFeatures._();

  static const enableUiCatalog = bool.fromEnvironment(
    'ENABLE_UI_CATALOG',
    defaultValue: false,
  );
}
