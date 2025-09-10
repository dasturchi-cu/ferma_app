import 'package:flutter/material.dart';

class ErrorDialog extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final String? retryText;

  const ErrorDialog({
    Key? key,
    required this.message,
    this.onRetry,
    this.retryText = 'Retry',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red),
          SizedBox(width: 8),
          Text('Error'),
        ],
      ),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        if (onRetry != null)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onRetry!();
            },
            child: Text(retryText!),
          ),
      ],
    );
  }

  static void show(BuildContext context, String message, {VoidCallback? onRetry}) {
    showDialog(
      context: context,
      builder: (context) => ErrorDialog(
        message: message,
        onRetry: onRetry,
      ),
    );
  }
}
