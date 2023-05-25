import 'package:flutter/material.dart';

class Keypad extends StatelessWidget {
  const Keypad(this.textController, this.update, {Key? key}) : super(key: key);

  final TextEditingController textController;
  final Function update;

  @override
  Widget build(BuildContext context) {
    String buttons = '123456789.0';

    return Column(
      children: List.generate(4, (y) {
        return Expanded(
          child: Row(
            children: List.generate(3, (x) {
              final index = y * 3 + x;
              return Expanded(
                child: InkWell(
                  onTap: () => _handlePressed(index),
                  child: Container(
                      alignment: Alignment.center,
                      child: index == 11
                          ? const Icon(Icons.backspace_outlined)
                          : Text(
                        buttons[index],
                        style: Theme.of(context).textTheme.headlineSmall,
                      )),
                ),
              );
            },)
      ),
        );
      }),
    );
  }

  _handlePressed(index) {
    String buttons = '123456789.0';
    if (index == 11) {
      if (textController.text == '\$' || textController.text == '') {
        return;
      }
      textController.text =
          textController.text.substring(0, textController.text.length - 1);
    } else {
      textController.text += buttons[index];
    }
    update();
  }
}
