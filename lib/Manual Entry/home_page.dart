import 'package:flutter/material.dart';
import 'keypad.dart';
import 'package:untitled/summary_page.dart';
import '../data_class.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  final TextEditingController textController =
      TextEditingController(text: '\$');
  final FocusNode _focus = FocusNode();

  final tipHelper = TipHelper();

  late Animation<double> animation;
  late AnimationController animationController;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChange);
    animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
  }

  void _onFocusChange() {
    if (_focus.hasFocus) {
      if (!tipHelper.inputIsValid(textController.text)) return;
      if (tipHelper.onSubmit(textController.text)) {
        // TODO: Fix summary page
        // Navigator.push(context,
        //     MaterialPageRoute(builder: (context) => SummaryPage()));
      }
      if ([1, 2].contains(tipHelper.step)) {
        double endValue = tipHelper.step == 1
            ? tipHelper.totalTips.toDouble()
            : tipHelper.totalHours;
        animation = Tween<double>(begin: 0, end: endValue).animate(
            CurvedAnimation(
                parent: animationController,
                curve: const Interval(0, 1, curve: Curves.decelerate)))
          ..addListener(() {
            setState(() {
              if (tipHelper.step == 1) {
                tipHelper.totalTips = animation.value.toInt();
                textController.text =
                    '\$${(endValue - animation.value).toInt()}';
              } else {
                tipHelper.totalHours = animation.value;
                textController.text =
                    (endValue - animation.value).toStringAsFixed(2);
              }
            });
          });
        animationController.reset();
        animationController.forward().then((value) {
          tipHelper.nextStep();
          textController.clear();
        });
      } else {
        setState(() {
          textController.text = '';
        });
      }
      _focus.unfocus();
    }
  }

  Widget totalTips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Total Tips: ',
              style: Theme.of(context).textTheme.headlineSmall),
          Text('\$${tipHelper.totalTips}',
              style: Theme.of(context).textTheme.headlineSmall),
        ],
      ),
    );
  }

  Widget totalHours() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Total Hours: ',
              style: Theme.of(context).textTheme.headlineSmall),
          Text('${tipHelper.totalHours.toStringAsFixed(2)} hrs',
              style: Theme.of(context).textTheme.headlineSmall),
        ],
      ),
    );
  }

  Widget hoursList() {
    return Container(
      padding: const EdgeInsets.only(top: 12),
      child: ListView.builder(
        reverse: true,
        shrinkWrap: true,
        itemCount: tipHelper.listHours.length,
        itemBuilder: (context, index) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  tipHelper.listHours.reversed
                      .toList()[index]
                      .toStringAsFixed(2),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                IconButton(
                  onPressed: () async {
                    String newValue = await showDialog(
                        context: context, builder: (context) => editPopup());
                    tipHelper.listHours[index] = double.parse(newValue);
                    setState(() {});
                  },
                  icon: const Icon(Icons.edit_outlined),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget textEntry() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              tipHelper.getStepString(),
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(color: Colors.black),
            ),
            IconButton(
              icon: const Icon(Icons.help_outline),
              onPressed: () => showDialog(
                  context: context, builder: (context) => helpPopup()),
            ),
          ],
        ),
        TextField(
          controller: textController,
          focusNode: _focus,
          textAlign: TextAlign.end,
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: tipHelper.inputIsValid(textController.text)
                    ? Colors.green
                    : Colors.black,
              ),
          decoration: const InputDecoration(
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.black),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.black),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 24),
          ),
          readOnly: true,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_focus.hasFocus) _focus.unfocus();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 1,
              child: totalTips(),
            ),
            Expanded(
              flex: 1,
              child: totalHours(),
            ),
            Expanded(
              flex: 5,
              child: hoursList(),
            ),
            Expanded(
              flex: 4,
              child: textEntry(),
            ),
            Expanded(
              flex: 10,
              child: Keypad(textController, () => {setState(() {})}),
            ),
          ],
        ), // This trailing comma makes auto-formatting nicer for build methods.
      ),
    );
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  editPopup() {
    TextEditingController controller = TextEditingController();
    return AlertDialog(
      // title: const Text('Edit Value'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Enter new value:'),
          TextField(
            controller: controller,
            decoration: const InputDecoration(
              border: UnderlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, controller.text),
          child: const Text('Submit'),
        )
      ],
    );
  }

  helpPopup() {
    return const AlertDialog(
      scrollable: true,
      title: Text('Need Help?'),
      content: Text(
        '''Step 1. Enter Total Usable Tips:
          
      This should be a whole dollar amount with no change, once you enter the dollar amount on the keypad the number should be green and you can click on the number to continue
      
Step 2. Enter Total Hours:
      
      This number will be at the bottom of your tip hourly report and is a number with two digits after the decimal. Once you enter the number with two digits after the decimal the number will turn green and you can click the number to continue.
      
Step 3. Enter Individual Hours:
      
      Enter each partners hours worked for the week. This number should also be two digits after the decimal and once the number is input it will be green and you can click the number to continue. Keep repeating this step until all partners hours are input, they will show in a list. Once every partners hours are input the calculator will automatically continue to the summary page which will break down each partners tip amount.
      ''',
        textAlign: TextAlign.start,
      ),
    );
  }
}
