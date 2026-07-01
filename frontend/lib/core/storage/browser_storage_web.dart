import 'package:web/web.dart' as web;

class BrowserStorage {
  const BrowserStorage();

  String? read(String key) => web.window.localStorage.getItem(key);

  void write(String key, String value) {
    web.window.localStorage.setItem(key, value);
  }

  void delete(String key) {
    web.window.localStorage.removeItem(key);
  }
}

bool get isBrowserStorageAvailable => true;

BrowserStorage createBrowserStorage() => const BrowserStorage();
