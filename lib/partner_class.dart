class Partner {
  int storeNumber;
  String name;
  String numbers;
  double hours;
  int tipAmount;

  Partner({
    this.storeNumber = -1,
    this.name = '',
    this.numbers = '',
    this.hours = -1.0,
    this.tipAmount = -1,
  });

  @override
  toString() {
    return 'Partner({Name: $name, Store Number: ${storeNumber != -1 ? storeNumber : ''}, Numbers: $numbers, Hours: ${hours != -1.0 ? hours : ''}, Tip Amount: ${tipAmount != -1 ? tipAmount : ''}})';
  }
}
