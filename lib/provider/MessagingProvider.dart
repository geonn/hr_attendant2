import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MessagingProvider with ChangeNotifier {
  MessagingProvider() {
    _initMessaging();
  }

  void _initMessaging() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleMessage(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleMessage(message);
    });
  }

  void _handleMessage(RemoteMessage message) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    FirebaseFirestore.instance.collection('notifications').add({
      'title': message.notification?.title ?? 'Default title',
      'body': message.notification?.body ?? 'Default body',
      'userId': prefs.getString('authenticate'), // Use the user ID
      'timestamp': FieldValue.serverTimestamp(),
      'screen': message.data['screen'] ?? "",
      'read': false, // Add a 'read' field for read/unread status
    });
  }
}
