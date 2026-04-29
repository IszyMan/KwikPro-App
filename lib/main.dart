import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if(kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
          apiKey: "AIzaSyCIwcdsN-VY2cutAiDD-9HcrdIOhvNOVLE",
          authDomain: "kwikpro-app.firebaseapp.com",
          appId: "1:648958053897:web:99a585daf09aad6d36b2d8",
          storageBucket: "kwikpro-app.firebasestorage.app",
          messagingSenderId: "648958053897",
          projectId: "kwikpro-app")
    );

  }else {
    await Firebase.initializeApp();
  }
  runApp(const ProviderScope(child: MyApp()));
}