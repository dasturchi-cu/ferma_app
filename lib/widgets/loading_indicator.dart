import 'package:flutter/material.dart';

class LoadingIndicator extends StatelessWidget {
  final double size;
  final double strokeWidth;
  final Color? color;

  const LoadingIndicator({
    Key? key,
    this.size = 24.0,
    this.strokeWidth = 2.0,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: strokeWidth,
          valueColor: AlwaysStoppedAnimation<Color>(
            color ?? Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }

  static Widget small() {
    return const LoadingIndicator(
      size: 16.0,
      strokeWidth: 1.5,
    );
  }

  static Widget medium() {
    return const LoadingIndicator(
      size: 32.0,
      strokeWidth: 2.5,
    );
  }

  static Widget large() {
    return const LoadingIndicator(
      size: 48.0,
      strokeWidth: 3.0,
    );
  }
}
