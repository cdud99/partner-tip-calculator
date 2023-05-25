import 'package:flutter/material.dart';

import 'Manual Entry/manual_entry.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.greenAccent,
        body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: ElevatedButton(
            style: ButtonStyle(
              backgroundColor: MaterialStateColor.resolveWith((states) => Colors.white),
              elevation: MaterialStateProperty.resolveWith((states) => 5),
            ),
            onPressed: () => Navigator.pushNamed(context, '/scan'),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                'Auto Scan (New)',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: ElevatedButton(
            style: ButtonStyle(
              backgroundColor: MaterialStateColor.resolveWith((states) => Colors.white),
              elevation: MaterialStateProperty.resolveWith((states) => 5),
            ),
            onPressed: () => Navigator.pushNamed(
                context, '/manualEntry'),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                'Manual Entry',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          ),
        ),
      ],
    ));
  }
}
