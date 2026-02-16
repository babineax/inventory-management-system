import 'package:flutter/material.dart';

class LoadingWidget extends StatelessWidget {
  final String message;

  const LoadingWidget({super.key, this.message = 'Loading...'});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          if (message.isNotEmpty)
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white70
                    : Theme.of(context).primaryColor,
              ),
            ),
        ],
      ),
    );
  }
}
