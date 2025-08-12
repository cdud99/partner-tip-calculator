import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:untitled/partner_class.dart';

class SummaryPage extends StatefulWidget {
  static const routeName = '/summary';

  const SummaryPage({super.key});

  @override
  State<SummaryPage> createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> {
  final TextEditingController controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late double _tipRate;
  late List<Partner> partners;
  late double totalHours;
  int totalTips = 0;
  bool partnersChecked = false;

  var logger = Logger();

  @override
  void initState() {
    controller.text = '$totalTips';
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: controller.text.length,
        );
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final SummaryArguments args =
        ModalRoute.of(context)!.settings.arguments as SummaryArguments;
    partners = args.partners;
    totalHours = args.totalHours;
    double counter = 0;
    if (!partnersChecked) {
      List<Partner> remove = [];
      for (var i = 0; i < partners.length; i++) {
        Partner partner = partners[i];
        if (partner.hours <= 0) {
          remove.add(partner);
        }
      }
      for (Partner partner in remove) {
        partners.remove(partner);
      }
      partnersChecked = true;
    }
    for (Partner partner in partners) {
      counter += partner.hours;
    }
    if (counter != totalHours) {
      logger.d('$counter $totalHours');
      logger.d('Someone\'s hours are wrong');
    }

    _calculateTips();

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 16.0,
              horizontal: 32.0,
            ),
            child: Column(
              children: [
                Text(
                  'Tip Distribution',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                SizedBox(height: 32.0),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Total Tips:',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: controller,
                        textAlign: TextAlign.right,
                        style: Theme.of(context).textTheme.headlineSmall,
                        keyboardType: TextInputType.number,
                        focusNode: _focusNode,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.only(bottom: 4.0),
                          prefix: Text(
                            '\$',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                        onChanged: (String value) {
                          int? number = int.tryParse(value);
                          if (number == null) return;
                          totalTips = number;
                          setState(() {});
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.0),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Total Hours Worked:',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    Text(
                      '$totalHours hrs',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
                SizedBox(height: 8.0),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Tip Rate:',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    Text(
                      '\$${_tipRate.toStringAsFixed(3)}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
                SizedBox(height: 24.0),
                Row(
                  children: [
                    Expanded(
                        child: Text(
                      'Employee',
                      style: Theme.of(context).textTheme.headlineSmall,
                    )),
                    Text(
                      'Hours   ',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(
                      'Tips',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
                SizedBox(height: 8.0),
                Divider(
                  color: Theme.of(context).colorScheme.primary,
                ),
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: partners.length,
                    itemBuilder: (context, index) {
                      final String name = partners[index].name;
                      final String hours =
                          partners[index].hours.toStringAsFixed(2);
                      final String payout =
                          partners[index].tipAmount.toString();

                      List<Widget> children = [
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: name == null ? 0 : 24.0),
                          child: Text(
                            hours,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                        Text(
                          payout.length == 1 ? '  \$$payout' : '\$$payout',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ];

                      if (name != '') {
                        children.insert(
                          0,
                          Expanded(
                            child: Text(
                              name.toTitleCase(),
                              style: Theme.of(context).textTheme.headlineSmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        );
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: children,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _calculateTips() {
    double tipRate = totalTips / totalHours;
    int totalPayout = -1;

    bool? checkedLower;
    while (totalPayout != totalTips) {
      totalPayout = 0;
      for (Partner partner in partners) {
        partner.tipAmount = (partner.hours * tipRate).round();
        totalPayout += partner.tipAmount;
      }
      if (totalPayout < totalTips) {
        if (checkedLower == null) {
          checkedLower = true;
        } else if (checkedLower == false) {
          break;
        }
        tipRate += 0.001;
      } else if (totalPayout > totalTips) {
        checkedLower = false;
        tipRate -= 0.001;
      }
    }
    for (Partner partner in partners) {
      print(partner.tipAmount);
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

extension StringCasingExtension on String {
  String toTitleCase() {
    if (isEmpty) {
      return this;
    }
    // Split the string into words based on spaces
    List<String> words = split(' ');
    // Capitalize the first letter of each word and join the rest
    for (int i = 0; i < words.length; i++) {
      if (words[i].isNotEmpty) {
        words[i] =
            '${words[i][0].toUpperCase()}${words[i].substring(1).toLowerCase()}';
      }
    }
    // Join the words back together with spaces
    return words.join(' ');
  }
}
