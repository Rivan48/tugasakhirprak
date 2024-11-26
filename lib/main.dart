import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Tambahkan provider
import 'package:tugasakhirprak1/pages/homePage.dart';
import 'package:tugasakhirprak1/pages/loginPage.dart';
import 'package:tugasakhirprak1/pages/provider/language_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:tugasakhirprak1/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  WidgetsFlutterBinding.ensureInitialized();

  AwesomeNotifications().initialize(
    // Set the icon for notifications (use a drawable asset for Android)
    'resource://drawable/res_app_icon',
    [
      NotificationChannel(
        channelKey: 'comments_channel',
        channelName: 'Comment Notifications',
        channelDescription: 'Notifications for replies on comments',
        importance: NotificationImportance.High,
        defaultColor: Color(0xFF4CAF50),
        ledColor: Colors.white,
      )
    ],
  );
  AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
    if (!isAllowed) {
      // Minta izin kepada pengguna
      AwesomeNotifications().requestPermissionToSendNotifications();
    }
  });
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => LanguageProvider()), // Tambahkan LanguageProvider
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'News App',
        theme: ThemeData(
          primarySwatch: Colors.green,
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: AppBarTheme(
            elevation: 0,
            backgroundColor: Color(0xFF4CAF50),
          ),
        ),
        home: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasData) {
              return HomePage();
            }
            return LoginPage();
          },
        ),
      ),
    );
  }
}
