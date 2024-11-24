// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
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
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBDcZ7MWhMBNBsJu2BBT3Q2IpG0EifQ9ic',
    appId: '1:516179892419:web:c109f3d62ddef712c92a76',
    messagingSenderId: '516179892419',
    projectId: 'taprak-3f096',
    authDomain: 'taprak-3f096.firebaseapp.com',
    storageBucket: 'taprak-3f096.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCVuh8FZTV0lqpnrJirUUhdfat83Ysu8TE',
    appId: '1:516179892419:android:986e23dc1abb77c6c92a76',
    messagingSenderId: '516179892419',
    projectId: 'taprak-3f096',
    storageBucket: 'taprak-3f096.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAXwK_aR2hT4K3Ht6RkaMWQBrKjBmlP1iw',
    appId: '1:516179892419:ios:7478c1379dcd3207c92a76',
    messagingSenderId: '516179892419',
    projectId: 'taprak-3f096',
    storageBucket: 'taprak-3f096.firebasestorage.app',
    iosBundleId: 'com.example.tugasakhirprak1',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAXwK_aR2hT4K3Ht6RkaMWQBrKjBmlP1iw',
    appId: '1:516179892419:ios:7478c1379dcd3207c92a76',
    messagingSenderId: '516179892419',
    projectId: 'taprak-3f096',
    storageBucket: 'taprak-3f096.firebasestorage.app',
    iosBundleId: 'com.example.tugasakhirprak1',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBDcZ7MWhMBNBsJu2BBT3Q2IpG0EifQ9ic',
    appId: '1:516179892419:web:6f958277efad836fc92a76',
    messagingSenderId: '516179892419',
    projectId: 'taprak-3f096',
    authDomain: 'taprak-3f096.firebaseapp.com',
    storageBucket: 'taprak-3f096.firebasestorage.app',
  );
}
