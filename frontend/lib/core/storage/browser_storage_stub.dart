class BrowserStorage {
  const BrowserStorage();

  String? read(String key) => null;

  void write(String key, String value) {
    throw UnsupportedError('Browser storage is only available on web.');
  }

  void delete(String key) {}
}

bool get isBrowserStorageAvailable => false;

BrowserStorage createBrowserStorage() => const BrowserStorage();
