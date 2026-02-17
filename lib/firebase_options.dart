import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDBJnVTcW_29irNz2syDvskex0zxtrrPW0',
    appId: '1:608662564660:android:841fdab21611df09bfbf61',
    messagingSenderId: '608662564660',
    projectId: 'merorides-driver',
    storageBucket: 'merorides-driver.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDyThtwfUjTDrF-lj7APDSvqiij1BguiSw',
    appId: '1:608662564660:ios:9c10b8cd354de26fbfbf61',
    messagingSenderId: '608662564660',
    projectId: 'merorides-driver',
    storageBucket: 'merorides-driver.firebasestorage.app',
    iosClientId: '608662564660-ob85e68hbg8bfjnnej08gprt1vdcvl30.apps.googleusercontent.com',
    iosBundleId: 'com.merorides.meroridesdriver',
  );
}
