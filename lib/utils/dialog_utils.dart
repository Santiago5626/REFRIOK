import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

enum DialogType { success, error }

void showAnimatedDialog(BuildContext context, DialogType type, String message) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset(
              type == DialogType.success
                  ? 'assets/animations/success.json'
                  : 'assets/animations/error.json',
              width: 150,
              height: 150,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cerrar'),
          ),
        ],
      );
    },
  );
}
