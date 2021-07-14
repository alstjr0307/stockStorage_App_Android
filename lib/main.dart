

import 'package:firebase_admob/firebase_admob.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'HomePage.dart';
Future<void> _messageHandler(RemoteMessage message) async {
  print('background message ${message.notification!.body}');
}
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_messageHandler);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  ThemeMode themeMode = ThemeMode.light;

  var paddingBottom = 50.0;

  @override
  Widget build(BuildContext context) {

    const FlexScheme usedFlexScheme = FlexScheme.barossa;
    return MaterialApp(

        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          // if it's a RTL language
        ],
        supportedLocales: [
          const Locale('ko', 'KR'),
          // include country code too
        ],
      title: 'Flutter Demo',
      theme:FlexColorScheme.light(

        scheme: usedFlexScheme,
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        fontFamily: 'Hanma'
      ).toTheme,
        themeMode:  themeMode,

      home: HomePage(),
      builder: (context, widget) {

        final mediaQuery = MediaQuery.of(context);
        return new Padding(
          child: widget,
          padding: new EdgeInsets.only(bottom: paddingBottom),
        );
      },
    );
  }
}
