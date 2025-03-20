import 'package:flutter/material.dart';

// Enum for toast states
enum ToastStates { SUCCESS, ERROR, WARNING }

// Global key for accessing scaffold messenger from anywhere
final GlobalKey<ScaffoldMessengerState> snackbarKey =
    GlobalKey<ScaffoldMessengerState>();

// Function to show toast using SnackBar
void showToast({
  required String msg,
  required ToastStates state,
  Duration duration = const Duration(seconds: 3),
}) {
  final SnackBar snackBar = SnackBar(
    content: Text(
      msg,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16.0,
      ),
    ),
    backgroundColor: _chooseToastColor(state),
    duration: duration,
    behavior: SnackBarBehavior.floating,
    margin: const EdgeInsets.all(16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  );

  snackbarKey.currentState?.showSnackBar(snackBar);
}

// Helper method for the current context
void showToastWithContext({
  required BuildContext context,
  required String msg,
  required ToastStates state,
  Duration duration = const Duration(seconds: 3),
}) {
  final SnackBar snackBar = SnackBar(
    content: Text(
      msg,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16.0,
      ),
    ),
    backgroundColor: _chooseToastColor(state),
    duration: duration,
    behavior: SnackBarBehavior.floating,
    margin: const EdgeInsets.all(16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  );

  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}

Color _chooseToastColor(ToastStates state) {
  switch (state) {
    case ToastStates.SUCCESS:
      return Colors.green;
    case ToastStates.ERROR:
      return Colors.red;
    case ToastStates.WARNING:
      return Colors.amber;
  }
}
