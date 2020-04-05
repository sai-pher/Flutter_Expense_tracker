import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'models/expense_model.dart';

// TODO: Write Doc comment

class DBHandler {
  static final String _databaseName = "ExpenseTracker.db";
  static final int _version = 1;

  // ================= Singleton instance of database handler =================
  DBHandler._privateConstructor();

  static final DBHandler handler = DBHandler._privateConstructor();

  // Force single connection to database
  static Database _database;

  Future<Database> get database async {
    if (_database == null) {
      _database = _initDatabase();
    } else {
      return _database;
    }

    return _database;
  }

  // Method to open connection to database.
  _initDatabase() async {
    // get directory for given platform.
    String directoryPath = await getDatabasesPath();
    String path = join(directoryPath, _databaseName);

    // open connection
    return await openDatabase(path, version: _version, onCreate: _onCreate);
  }

  // Method to create database schema
  Future _onCreate(Database db, int version) async {
    await db.execute('''
    CREATE TABLE $tableExpenses (
      $columnID INTEGER PRIMARY KEY,
      $columnItem TEXT NOT NULL,
      $columnCategory TEXT NOT NULL,
      $columnCost REAL NOT NULL,
      $columnDate INT NOT NULL,
    )
    ''');
  }

// ================= Helper methods =================

// destroy
  destroyDB() async {
    String directoryPath = await getDatabasesPath();
    String path = join(directoryPath, _databaseName);
    deleteDatabase(path);
    _database = null;
  }

  // from mapped list
  fromMappedList(List<Map<String, dynamic>> maps) {
    var mappedList = [];
    if (maps.length == 0) {
      mappedList = null;
    } else {
      maps.forEach((map) => mappedList.add(Expense.fromMap(map)));
    }
    return mappedList;
  }

// insert
  Future<int> insert(Expense expense) async {
    Database db = await database;
    int id = await db.insert(tableExpenses, expense.toMap());
    return id;
  }

// getAll
  Future<List<Expense>> getAll() async {
    // Query
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      tableExpenses,
      columns: [columnID, columnItem, columnCategory, columnCost, columnDate],
    );

    return fromMappedList(maps);
  }

// getBetweenDates
  getBetweenDates(int lowerDateMilli, int upperDateMilli) async {
    // Query
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(tableExpenses,
        columns: [columnID, columnItem, columnCategory, columnCost, columnDate],
        where: '$columnDate BETWEEN ? AND ?',
        whereArgs: [lowerDateMilli, upperDateMilli],
        orderBy: '$columnDate ASC');

    return fromMappedList(maps);
  }

// getTopNum
  getTopNumCosts(int limit) async {
    // Query
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(tableExpenses,
        columns: [columnID, columnItem, columnCategory, columnCost, columnDate],
        orderBy: '$columnCost DESC',
        limit: limit);

    return fromMappedList(maps);
  }
}
