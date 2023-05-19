import 'package:flutter/material.dart';
import 'package:untitled/Home%20Page/home_page.dart';
import 'package:untitled/Scan%20Tips/scan.dart';

class ModeSelectionPage extends StatelessWidget {
  const ModeSelectionPage({Key? key}) : super(key: key);

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
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (context) => ScanPage())),
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
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (context) => MyHomePage())),
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
