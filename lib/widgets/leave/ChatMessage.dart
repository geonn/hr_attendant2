import 'package:flutter/material.dart';

class ChatMessage extends StatelessWidget {
  final String title;
  final String message;
  final bool isUser;

  const ChatMessage({
    super.key,
    required this.title,
    required this.message,
    this.isUser = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment:
              isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: <Widget>[
            Container(
              margin: const EdgeInsets.only(right: 4.0),
              child: CircleAvatar(child: Text(title[0])),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    Container(
                      constraints: const BoxConstraints(minWidth: 100),
                      margin: const EdgeInsets.only(top: 5.0),
                      child: Text(message),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
