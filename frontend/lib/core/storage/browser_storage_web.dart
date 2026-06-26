// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class BrowserStorage {
  const BrowserStorage();

  String? read(String key) => html.window.localStorage[key];

  void write(String key, String value) {
    html.window.localStorage[key] = value;
  }

  void delete(String key) {
    html.window.localStorage.remove(key);
  }
}

bool get isBrowserStorageAvailable => true;

BrowserStorage createBrowserStorage() => const BrowserStorage();
