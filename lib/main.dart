import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:untitled/mode_selection.dart';
import 'package:untitled/summary_page.dart';
import 'package:untitled/Scan%20Tips/scan_page.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: GoogleFonts.openSansTextTheme(Theme.of(context).textTheme),
        appBarTheme: const AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarIconBrightness: Brightness.light,
          ),
        ),
      ),
      routes: {
        '/home': (context) => const ModeSelectionPage(),
        '/scan': (context) => const ScanPage(),
        SummaryPage.routeName: (context) => const SummaryPage(),
      },
      debugShowCheckedModeBanner: false,
      initialRoute: '/home',
    );
  }
}
