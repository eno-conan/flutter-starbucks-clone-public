import 'package:flutter/material.dart';

/// エラーダイアログを表示
void showErrorDialog(BuildContext context, String message) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('エラー'),
      content: Text(message),
      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK'))],
    ),
  );
}
