import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'models/expense_model.dart';

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
    Directory directoryPath = await getApplicationDocumentsDirectory();
    String path = join(directoryPath.path, _databaseName);

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

// insert
// getAll
// getBetweenDates
// getTopFive

}
