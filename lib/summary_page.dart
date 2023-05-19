import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:untitled/data_class.dart';

import 'Scan Tips/scan.dart';

class SummaryPage extends StatefulWidget {
  const SummaryPage(
    this.tipHelper, {
    this.partners,
    this.totalTips,
        this.totalHours,
    Key? key,
  }) : super(key: key);

  final List<Partner>? partners;
  final int? totalTips;
  final double? totalHours;
  final TipHelper tipHelper;

  @override
  State<SummaryPage> createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> {
  late TipHelper tipHelper;
  late List<int> _tipAmounts;
  late double _tipRate;
  List<Partner>? partners;

  var logger = Logger(
    filter: null, // Use the default LogFilter (-> only log in debug mode)
    printer: PrettyPrinter(), // Use the PrettyPrinter to format and logger.d log
    output: null, // Use the default LogOutput (-> send everything to console)
  );

  @override
  Widget build(BuildContext context) {
    if (widget.partners != null) {
      partners = widget.partners;
      double counter = 0;
      for (Partner partner in partners!) {
        counter += partner.hours;
      }
      if (counter != widget.totalHours) {
        logger.d(counter, widget.totalHours);
        logger.d('Someone\'s hours are wrong');
      }
    }
    tipHelper = widget.tipHelper;

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
                          style: Theme.of(context).textTheme.headline5,
                        ),
                        Text(
                          '\$${partners != null ? widget.totalTips : tipHelper.totalTips}',
                          style: Theme.of(context).textTheme.headline5,
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
                          style: Theme.of(context).textTheme.headline5,
                        ),
                        Text(
                          '${partners != null ? widget.totalHours! : tipHelper.totalHours} hrs',
                          style: Theme.of(context).textTheme.headline5,
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
                          style: Theme.of(context).textTheme.headline5,
                        ),
                        Text(
                          '\$${_tipRate.toStringAsFixed(3)}',
                          style: Theme.of(context).textTheme.headline5,
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
                itemCount: partners != null ? partners!.length : tipHelper.listHours.length,
                itemBuilder: (context, index) {
                  final String hours = partners != null ? partners![index].hours.toStringAsFixed(2) : tipHelper.listHours[index].toStringAsFixed(2);
                  final String payout = partners != null ? partners![index].tipAmount.toStringAsFixed(2) :  _tipAmounts[index].toStringAsFixed(2);

                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          hours,
                          style: Theme.of(context).textTheme.headline5,
                        ),
                        Text(
                          '\$$payout',
                          style: Theme.of(context).textTheme.headline5,
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
    if (partners != null) {
      double tipRate = widget.totalTips! / widget.totalHours!;
      int totalPayout = 0;

      while (totalPayout != widget.totalTips!) {
        totalPayout = 0;
        for (Partner partner in partners!) {
          partner.tipAmount = (partner.hours * tipRate).round();
          totalPayout += partner.tipAmount;
        }
        if (totalPayout < widget.totalTips!) {
          tipRate += 0.001;
        } else if (totalPayout > widget.totalTips!) {
          tipRate -= 0.001;
        }
      }
      _tipRate = tipRate;

      return;
    }
    double tipRate = tipHelper.totalTips / tipHelper.totalHours;

    List<int> tipAmounts = [];
    int totalPayout = 0;

    while (totalPayout != tipHelper.totalTips) {
      tipAmounts.clear();
      for (final hours in tipHelper.listHours) {
        tipAmounts.add((hours * tipRate).round());
      }
      totalPayout = tipAmounts.reduce((a, b) => a + b);
      if (totalPayout < tipHelper.totalTips) {
        tipRate += 0.001;
      } else if (totalPayout > tipHelper.totalTips) {
        tipRate -= 0.001;
      }
    }

    _tipAmounts = tipAmounts;
    _tipRate = tipRate;
  }
}
