import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'timer_provider.dart';

class TimerPage extends StatelessWidget {
  const TimerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('타이머')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Consumer<TimerProvider>(
              builder: (context, timerProvider, _) {
                return Text(
                  timerProvider.formattedTime,
                  style: const TextStyle(
                    fontSize: 60,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
            const SizedBox(height: 40),
            Consumer<TimerProvider>(
              builder: (context, timerProvider, _) {
                return IconButton(
                  icon: Icon(
                    timerProvider.isRunning ? Icons.pause : Icons.play_arrow,
                    size: 48,
                  ),
                  onPressed: () {
                    if (timerProvider.isRunning) {
                      timerProvider.pause();
                    } else {
                      timerProvider.start();
                    }
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}