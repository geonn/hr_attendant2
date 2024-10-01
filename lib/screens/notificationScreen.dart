import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hr_attendant/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  Future<String?> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('authenticate');
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  Future<void> markNotificationAsRead(String notificationId, String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('authenticate');

    if (userId != null) {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});
    }

    ApiService api = ApiService();
    api.post('/api/doReadNotification', {'id': id});
  }

  void removeAllNotificationsByUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('authenticate');
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .get();

    for (var doc in querySnapshot.docs) {
      await doc.reference.delete();
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
        ),
        //floatingActionButton: FloatingActionButton(
        //  onPressed: removeAllNotificationsByUserId, child: Text("Remove")),
        body: FutureBuilder<String?>(
          future: getUserId(),
          builder: (BuildContext context, AsyncSnapshot<String?> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('notifications')
                    .where('userId', isEqualTo: snapshot.data.toString())
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot2) {
                  if (snapshot2.hasError) {
                    print(snapshot.data);
                    return Text(snapshot.data.toString());
                  }

                  if (snapshot2.connectionState == ConnectionState.waiting) {
                    return const Text("Loading");
                  }

                  return ListView(
                    children:
                        snapshot2.data!.docs.map((DocumentSnapshot document) {
                      Map<String, dynamic> data =
                          document.data() as Map<String, dynamic>;
                      return Card(
                        color: data['read'] ? Colors.white : Colors.grey[200],
                        child: ListTile(
                          title: Text(data['title']),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${data['body']}',
                                maxLines: 3, // Limit to 2 lines
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 10),
                              ),
                              const Divider(),
                              Text(
                                DateFormat('MM/dd hh:mm a')
                                    .format(data['timestamp'].toDate()),
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Theme.of(context).primaryColor),
                              ),
                            ],
                          ),
                          onTap: () async {
                            markNotificationAsRead(
                                document.id, data['id'] ?? "");
                            String? screen = data['screen'];
                            if (screen != null && screen != "MemoScreen") {
                              Navigator.pushNamed(context, screen);
                            } else {
                              // Show a popup dialog with the content of data['body']
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text("Memo"),
                                    content: SingleChildScrollView(
                                        child: Text(data['body'])),
                                    actions: [
                                      TextButton(
                                        child: const Text("Close"),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                    ],
                                  );
                                },
                              );
                            }
                          },
                        ),
                      );
                    }).toList(),
                  );
                },
              );
            }
          },
        ));
  }
}
