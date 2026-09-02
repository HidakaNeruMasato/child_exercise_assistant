// File generated / configured for Firebase Project: child-exercise-assistant
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSy_DEMO_KEY_CHILD_EXERCISE_ASSISTANT',
    appId: '1:818654728220:web:childexerciseassistant',
    messagingSenderId: '818654728220',
    projectId: 'child-exercise-assistant',
    authDomain: 'child-exercise-assistant.firebaseapp.com',
    storageBucket: 'child-exercise-assistant.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSy_DEMO_KEY_CHILD_EXERCISE_ASSISTANT',
    appId: '1:818654728220:android:childexerciseassistant',
    messagingSenderId: '818654728220',
    projectId: 'child-exercise-assistant',
    storageBucket: 'child-exercise-assistant.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSy_DEMO_KEY_CHILD_EXERCISE_ASSISTANT',
    appId: '1:818654728220:ios:childexerciseassistant',
    messagingSenderId: '818654728220',
    projectId: 'child-exercise-assistant',
    storageBucket: 'child-exercise-assistant.appspot.com',
    iosBundleId: 'com.example.childExerciseAssistant',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSy_DEMO_KEY_CHILD_EXERCISE_ASSISTANT',
    appId: '1:818654728220:ios:childexerciseassistant',
    messagingSenderId: '818654728220',
    projectId: 'child-exercise-assistant',
    storageBucket: 'child-exercise-assistant.appspot.com',
    iosBundleId: 'com.example.childExerciseAssistant',
  );
}
