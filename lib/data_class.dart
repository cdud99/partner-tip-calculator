class TipHelper {
  TipHelper();

  int step = 1;

  int totalTips = 0;
  double totalHours = 0;
  final List<double> listHours = [];


  bool inputIsValid(String rawInput) {
    if (rawInput == '\$' || rawInput == '') return false;
    final String input = rawInput.substring(rawInput[0] == '\$' ? 1 : 0);
    final String idealNumber = double.parse(input).toStringAsFixed(step == 1 ? 0 : 2);
    final bool valid = input == idealNumber;
    if (valid && step == 3) {
      if (listHours.isEmpty) return valid;
      final double sumHours = roundDouble(listHours.reduce((a, b) => a + b), 2);
      if (sumHours + double.parse(input) > totalHours) return false;
    }

    return valid;
  }


  bool onSubmit(String input) {
    if (inputIsValid(input)) {
      switch (step) {
        case 1:
          totalTips = int.parse(input.substring(1));
          break;
        case 2:
          totalHours = double.parse(input);
          break;
        case 3:
          listHours.add(double.parse(input));
          final double sum = roundDouble(listHours.reduce((a, b) => a + b), 2);
          print('Sum: $sum');
          if (sum == totalHours) return true;
          break;
      }
    }
    return false;
  }


  double getValue() {
    if (step == 1) {
      return totalTips.toDouble();
    }
    return totalHours;
  }


  String getStepString() {
    if (step == 1) {
      return 'Enter Total Usable Tips:';
    } else if (step == 2) {
      return 'Enter Total Hours:';
    } else {
      return 'Enter Individual Hours:';
    }
  }


  double roundDouble(double value, int places){
    final double newValue = double.parse(value.toStringAsFixed(places));
    return newValue;
  }

  nextStep() {
    step += 1;
  }
}
