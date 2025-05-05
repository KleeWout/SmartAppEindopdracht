// File generated based on your google-services.json
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

/// Default Firebase configuration options for your app
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError('iOS platform not configured for Firebase');
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCUIr_DrLY-J5-GbpYMEhJ_1qjCEDlpkMc',
    appId: '1:993808106095:android:334ccf70cc40f0a900c39a',
    messagingSenderId: '993808106095',
    projectId: 'receiptapp-18cb0',
    storageBucket: 'receiptapp-18cb0.firebasestorage.app',
  );
}
