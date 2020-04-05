final String tableExpenses = 'expenses';
final String columnID = '_id';
final String columnItem = 'item';
final String columnCategory = 'category';
final String columnCost = 'cost';
final String columnDate = 'date';

class Expense {
  int _id;
  String _item;
  String _category; //TODO: make enum at some point
  double _cost;
  DateTime _date; //TODO: use [date.millisecondsSinceEpoch] to store in db and [DateTime.fromMillisecondsSinceEpoch] to convert back

  // TODO: remember to take date as a DateTime.now()
  // Constructor
  Expense(this._item, this._category, this._cost, this._date);


  //constructor to create expense from map object
  Expense.fromMap(Map<String, dynamic> map) {
    _id = map[columnID];
    _item = map[columnItem];
    _category = map[columnCategory];
    _cost = map[columnCost];
    dateMilli = map[columnDate];
  }

  // Method to create map from expense object
  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      columnItem: item,
      columnCategory: category,
      columnCost: cost.toDouble(),
      columnDate: dateMilli
    };
    if (id != null) {
      map[columnID] = id;
    }

    return map;
  }

  // Getters and setters
  // ignore: unnecessary_getters_setters
  DateTime get date => _date;

  int get dateMilli => _date.millisecondsSinceEpoch;

  // ignore: unnecessary_getters_setters
  set date(DateTime value) {
    _date = value;
  }

  set dateMilli(int milliseconds) {
    _date = DateTime.fromMillisecondsSinceEpoch(milliseconds);
  }

  double get cost => _cost;

  String get category => _category;

  String get item => _item;

  int get id => _id;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Expense &&
              runtimeType == other.runtimeType &&
              _item == other._item &&
              _category == other._category &&
              _cost == other._cost &&
              _date == other._date;

  @override
  int get hashCode =>
      _item.hashCode ^
      _category.hashCode ^
      _cost.hashCode ^
      _date.hashCode;




}
