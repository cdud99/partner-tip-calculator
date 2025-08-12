import 'package:flutter/material.dart';
import 'package:untitled/partner_class.dart';
import 'package:untitled/summary_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        // backgroundColor: Theme.of(context).colorScheme.primary,
        // floatingActionButton:
        //     FloatingActionButton(onPressed: () => print('Tapped')),
        body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tip Distribution Calculator',
              style: Theme.of(context)
                  .textTheme
                  .displayMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            Image(
              image: AssetImage('assets/images/scan_image.png'),
              height: MediaQuery.of(context).size.height / 3,
            ),
            Column(
              children: [
                Text(
                  'Scan your tip report',
                  style: Theme.of(context)
                      .textTheme
                      .displaySmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16.0),
                Text(
                  'Use your camera to scan your tip report and calculate tips',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton(
                  onPressed: () => Navigator.pushNamed(context, '/scan'),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24.0),
                    ),
                    padding: EdgeInsets.all(16.0),
                  ),
                  child: Text(
                    'Scan Report',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/manualEntry'),
                  // onPressed: () {
                  //   List<Partner> partners = List.filled(
                  //       10,
                  //       Partner(
                  //         hours: 10.0,
                  //         name: 'Connor Dudley',
                  //       ));
                  //   double totalHours = 100.00;
                  //   Navigator.pushNamedAndRemoveUntil(
                  //     context,
                  //     SummaryPage.routeName,
                  //     ModalRoute.withName('/home'),
                  //     arguments: SummaryArguments(partners, 318, totalHours),
                  //   );
                  // },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.only(top: 16.0),
                  ),
                  child: Text(
                    'Enter Manually',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary),
                  ),
                ),
              ],
            ),
            // Padding(
            //   padding: const EdgeInsets.symmetric(horizontal: 16.0),
            //   child: ElevatedButton(
            //     style: ButtonStyle(
            //       backgroundColor: WidgetStateColor.resolveWith(
            //           (states) => Colors.white),
            //       elevation: WidgetStateProperty.resolveWith((states) => 5),
            //     ),
            //     onPressed: () => Navigator.pushNamed(context, '/scan'),
            //     child: Padding(
            //       padding: const EdgeInsets.symmetric(vertical: 16.0),
            //       child: Text(
            //         'Auto Scan (New)',
            //         style: Theme.of(context).textTheme.headlineMedium,
            //       ),
            //     ),
            //   ),
            // ),
            // Padding(
            //   padding: const EdgeInsets.symmetric(horizontal: 16.0),
            //   child: ElevatedButton(
            //     style: ButtonStyle(
            //       backgroundColor: WidgetStateColor.resolveWith(
            //           (states) => Colors.white),
            //       elevation: WidgetStateProperty.resolveWith((states) => 5),
            //     ),
            //     onPressed: () =>
            //         Navigator.pushNamed(context, '/manualEntry'),
            //     child: Padding(
            //       padding: const EdgeInsets.symmetric(vertical: 16.0),
            //       child: Text(
            //         'Manual Entry',
            //         style: Theme.of(context).textTheme.headlineMedium,
            //       ),
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    ));
  }
}
