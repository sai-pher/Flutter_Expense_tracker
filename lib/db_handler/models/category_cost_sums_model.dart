import "package:expense_tracker/app/column_labels.dart";

// {'$columnCategory': String category_name,
// '$columnCategoryCostSums': double cost_sum}

// ================= Constructors =================

class CategoryCostSum {
  String categoryName;
  double costSum;

  CategoryCostSum(this.categoryName, this.costSum);

  /// Constructor to create an `CategoryCostSum` object from a map object.
  ///
  /// This constructor is to be used when getting full records from
  /// the SQLite database.
  CategoryCostSum.fromMap(Map<String, dynamic> map) {
    categoryName = map[columnCategory];
    costSum = map[columnCategoryCostSums];
  }

  // ================= Helper methods =================
  /// Method to create a map from an CategoryCostSum object.
  ///
  /// This method converts the given `CategoryCostSum` object into
  /// a map object with the column labels to be used in the SQLite
  /// database.
  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      columnCategory: categoryName,
      columnCategoryCostSums: costSum,
    };

    return map;
  }

  // ================= Utility methods =================

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryCostSum &&
          runtimeType == other.runtimeType &&
          categoryName == other.categoryName &&
          costSum == other.costSum;

  @override
  int get hashCode => categoryName.hashCode ^ costSum.hashCode;

  @override
  String toString() {
    return 'CategoryCostSum{categoryName: $categoryName, costSum: $costSum}';
  }
}
