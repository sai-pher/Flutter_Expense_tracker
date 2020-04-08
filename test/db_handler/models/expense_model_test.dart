import "package:expense_tracker/app/column_labels.dart";
import 'package:expense_tracker/db_handler/models/expense_model.dart';
import 'package:test/test.dart';

void main() {
  group("Expense object property verification", () {
    var now = DateTime.now();

    var exp1 = Expense("item", "category", 10, now);

    test("Expense object should be created", () {});

    test("Expense object should have item name 'item'", () {
      expect("item", exp1.item);
    });

    test("Expense object should have category name 'category'", () {
      expect("category", exp1.category);
    });

    test("Expense object should have cost price 10", () {
      expect(10, exp1.cost);
    });

    test("Expense object should have date time 'now'", () {
      expect(now, exp1.date);
    });

    test("Expense object should have date milliseconds 'now.milli'", () {
      expect(now.millisecondsSinceEpoch, exp1.dateMilli);
    });
  });

  group("Expense object dateTime verification", () {
    var now = DateTime.now();

    for (num i = 0; i < 9000000000; i += 1) {}

    var later = DateTime.now();

    var exp1 = Expense("item 1", "category 1", 10, now);
    var exp2 = Expense("item 2", "category 2", 20, later);

    test("Verify now is less than later", () {
      expect(true, now.millisecondsSinceEpoch < later.millisecondsSinceEpoch);
    });

    test("Verify exp1 date is less than exp2 date", () {
      expect(true, exp1.dateMilli < exp2.dateMilli);
    });

    test("Verify expense object datetime can be set", () {
      expect(now.millisecondsSinceEpoch, exp1.dateMilli);

      exp1.dateMilli = later.millisecondsSinceEpoch;

      expect(later.millisecondsSinceEpoch, exp1.dateMilli);
    });
  });

  group("Test map methods", () {
    DateTime now = DateTime.now();

    Map<String, dynamic> map = <String, dynamic>{
      columnID: 1,
      columnItem: "item 1",
      columnCategory: "category 1",
      columnCost: 10.0,
      columnDate: now.millisecondsSinceEpoch
    };

    Expense exp1 = Expense.fromMap(map);
    Map<String, dynamic> map1 = exp1.toMap();
    var exp2 = Expense.fromMap(map1);

    test("Verify Expense object created from map", () {
      expect(map[columnID], exp1.id);
      expect(map[columnItem], exp1.item);
      expect(map[columnCategory], exp1.category);
      expect(map[columnCost], exp1.cost);
      expect(map[columnDate], exp1.dateMilli);
    });

    test("Verify datetime is accurate", () {
      expect(now.millisecondsSinceEpoch, exp1.dateMilli);
      expect(true, exp1.date != null);
      expect(now.day, exp1.date.day);
      expect(now.month, exp1.date.month);
      expect(now.year, exp1.date.year);
    });

    test("Verify toMap() method", () {
      expect(exp1.id, map1[columnID]);
      expect(exp1.item, map1[columnItem]);
      expect(exp1.category, map1[columnCategory]);
      expect(exp1.cost, map1[columnCost]);
      expect(exp1.dateMilli, map1[columnDate]);
    });

    test("Verify expense converted back and forth is the same", () {
      expect(exp1, exp2);
    });
  });
}
