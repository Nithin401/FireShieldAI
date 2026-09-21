import 'dart:js_interop';

@JS('FireShieldNotifications.showNotification')
external void _jsShowNotification(JSString title, JSString body, JSString severity);

@JS('FireShieldNotifications.requestPermission')
external void _jsRequestPermission();

@JS('FireShieldNotifications.openUrl')
external void _jsOpenUrl(JSString url);

void triggerSystemNotification(String title, String body, String severity) {
  try {
    _jsShowNotification(title.toJS, body.toJS, severity.toJS);
  } catch (_) {}
}

void requestNotificationPermission() {
  try {
    _jsRequestPermission();
  } catch (_) {}
}

void openExternalUrl(String url) {
  try {
    _jsOpenUrl(url.toJS);
  } catch (_) {}
}
