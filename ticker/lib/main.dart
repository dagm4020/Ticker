import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'auth_wrapper.dart';
import 'home_screen.dart';
import 'watchlist_screen.dart';
import 'newsfeed_screen.dart';
import 'settings_screen.dart';
import 'settings_notifications.dart';
import 'login_page.dart';
import 'news_detail_screen.dart';
import 'results_screen.dart';
import 'splash_screen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'dart:math';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    List<String> messages = [
      "📈 Check out today's top-performing stocks!",
      "💹 See which stocks are trending today!",
      "📊 Discover which stocks are on the rise!",
      "🚀 Don't miss today's best stock performances!",
      "🔍 Explore today's standout stocks!",
      "✨ Your daily stock insights are waiting!",
      "💡 Stay updated with today's stock movements!",
      "📉 Find out which stocks are falling today!",
      "🎯 Target your investments with today's data!",
      "🔥 Hot stocks alert! Check them out now!",
    ];

    String message = messages[Random().nextInt(messages.length)];

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'daily_stock_channel',
      'Daily Stock Updates',
      channelDescription: 'Daily notifications about stock performances',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      'Stock Update',
      message,
      platformChannelSpecifics,
      payload: 'Daily Stock Notification',
    );

    return Future.value(true);
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
    print("✅ .env file loaded successfully.");
  } catch (e) {
    print("❌ Failed to load .env file: $e");
  }

  await Firebase.initializeApp();

  Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: false,
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Stock Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SplashScreen(),
      routes: {
        '/auth_wrapper': (context) => AuthWrapper(),
        '/home': (context) => HomeScreen(),
        '/watchlist': (context) => WatchlistScreen(),
        '/newsfeed': (context) => NewsfeedScreen(),
        '/settings': (context) => SettingsScreen(),
        '/settings_notifications': (context) => SettingsNotifications(),
        '/login': (context) => LoginPage(),
        '/results': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments as Map<String, String>;
          return ResultsScreen(
              symbol: args['symbol']!, apiKey: args['apiKey']!);
        },
        '/news_detail': (context) => NewsDetailScreen(),
      },
    );
  }
}
