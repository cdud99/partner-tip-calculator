class Partner {
  int storeNumber = -1;
  String name = '';
  String numbers = '';
  double hours = -1.0;
  int tipAmount = -1;

  Partner();

  @override
  toString() {
    return 'Partner({Name: $name, Store Number: ${storeNumber != -1 ? storeNumber : ''}, Numbers: $numbers, Hours: ${hours != -1.0 ? hours : ''}, Tip Amount: ${tipAmount != -1 ? tipAmount : ''}})';
  }
}