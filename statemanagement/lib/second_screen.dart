import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'counter_provider.dart';

class SecondScreen extends StatelessWidget {
  const SecondScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CounterProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Second Screen"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Counter value in Second Screen:",
            ),
            Text(
              "${provider.count}",
              style: const TextStyle(fontSize: 35),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                provider.increment();
              },
              child: const Text("Increment"),
            ),
          ],
        ),
      ),
    );
  }
}
