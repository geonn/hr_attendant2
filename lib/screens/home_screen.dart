import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:hr_attendant/models/profile.dart';
import 'package:hr_attendant/provider/LeaveProvider.dart';
import 'package:hr_attendant/provider/PayslipProvider.dart';
import 'package:hr_attendant/provider/attendance_provider.dart';
import 'package:hr_attendant/provider/claimProvider.dart';
import 'package:hr_attendant/screens/%20attendance/AttendanceScreen.dart';
import 'package:hr_attendant/screens/claim/ClaimScreen.dart';
import 'package:hr_attendant/screens/leave/LeaveScreen.dart';
import 'package:hr_attendant/screens/memo/memoScreen.dart';
import 'package:hr_attendant/screens/notificationScreen.dart';
import 'package:hr_attendant/services/api_service.dart';
import 'package:hr_attendant/services/auth_service.dart';
import 'package:hr_attendant/widgets/AsyncBuilder.dart';
import 'package:hr_attendant/widgets/AttendanceOverviewBox.dart';
import 'package:hr_attendant/widgets/LeaveOverviewBox.dart';
import 'package:hr_attendant/widgets/ProfileAvatar.dart';
import 'package:hr_attendant/widgets/home/buildCircleButton.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upgrader/upgrader.dart';

class HomeScreen extends StatefulWidget {
  final Function(MaterialColor) updateThemeColor;

  const HomeScreen({super.key, required this.updateThemeColor});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();

  final ImagePicker _picker = ImagePicker();
  bool isReminderEnabled = false;

