import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationProvider extends ChangeNotifier {
  final StreamController<int> _unreadNotificationController =
      StreamController<int>.broadcast();
  Stream<int> get unreadNotificationStream =>
      _unreadNotificationController.stream;

  NotificationProvider() {
    _initUnreadNotificationStream();
  }

  void _initUnreadNotificationStream() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('authenticate');
    print('_initUnreadNotificationStream');
    print(userId);
    if (userId != null) {
      FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .snapshots()
          .listen((snapshot) {
        _unreadNotificationController.add(snapshot.docs.length);
        print('${snapshot.docs.length} number of unread notification');
      });
    }
  }

  @override
  void dispose() {
    _unreadNotificationController.close();
    super.dispose();
  }
}
