import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:untitled/partner_class.dart';

class SummaryPage extends StatefulWidget {
  static const routeName = '/summary';

  const SummaryPage({Key? key}) : super(key: key);

  @override
  State<SummaryPage> createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> {
  late double _tipRate;
  late List<Partner> partners;
  late double totalHours;
  late int totalTips;

  var logger = Logger();

  @override
  void initState() {
    final SummaryArguments args =
        ModalRoute.of(context)!.settings.arguments as SummaryArguments;
    partners = args.partners;
    totalTips = args.totalTips;
    totalHours = args.totalHours;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    partners = partners;
    double counter = 0;
    for (Partner partner in partners) {
      counter += partner.hours;
    }
    if (counter != totalHours) {
      logger.d(counter, totalHours);
      logger.d('Someone\'s hours are wrong');
    }

    _calculateTips();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Flexible(
              flex: 1,
              child: Column(
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Tips:',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        Text(
                          '\$$totalTips',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Hours:',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        Text(
                          '$totalHours hrs',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tip Rate:',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        Text(
                          '\$${_tipRate.toStringAsFixed(3)}',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              flex: 5,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: partners.length,
                itemBuilder: (context, index) {
                  final String hours = partners[index].hours.toStringAsFixed(2);
                  final String payout = partners[index].tipAmount.toString();

                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          hours,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        Text(
                          '\$$payout',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _calculateTips() {
    double tipRate = totalTips / totalHours;
    int totalPayout = 0;

    while (totalPayout != totalTips) {
      totalPayout = 0;
      for (Partner partner in partners) {
        partner.tipAmount = (partner.hours * tipRate).round();
        totalPayout += partner.tipAmount;
      }
      if (totalPayout < totalTips) {
        tipRate += 0.001;
      } else if (totalPayout > totalTips) {
        tipRate -= 0.001;
      }
    }
    _tipRate = tipRate;

    return;
  }
}

class SummaryArguments {
  final List<Partner> partners;
  final int totalTips;
  final double totalHours;

  SummaryArguments(this.partners, this.totalTips, this.totalHours);
}
