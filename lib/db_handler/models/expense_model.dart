import "package:expense_tracker/app/column_labels.dart";

// ================= Expense class =================
/// An object modeling a given user expense.
class Expense {
  int _id;
  String _item;
  String _category;
  double _cost;
  DateTime _date;

  // ================= Constructors =================
  // TODO: remember to take date as a DateTime.now()
  // Constructor
  Expense(this._item, this._category, this._cost, this._date);

  /// Constructor to create an `Expense` object from a map object.
  ///
  /// This constructor is to be used when getting full records from
  /// the SQLite database.
  Expense.fromMap(Map<String, dynamic> map) {
    _id = map[columnID];
    _item = map[columnItem];
    _category = map[columnCategory];
    _cost = map[columnCost];
    dateMilli = map[columnDate];
  }

// ================= Helper methods =================
  /// Method to create a map from an expense object.
  ///
  /// This method converts the given `Expense` object into
  /// a map object with the column labels to be used in the SQLite
  /// database.
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

// ================= Getters and setters =================

  // ignore: unnecessary_getters_setters
  DateTime get date => _date;

  int get dateMilli => _date.millisecondsSinceEpoch;

  // ignore: unnecessary_getters_setters
  set date(DateTime value) {
    _date = value;
  }

  /// Sets `_date` value to DateTime object from [milliseconds] since epoch.
  set dateMilli(int milliseconds) {
    _date = DateTime.fromMillisecondsSinceEpoch(milliseconds);
  }

  double get cost => _cost;

  String get category => _category;

  String get item => _item;

  int get id => _id;

  // ================= Utility methods =================
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
