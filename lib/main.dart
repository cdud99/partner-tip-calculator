import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:untitled/Manual%20Entry/manual_entry.dart';
import 'package:untitled/Scan%20Tips/test_page.dart';
import 'package:untitled/home_page.dart';
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
        colorScheme: ColorScheme.light(
          primary: HexColor.fromHex('339974'),
        ),
      ),
      routes: {
        '/home': (context) => const HomePage(),
        '/scan': (context) => const ScanPage(),
        '/test': (context) => const TestPage(),
        '/manualEntry': (context) => const ManualEntryPage(),
        SummaryPage.routeName: (context) => const SummaryPage(),
      },
      debugShowCheckedModeBanner: false,
      initialRoute: '/home',
    );
  }
}

extension HexColor on Color {
  /// Converts a hex string like '#2196F3' or '2196F3' to a Color.
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    hexString = hexString.replaceFirst('#', '');
    buffer.write(hexString);
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