  Future<void> _logout(BuildContext context) async {
    Provider.of<AttendanceProvider>(context, listen: false).reset();
    Provider.of<ClaimProvider>(context, listen: false).reset();
    Provider.of<LeaveProvider>(context, listen: false).reset();
    Provider.of<PayslipProvider>(context, listen: false).reset();

    await _authService.logout();
    Navigator.of(context)
        .pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  void setupMessaging() async {
    print('setupMessaging');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('onMessage listen');
      FirebaseFirestore.instance.collection('notifications').add({
        'title': message.notification?.title ?? 'Default title',
        'body': message.notification?.body ?? 'Default body',
        'userId': prefs.getString('authenticate'), // Use the user ID
        'timestamp': FieldValue.serverTimestamp(),
        'screen': message.data['screen'] ?? "",
        'id': message.data['id'] ?? "",
        'read': false, // Add a 'read' field for read/unread status
      });
    });
    //if (Platform.isIOS) {
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print('onMessageOpenedApp');
      FirebaseFirestore.instance.collection('notifications').add({
        'title': message.notification?.title ?? 'Default title',
        'body': message.notification?.body ?? 'Default body',
        'userId': prefs.getString('authenticate'), // Use the user ID
        'timestamp': FieldValue.serverTimestamp(),
        'screen': message.data['screen'] ?? "",
        'read': false, // Add a 'read' field for read/unread status
      });
    });
    //}
    /*FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage? message) async {
      print('getInitialMessage');
      FirebaseFirestore.instance.collection('notifications').add({
        'title': message!.notification?.title ?? 'Default title',
        'body': message.notification?.body ?? 'Default body',
        'userId': prefs.getString('authenticate'), // Use the user ID
        'timestamp': FieldValue.serverTimestamp(),
        'screen': message.data['screen'] ?? "",
        'id': message.data['id'] ?? "",
        'read': false, // Add a 'read' field for read/unread status
      });
    });*/
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _loadReminderPreference();
    //FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    /*if (!_isMessagingSetup) {
      _isMessagingSetup = true;
      setupMessaging();
    }*/
    final attendanceProvider =
        Provider.of<AttendanceProvider>(context, listen: false);
    attendanceProvider.fetchTodayAttendance();
    final leaveProvider = Provider.of<LeaveProvider>(context, listen: false);
    leaveProvider.fetchLeaves();
  }

  _loadReminderPreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isReminderEnabled = prefs.getBool('isReminderEnabled') ?? false;
    });
  }

  _saveReminderPreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isReminderEnabled', isReminderEnabled);
  }

  Future<void> _pickImage() async {
    ApiService apiService = ApiService();
    final pickedImageSource = await showDialog<ImageSource>(
          context: context,
          builder: (BuildContext context) {
            return SimpleDialog(
              title: const Text('Choose image source'),
              children: <Widget>[
                SimpleDialogOption(
                  onPressed: () {
                    Navigator.pop(context, ImageSource.camera);
                  },
                  child: const Text('Take a picture'),
                ),
                SimpleDialogOption(
                  onPressed: () {
                    Navigator.pop(context, ImageSource.gallery);
                  },
                  child: const Text('Choose from gallery'),
                ),
              ],
            );
          },
        ) ??
        ImageSource.gallery;

    final XFile? pickedFile =
        await _picker.pickImage(source: pickedImageSource);

    if (pickedFile != null) {
      // Now you have the image file, you can use it to upload
      // Convert the XFile to File
      File file = File(pickedFile.path);

      // Call the upload function

      apiService
          .postWithFile("/api/uploadProfileHeadshot", {}, file)
          .then((value) {
        setState(() {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print('home');
    print(Theme.of(context).secondaryHeaderColor);
    return UpgradeAlert(
      upgrader: Upgrader(
        durationUntilAlertAgain: const Duration(days: 1),
      ),
      child: Scaffold(
          drawer: Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                  ),
                  child: const Text(
                    'Menu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Logout'),
                  onTap: () {
                    _logout(context);
                  },
                ),
                SwitchListTile(
                  title: const Text('Enable Clock Time Reminder'),
                  value: isReminderEnabled,
                  secondary: const Icon(Icons.timelapse_sharp),
                  onChanged: (bool value) {
                    setState(() {
                      isReminderEnabled = value;
                    });
                    _saveReminderPreference();
                    // Additional code to enable/disable the reminder
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.color_lens),
                  title: const Text('Change Theme Color'),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return SimpleDialog(
                          title: const Text('Select Theme Color'),
                          children: [
                            ListTile(
                              title: const Text('Light Green'),
                              onTap: () {
                                widget.updateThemeColor(Colors.lightGreen);
                                Navigator.pop(context);
                              },
                            ),
                            ListTile(
                              title: const Text('Light Blue'),
                              onTap: () {
                                widget.updateThemeColor(Colors.lightBlue);
                                Navigator.pop(context);
                              },
                            ),
                            ListTile(
                              title: const Text('Red'),
                              onTap: () {
                                widget.updateThemeColor(Colors.red);
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          appBar: AppBar(
            title: Image.asset(
              'assets/images/hrms_logo.png', // Replace with the path to your logo image
              height: 50.0,
            ),
            actions: <Widget>[
              StreamBuilder<int>(
                initialData: 0,
                stream:
                    getUnreadNotificationCountStream(), // Provider.of<NotificationProvider>(context).unreadNotificationStream,

                builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else {
                    return Stack(
                      children: <Widget>[
                        IconButton(
                          icon: const Icon(Icons.notifications),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const NotificationScreen()),
                            );
                          },
                        ),
                        if (snapshot.data != null && snapshot.data! > 0)
                          Positioned(
                            right: 10,
                            bottom: 10,
                            child: Container(
                              padding: const EdgeInsets.all(1),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 12,
                                minHeight: 12,
                              ),
                              child: Text(
                                '${snapshot.data}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    );
                  }
                },
              )
            ],
          ),
          body: AsyncBuilder<Profile>(
            future: _authService.getUserProfile(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final profile = snapshot.data!;
                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        color: Theme.of(context).primaryColor,
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            ProfileAvatar(
                              imageUrl: profile.profilePicture,
                              onTap: () {
                                _pickImage();
                                // handle avatar editing
                              },
                            ),
                            const SizedBox(width: 16.0),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome, ${profile.name}!',
                                    style: const TextStyle(
                                      fontSize: 20.0,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 8.0),
                                  Text(
                                    '${profile.company_name}, ${profile.position}',
                                    style: const TextStyle(
                                      fontSize: 16.0,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Consumer<LeaveProvider>(
                                builder: (context, leaveProvider, child) =>
                                    LeaveOverviewBox(
                                  totalLeave: double.tryParse(leaveProvider
                                          .leaveSummary['total_leave']
                                          .toString()) ??
                                      0.0,
                                  leaveBalance: double.tryParse(leaveProvider
                                          .leaveSummary['leave_balance']
                                          .toString()) ??
                                      0.0,
                                  leaveApplied: double.tryParse(leaveProvider
                                          .leaveSummary['leave_applied']
                                          .toString()) ??
                                      0.0,
                                  leaveApproved: double.tryParse(leaveProvider
                                          .leaveSummary['leave_approved']
                                          .toString()) ??
                                      0.0,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16.0),
                            Expanded(
                              child: Stack(
                                children: [
                                  FutureBuilder(
                                    future: Provider.of<AttendanceProvider>(
                                            context,
                                            listen: false)
                                        .fetchAttendance(
                                            DateTime(DateTime.now().year,
                                                DateTime.now().month, 1),
                                            DateTime(DateTime.now().year,
                                                DateTime.now().month + 1, 0)),
                                    builder: (BuildContext context,
                                        AsyncSnapshot<void> snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const Center(
                                            child:
                                                CircularProgressIndicator()); // or your custom loading widget
                                      } else {
                                        if (snapshot.error != null) {
                                          // Error handling
                                          return const Center(
                                              child:
                                                  Text('An error occurred!'));
                                        } else {
                                          return Consumer<AttendanceProvider>(
                                            builder: (context, provider, _) {
                                              final counts = provider
                                                  .countAttendanceStatusForCurrentMonth();
                                              return AttendanceOverviewBox(
                                                onTimeCount:
                                                    counts['onTimeCount'] ?? 0,
                                                overtimeCount:
                                                    counts['overtimeCount'] ??
                                                        0,
                                                absentCount:
                                                    counts['absentCount'] ?? 0,
                                              );
                                            },
                                          );
                                        }
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      LayoutBuilder(
                        builder:
                            (BuildContext context, BoxConstraints constraints) {
                          double containerWidth = constraints.maxWidth;

                          return Container(
                            width: containerWidth,
                            height: containerWidth,
                            padding: const EdgeInsets.all(8.0),
                            child: Stack(
                              children: [
                                Align(
                                  alignment: Alignment.topLeft,
                                  child: CircleButton(
                                    text: 'Claim',
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const ClaimScreen()),
                                      );
                                    },
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.topRight,
                                  child: CircleButton(
                                    text: 'Leave',
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const LeavePage()),
                                      );
                                    },
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.bottomLeft,
                                  child: CircleButton(
                                    text: 'Notification',
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const NotificationScreen()),
                                      );
                                    },
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: CircleButton(
                                    text: 'Company Memo',
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const MemoScreen()),
                                      );
                                    },
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.center,
                                  child: CircleButton(
                                    text: 'Attendance',
                                    buttonSize: ButtonSize.large,
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const AttendancePage()),
                                      );
                                    },
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Column(
                                          children: [
                                            const SizedBox(
                                              height: 10,
                                            ),
                                            const Text(
                                              'IN',
                                            ),
                                            Consumer<AttendanceProvider>(
                                              builder: (context, provider, _) =>
                                                  Text(
                                                provider.getTodayInTime() ??
                                                    "__:__",
                                                style: const TextStyle(
                                                    color: Colors.black),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const Text(
                                          "Attendance",
                                          style: TextStyle(fontSize: 18),
                                        ),
                                        Column(
                                          children: [
                                            const Text('OUT'),
                                            Text(
                                              Provider.of<AttendanceProvider>(
                                                          context,
                                                          listen: true)
                                                      .getTodayOutTime() ??
                                                  "__:__ ",
                                              style: const TextStyle(
                                                  color: Colors.black),
                                            ),
                                            const SizedBox(
                                              height: 10,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              } else if (snapshot.hasError) {
                return Center(
                  child: Text(snapshot.error.toString()),
                );
              } else {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
            },
            catchError: (context, error) {
              // Handle the error here
              /*ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to load profile. User logged out.'),
                ),
              );*/
              // Navigate the user back to the login screen

              return Center(child: Text('Error: $error'));
            },
          )),
    );
  }

  Stream<int> getUnreadNotificationCountStream() async* {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('authenticate');
    print('UserId: $userId');

    if (userId != null) {
      StreamController<int> controller = StreamController<int>.broadcast();

      FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .snapshots()
          .listen((snapshot) {
        print('Unread notifications: ${snapshot.docs.length}');
        controller.add(snapshot.docs.length);
      }, onError: (error) {
        print('Error querying Firestore: $error');
        controller.addError(error);
      });

      yield* controller.stream;
    } else {
      print('UserId is null');
    }
  }
}
