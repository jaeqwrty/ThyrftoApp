import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      // case TargetPlatform.iOS:
      //   return ios;
      // case TargetPlatform.macOS:
      //   return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions has not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions has not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions has not been configured for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyBXo3rP_sCj2LLUVaq8lp4egSNn0-jOdPE",
    authDomain: "thryfto-ab058.firebaseapp.com",
    projectId: "thryfto-ab058",
    storageBucket: "thryfto-ab058.firebasestorage.app",
    messagingSenderId: "41459314240",
    appId: "1:41459314240:web:21ad79876d3c10549639a5",
    measurementId: "G-HGC9VB3Z8S",
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDblywVAJQ6DsI_KXBGUC2gKBUDdp0dosU',
    appId: '1:41459314240:android:9fc52c60036ac3c39639a5',
    messagingSenderId: '41459314240',
    projectId: 'thryfto-ab058',
  );

  // static const FirebaseOptions ios = FirebaseOptions(
  //   apiKey: 'YOUR_IOS_API_KEY',
  //   appId: 'YOUR_IOS_APP_ID',
  //   messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
  //   projectId: 'your-project-id',
  //   iosBundleId: 'com.example.thryfto',
  // );

  // static const FirebaseOptions macos = FirebaseOptions(
  //   apiKey: 'YOUR_MACOS_API_KEY',
  //   appId: 'YOUR_MACOS_APP_ID',
  //   messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
  //   projectId: 'your-project-id',
  //   iosBundleId: 'com.example.thryfto',
  // );
}
