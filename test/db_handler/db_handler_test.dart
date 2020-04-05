import 'package:expense_tracker/db_handler/db_handler.dart';
import 'package:test/test.dart';

void main() {
  group("DB creator and destoryer", () {
    DBHandler db = DBHandler.handler;

    test("Database should be created", () {
      expect(true, db != null);
    });
  });
}
