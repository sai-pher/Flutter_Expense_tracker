import 'dart:io';

import "package:expense_tracker/app/column_labels.dart";
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/expense_model.dart';

/// A singleton class to manage connections to the SQLite database.
///
/// This class provides a static object [handler] that grants access to
/// helper methods with a single connection to the global database.
///
/// Exceptions are not currently thrown or handled by methods of this class.
class DBHandler {
  static final String _databaseName = "ExpenseTracker.db";
  static final int _version = 1;

  // ================= Singleton instance of database handler =================
  DBHandler._privateConstructor();

  /// A static object that ensure a single connection to the SQLite database.
  static final DBHandler handler = DBHandler._privateConstructor();

  // Force single connection to database
  static Database _database;

  Future<Database> get database async {
    if (_database == null) {
      _database = await _initDatabase();
    } else {
      return _database;
    }

    return _database;
  }

  /// Method to open connection to database.
  _initDatabase() async {
    // get directory for given platform.
    String databasePath = await getDatabasesPath();
    String path = join(databasePath, _databaseName);

    // Make sure the directory exists
    try {
      await Directory(databasePath).create(recursive: true);
    } catch (_) {}

    // open connection
    return await openDatabase(path, version: _version, onCreate: _onCreate);
  }

  /// Method to create database schema
  Future _onCreate(Database db, int version) async {
    print("Creating DB $_databaseName with table $tableExpenses...");
    await db.execute('''
    CREATE TABLE IF NOT EXISTS $tableExpenses (
      $columnID INTEGER PRIMARY KEY AUTOINCREMENT,
      $columnItem TEXT NOT NULL,
      $columnCategory TEXT NOT NULL,
      $columnCost REAL NOT NULL,
      $columnDate INT NOT NULL
    )
    ''');
    print("DB Creation successful!");
  }

// ================= Helper methods =================

// destroy
  /// A helper method to delete the SQLite database.
  ///
  /// This method is for testing purposes only and should not be used
  /// trivially.
  _destroyDB() async {
    String directoryPath = await getDatabasesPath();
    String path = join(directoryPath, _databaseName);
    deleteDatabase(path);
    _database = null;
  }

  // from mapped list
  /// A helper method to convert maps in a list [mapsList] into Expense objects.
  ///
  /// Maps in [mapsList] must be in the form
  /// `{columnID, columnItem, columnCategory, columnCost, columnDate}`
  /// to maintain `Expense` object structure.
  ///
  /// This method does NOT provide error checking for this requirement (fix later).
  ///
  /// This method returns
  /// a list of successfully mapped `Expense` objects as [mappedList]
  fromMappedList(List<Map<String, dynamic>> mapsList) {
    List mappedList = [];
    if (mapsList.length == 0) {
      var now = DateTime.now();
      var exp1 = Expense("None", "category", 0, now);
      mappedList.add(exp1);
    } else {
      mapsList.forEach((map) => mappedList.add(Expense.fromMap(map)));
    }
    return mappedList;
  }

// insert
  /// A method to add an `Expense` object [expense] to the SQLite database.
  ///
  /// This method returns the [id] of a given record that has been successfully added.
  Future<int> insert(Expense expense) async {
    Database db = await database;
    int id = await db.insert(tableExpenses, expense.toMap());
    return id;
  }

// getAll
  /// A method to retrieve all `Expense` objects from the SQLite database.
  ///
  /// This method returns
  /// a list of successfully mapped `Expense` objects.
  Future<List<Expense>> getAll() async {
    // Query
    final db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      tableExpenses,
      columns: [columnID, columnItem, columnCategory, columnCost, columnDate],
    );

//    print("Raw maps: ${maps.runtimeType} \n$maps");

    List<Expense> mappedList = maps.isNotEmpty
        ? maps.map<Expense>((map) => Expense.fromMap(map)).toList()
        : [Expense("None", "category", 0, DateTime.now())];

//    print("Mapped list: ${mappedList.runtimeType} \n$mappedList");

    return mappedList;

//    return fromMappedList(maps);
  }

