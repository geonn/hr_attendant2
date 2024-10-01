import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:hr_attendant/provider/LeaveProvider.dart';
import 'package:hr_attendant/provider/MessagingProvider.dart';
import 'package:hr_attendant/provider/NotificationProvider.dart';
import 'package:hr_attendant/provider/claimProvider.dart';
import 'package:hr_attendant/screens/home_screen.dart';
import 'package:hr_attendant/screens/leave/LeaveScreen.dart';
import 'package:hr_attendant/screens/pdfViewer.dart';
import 'package:hr_attendant/services/auth_service.dart';
import 'package:hr_attendant/utils/theme_helper.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'provider/PayslipProvider.dart';
import 'provider/attendance_provider.dart';
import 'screens/login_screen.dart';
import 'firebase_options.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

Logger log = Logger();
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initializeNotifications();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  print("initial getInitialMessage");
  FirebaseMessaging.instance
      .getInitialMessage()
      .then((RemoteMessage? message) async {
    print("Inside getInitialMessage");
    print(message?.notification?.title ?? "empty");
    if (message != null) {
      print("Terminated State:");
      // Handle the notification caused by tapping on it in the system tray.
      SharedPreferences prefs = await SharedPreferences.getInstance();
      FirebaseFirestore.instance.collection('notifications').add({
        'title': message.notification?.title ?? 'Default title',
        'body': message.notification?.body ?? 'Default body',
        'userId': prefs.getString('authenticate'), // Use the user ID
        'id': message.data['id'] ?? "",
        'timestamp': FieldValue.serverTimestamp(),
        'screen': message.data['screen'] ?? "",
        'read': false, // Add a 'read' field for read/unread status
      });
    }
  });
  print("after getInitialMessage");
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  FirebaseMessaging.instance.subscribeToTopic('all');
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('User granted permission');
  } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
    print('User granted provisional permission');
  } else {
    print('User declined or has not accepted permission');
  }
  messaging = FirebaseMessaging.instance;
  messaging.getToken().then((token) async {
    print('token here');
    print(token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fcm_token', token ?? '');
  });

  MaterialColor themeColor = await loadThemeColor();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => MessagingProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(
          create: (_) => LeaveProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => AttendanceProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => PayslipProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => ClaimProvider(),
        )
      ],
      child: MyApp(
        themeColor: themeColor,
      ),
    ),
  );
}

Future<void> initializeTimeZones() async {
  print("Initializing timezones in main.dart");
  tz.initializeTimeZones();
  final String timeZoneName = await FlutterTimezone.getLocalTimezone();
  print('check timeZoneName here');
  print(timeZoneName);
  // Check if timeZoneName is in a "+HH" or "-HH" format
  if (RegExp(r'^[+-]\d{2}$').hasMatch(timeZoneName)) {
    // Default to a known timezone, e.g., "UTC"
    tz.setLocalLocation(tz.getLocation('UTC'));
  } else {
    try {
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      // Default to 'UTC' if the timezone is not found
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
  }
}

void initializeNotifications() {
  initializeTimeZones();
  //tz.setLocalLocation(tz.getLocation(DateTime.now().timeZoneName));
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  const DarwinInitializationSettings darwinInitializationSettings =
      DarwinInitializationSettings(
          onDidReceiveLocalNotification: onDidReceiveLocalNotification);

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: darwinInitializationSettings);

  flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

Future onDidReceiveLocalNotification(
    int id, String? title, String? body, String? payload) async {
  // Handle notification received in the foreground
  // This is primarily for iOS versions before iOS 10
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('_firebaseMessagingBackgroundHandler');

  SharedPreferences prefs = await SharedPreferences.getInstance();
  FirebaseFirestore.instance.collection('notifications').add({
    'title': message.notification?.title ?? 'Default title',
    'body': message.notification?.body ?? 'Default body',
    'userId': prefs.getString('authenticate'), // Use the user ID
    'id': message.data['id'] ?? "",
    'timestamp': FieldValue.serverTimestamp(),
    'screen': message.data['screen'] ?? "",
    'read': false, // Add a 'read' field for read/unread status
  });
  print("Handling a background message: ${message.messageId}");
}

class MyApp extends StatefulWidget {
  final MaterialColor themeColor;

  const MyApp({super.key, required this.themeColor});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  MaterialColor _themeColor = Colors.lightGreen;
  bool _notificationsEnabled = false;
  @override
  void initState() {
    _themeColor = widget.themeColor;
    // TODO: implement initState
    super.initState();
    Provider.of<MessagingProvider>(context, listen: false);
    _isAndroidPermissionGranted();
    _requestPermissions();
  }

  Future<void> _isAndroidPermissionGranted() async {
    if (Platform.isAndroid) {
      final bool granted = await flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>()
              ?.areNotificationsEnabled() ??
          false;
      setState(() {
        _notificationsEnabled = granted;
      });
    }
  }

  Future<void> _requestPermissions() async {
    if (Platform.isIOS || Platform.isMacOS) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    } else if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      final bool? granted =
          await androidImplementation?.requestNotificationsPermission();
      setState(() {
        _notificationsEnabled = granted ?? false;
      });
    }
  }

  void updateThemeColor(MaterialColor color) {
    setState(() {
      _themeColor = color;
    });

    saveThemeColor(color);
  }

  final AuthService authService = AuthService();

  @override
  Widget build(BuildContext context) {
    print('rebuild');
    print(_themeColor);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flexben HRMS',
      theme: ThemeData(
        primarySwatch: _themeColor,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        colorScheme: ColorScheme.fromSeed(seedColor: _themeColor),
        useMaterial3: true,
        scaffoldBackgroundColor: _themeColor.shade50,
        appBarTheme: AppBarTheme(backgroundColor: _themeColor.shade100),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        ),
      ),
      home: FutureBuilder<bool>(
        future: authService.isAuthenticated(),
        builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasData && snapshot.data == true) {
              return HomeScreen(updateThemeColor: updateThemeColor);
            } else {
              return const LoginScreen();
            }
          } else {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
        },
      ),
      routes: {
        '/pdfViewerPage': (context) => PDF(''),
        "/login": (context) => const LoginScreen(),
        "LeaveScreen": (context) => const LeavePage(),
      },
    );
  }
}
