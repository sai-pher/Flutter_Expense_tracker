import "package:expense_tracker/app/column_labels.dart";

// {'$columnItem': String item_name,
// '$columnItemCostSums': double cost_sum}

// ================= Constructors =================

class ItemCostSum {
  String itemName;
  double costSum;

  ItemCostSum(this.itemName, this.costSum);

  /// Constructor to create an `ItemCostSum` object from a map object.
  ///
  /// This constructor is to be used when getting full records from
  /// the SQLite database.
  ItemCostSum.fromMap(Map<String, dynamic> map) {
    itemName = map[columnItem];
    costSum = map[columnItemCostSums];
  }

  // ================= Helper methods =================
  /// Method to create a map from an ItemCostSum object.
  ///
  /// This method converts the given `ItemCostSum` object into
  /// a map object with the column labels to be used in the SQLite
  /// database.
  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      columnItem: itemName,
      columnItemCostSums: costSum,
    };

    return map;
  }

  // ================= Utility methods =================

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItemCostSum &&
          runtimeType == other.runtimeType &&
          itemName == other.itemName &&
          costSum == other.costSum;

  @override
  int get hashCode => itemName.hashCode ^ costSum.hashCode;

  @override
  String toString() {
    return 'ItemCostSum{itemName: $itemName, costSum: $costSum}';
  }
}
