import 'package:flutter/material.dart';

enum ButtonSize { small, medium, large }

class CircleButton extends StatelessWidget {
  final String text;
  final ButtonSize buttonSize;
  final VoidCallback? onPressed;
  final Widget? child;

  CircleButton(
      {super.key,
      required this.text,
      this.buttonSize = ButtonSize.medium,
      VoidCallback? onPressed,
      this.child})
      : onPressed = onPressed ?? (() {});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double paddingValue;

    switch (buttonSize) {
      case ButtonSize.small:
        paddingValue = screenWidth / 3;
        break;
      case ButtonSize.medium:
        paddingValue = screenWidth / 2.5;
        break;
      case ButtonSize.large:
        paddingValue = (screenWidth / 2.5) * 1.3;
        break;
    }

    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(center: Alignment.topCenter, colors: [
          Theme.of(context).secondaryHeaderColor,
          Theme.of(context).secondaryHeaderColor,
          Theme.of(context).primaryColorLight,
        ], stops: const [
          0.2,
          1.5,
          2
        ]),
        borderRadius: BorderRadius.circular(paddingValue),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(5, 5), // changes position of shadow
          ),
        ],
      ),
      child: SizedBox(
        width: paddingValue,
        height: paddingValue,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            shape: const CircleBorder(),
            backgroundColor: Colors.transparent,
            disabledForegroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            side: BorderSide(
                color: Theme.of(context).primaryColorLight, width: 4.0),
          ),
          child: (child != null)
              ? Center(child: child)
              : Text(
                  text,
                  style: TextStyle(color: Theme.of(context).primaryColor),
                ),
        ),
      ),
    );
  }
}