// getExpensesBetweenDates
  /// A method to retrieve `Expense` objects
  /// between two dates [lowerDateMilli] and [upperDateMilli].
  ///
  /// This method returns
  /// a list of successfully mapped `Expense` objects.
  Future<List<Expense>> getExpensesBetweenDates(int lowerDateMilli,
      int upperDateMilli) async {
    // Query
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(tableExpenses,
        columns: [columnID, columnItem, columnCategory, columnCost, columnDate],
        where: '$columnDate BETWEEN ? AND ?',
        whereArgs: [lowerDateMilli, upperDateMilli],
        orderBy: '$columnDate ASC');

    return await fromMappedList(maps);
  }

// getTopNum
  /// A method to retrieve the top n [limit] `Expense` objects by cost.
  ///
  /// This method returns
  /// a list of n [limit] successfully mapped `Expense` objects.
  Future<List<Expense>> getTopNumCosts(int limit) async {
    // Query
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(tableExpenses,
        columns: [columnID, columnItem, columnCategory, columnCost, columnDate],
        orderBy: '$columnCost DESC',
        limit: limit);

    return await fromMappedList(maps);
  }

  // getCategoryCostSums
  /// A method to retrieve the sum cost of all categories from the SQLite database.
  ///
  /// This method returns
  /// a list of maps in the form
  /// `{'$columnCategory': String category_name, '$columnCategoryCostSums': double cost_sum}`.
  getCategoryCostSums() async {
    Database db = await database;

    String query =
        'SELECT $columnCategory, SUM($columnCost) $columnCategoryCostSums '
        'FROM $tableExpenses GROUP BY $columnCategory';

    // {'$columnCategory': String category_name, '$columnCategoryCostSums': double cost_sum}
    List<Map<String, dynamic>> maps = await db.rawQuery(query);

    return maps;
  }

  // getItemCostSums
  /// A method to retrieve the sum cost of each item from the SQLite database.
  ///
  /// This method returns
  /// a list of maps in the form
  /// `{'$columnItem': String item_name, '$columnItemCostSums': double cost_sum}`.
  getItemCostSums() async {
    Database db = await database;

    String query = 'SELECT $columnItem, SUM($columnCost) $columnItemCostSums '
        'FROM $tableExpenses GROUP BY $columnItem';

    // {'$columnItem': String item_name, '$columnItemCostSums': double cost_sum}
    List<Map<String, dynamic>> maps = await db.rawQuery(query);

    return maps;
  }

  // getTotalCostSince
  /// A method to retrieve the sum cost of all items since a given date.
  ///
  /// This method returns
  /// a list of maps in the form
  /// `{'$columnItem': String item_name, '$columnItemCostSums': double cost_sum}`.
  getTotalCostSince(int sinceDateMilli) async {
    int nowMilli = DateTime
        .now()
        .millisecondsSinceEpoch;
    Database db = await database;

    String query = 'SELECT SUM($columnCost) $columnTotalItemCostSumSince '
        'FROM $tableExpenses WHERE $columnDate BETWEEN $sinceDateMilli AND $nowMilli';

    // {'columnTotalItemCostSumSince': double cost_sum}
    List<Map<String, int>> maps = await db.rawQuery(query);

    return maps;
  }

  // getTotalCostSince
  /// A method to retrieve the sum cost of all items between two given dates
  /// [lowerDateMilli] and [upperDateMilli].
  ///
  /// This method returns
  /// a list of maps in the form
  /// `{'$columnTotalItemCostSumBetween': double cost_sum}`.
  getTotalCostBetween(int lowerDateMilli, int upperDateMilli) async {
    Database db = await database;

    String query = 'SELECT SUM($columnCost) $columnTotalItemCostSumBetween '
        'FROM $tableExpenses WHERE $columnDate BETWEEN $lowerDateMilli AND $upperDateMilli';

    // {'$columnTotalItemCostSumBetween': double cost_sum}
    List<Map<String, int>> maps = await db.rawQuery(query);

    return maps;
  }
}
