import 'package:flutter/material.dart';
import 'package:another_flushbar/flushbar.dart';

class ToastUtils {
  // The function now requires the BuildContext
  static void showCustomToast(
    BuildContext context,
    String message,
    Color backgroundColor,
  ) {
    Flushbar(
      message: message,
      backgroundColor: backgroundColor,
      duration: const Duration(seconds: 3), // How long it stays on screen
      // --- THIS IS WHERE WE CUSTOMIZE THE LOOK ---
      borderRadius: BorderRadius.circular(8.0), // Slightly rounded corners
      margin: const EdgeInsets.all(8), // Margin to make it float
      flushbarPosition: FlushbarPosition.BOTTOM, // Position at the bottom

      // You can also add icons, buttons, etc.
      // icon: Icon(Icons.info_outline, size: 28.0, color: Colors.white),
    ).show(context); // Show the flushbar
  }
}
