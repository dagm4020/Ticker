import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsNotifications extends StatefulWidget {
  @override
  _SettingsNotificationsState createState() => _SettingsNotificationsState();
}

class _SettingsNotificationsState extends State<SettingsNotifications> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  bool _isNotificationsEnabled = false;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _loadNotificationPreference();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _loadNotificationPreference() async {
    setState(() {
      _isLoading = true;
    });

    User? user = _auth.currentUser;
    if (user != null) {
      DocumentReference userDocRef =
          _firestore.collection('users').doc(user.uid);

      try {
        DocumentSnapshot userDoc = await userDocRef.get();

        if (userDoc.exists) {
          Map<String, dynamic>? data = userDoc.data() as Map<String, dynamic>?;

          if (data != null && data.containsKey('notifications_enabled')) {
            bool deviceNotificationsEnabled =
                await flutterLocalNotificationsPlugin
                        .resolvePlatformSpecificImplementation<
                            AndroidFlutterLocalNotificationsPlugin>()
                        ?.areNotificationsEnabled() ??
                    false;

            setState(() {
              _isNotificationsEnabled = data['notifications_enabled'] as bool &&
                  deviceNotificationsEnabled;
            });

            if (!deviceNotificationsEnabled &&
                data['notifications_enabled'] == true) {
              await userDocRef.set(
                  {'notifications_enabled': false}, SetOptions(merge: true));
              setState(() {
                _isNotificationsEnabled = false;
              });
            }
          } else {
            await userDocRef
                .set({'notifications_enabled': false}, SetOptions(merge: true));
            setState(() {
              _isNotificationsEnabled = false;
            });
          }
        } else {
          await userDocRef.set({'notifications_enabled': false});
          setState(() {
            _isNotificationsEnabled = false;
          });
        }
      } catch (e) {
        print('Error loading notification preference: $e');
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() {
      _isNotificationsEnabled = value;
      _isLoading = true;
    });

    User? user = _auth.currentUser;
    if (user != null) {
      DocumentReference userDocRef =
          _firestore.collection('users').doc(user.uid);

      try {
        if (value) {
          bool permissionGranted = await _requestNotificationPermission();

          if (permissionGranted) {
            await userDocRef.set({
              'notifications_enabled': true,
            }, SetOptions(merge: true));

            await _scheduleDailyNotifications();

            _sendImmediateNotification();
          } else {
            setState(() {
              _isNotificationsEnabled = false;
            });
            await userDocRef.set({
              'notifications_enabled': false,
            }, SetOptions(merge: true));
          }
        } else {
          await userDocRef.set({
            'notifications_enabled': false,
          }, SetOptions(merge: true));

          await Workmanager()
              .cancelByUniqueName('daily_stock_notification_unique');
        }
      } catch (e) {
        print('Error toggling notifications: $e');
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<bool> _requestNotificationPermission() async {
    if (await Permission.notification.isGranted) {
      return true;
    } else {
      PermissionStatus status = await Permission.notification.request();

      if (status.isGranted) {
        return true;
      } else if (status.isDenied) {
        bool shouldOpenSettings = await _showPermissionDeniedDialog();
        if (shouldOpenSettings) {
          await openAppNotificationSettings();
        }
      }
    }

    return false;
  }

  Future<bool> _showPermissionDeniedDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Notifications Disabled'),
            content: Text(
                'To receive daily stock updates, please enable notifications in your device settings.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Open Settings'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> openAppNotificationSettings() async {
    final Uri uri = Uri(
      scheme: 'package',
      path: 'com.example.ticker',
    );

    try {
      await launchUrl(
        Uri(
          scheme: 'android.settings',
          host: 'APPLICATION_DETAILS_SETTINGS',
          queryParameters: {'package': uri.path},
        ),
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      print('Could not open settings: $e');
    }
  }

  Future<void> _scheduleDailyNotifications() async {
    await Workmanager().registerPeriodicTask(
      'daily_stock_notification_unique',
      'dailyStockNotification',
      frequency: Duration(hours: 24),
      initialDelay: Duration(minutes: 1),
      constraints: Constraints(
        networkType: NetworkType.not_required,
        requiresCharging: false,
      ),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
  }

  Future<void> _sendImmediateNotification() async {
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
      payload: 'Immediate Stock Notification',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple.shade800,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black, Colors.deepPurple.shade900],
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'We value your privacy and aim to enhance your experience with timely updates. Enable notifications to receive daily insights into stock performances. Please note that these notifications are optional and can be turned off at any time. Once enabled, you will receive a notification within a minute confirming the setup.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: _isLoading
                    ? Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Enable Daily Notifications',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.deepPurple),
                              strokeWidth: 2.0,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Enable Daily Notifications',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Switch(
                            value: _isNotificationsEnabled,
                            onChanged: _toggleNotifications,
                            activeColor: Colors.deepPurple,
                          ),
                        ],
                      ),
              ),
              Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
