import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Added import

// TODO: Add Firebase options import if you are using manual setup (not FlutterFire CLI)
// import 'firebase_options.dart'; // If you used `flutterfire configure`

Future<void> main() async { // Modified to be async
  WidgetsFlutterBinding.ensureInitialized(); // Added for Firebase init
  // TODO: Replace with your actual Firebase initialization if not using FlutterFire CLI
  // See documentation: https://firebase.google.com/docs/flutter/setup#manually-initialize-firebase
  // Example using default options (if firebase_options.dart exists):
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );
  // Example for manual setup (replace with your project's specific options):
  await Firebase.initializeApp(
    // options: const FirebaseOptions(
    //   apiKey: "YOUR_API_KEY",
    //   authDomain: "YOUR_AUTH_DOMAIN",
    //   projectId: "YOUR_PROJECT_ID",
    //   storageBucket: "YOUR_STORAGE_BUCKET",
    //   messagingSenderId: "YOUR_MESSAGING_SENDER_ID",
    //   appId: "YOUR_APP_ID",
    //   measurementId: "YOUR_MEASUREMENT_ID" // Optional
    // ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
import 'package:control_escolar_app/views/login_screen.dart'; // Import LoginScreen

// ... (other imports and Firebase initialization code remain the same) ...
        useMaterial3: true,
      ),
      home: const LoginScreen(), // Set LoginScreen as home
    );
  }
}

// MyHomePage and _MyHomePageState classes are removed as they are no longer the initial screen.
