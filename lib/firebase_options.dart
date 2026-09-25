// File generated for FireShield AI project: smart-fire-detection-272bb
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA_SmartFireDetection_WebKey',
    appId: '1:982341234567:web:8219abf32489c721',
    messagingSenderId: '982341234567',
    projectId: 'smart-fire-detection-272bb',
    authDomain: 'smart-fire-detection-272bb.firebaseapp.com',
    databaseURL: 'https://smart-fire-detection-272bb-default-rtdb.firebaseio.com',
    storageBucket: 'smart-fire-detection-272bb.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA_SmartFireDetection_AndroidKey',
    appId: '1:982341234567:android:98721389472198',
    messagingSenderId: '982341234567',
    projectId: 'smart-fire-detection-272bb',
    databaseURL: 'https://smart-fire-detection-272bb-default-rtdb.firebaseio.com',
    storageBucket: 'smart-fire-detection-272bb.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA_SmartFireDetection_IosKey',
    appId: '1:982341234567:ios:123891238912893',
    messagingSenderId: '982341234567',
    projectId: 'smart-fire-detection-272bb',
    databaseURL: 'https://smart-fire-detection-272bb-default-rtdb.firebaseio.com',
    storageBucket: 'smart-fire-detection-272bb.appspot.com',
    iosBundleId: 'com.fireshield.app',
  );
}
