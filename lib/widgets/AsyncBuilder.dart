import 'package:flutter/material.dart';

class AsyncBuilder<T> extends StatelessWidget {
  final Future<T> future;
  final Function(BuildContext context, AsyncSnapshot<T> snapshot) builder;
  final Function(BuildContext context, Object error)? catchError;

  const AsyncBuilder({
    super.key,
    required this.future,
    required this.builder,
    this.catchError,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          if (catchError != null) {
            return catchError!(context, snapshot.error!);
          }
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        return builder(context, snapshot);
      },
    );
  }
}
