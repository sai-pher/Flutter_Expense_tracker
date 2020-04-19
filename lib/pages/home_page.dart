import 'package:expense_tracker/db_handler/handlers/db_handler.dart';
import 'package:expense_tracker/db_handler/models/expense_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Home extends StatefulWidget {
//  final List<Expense> expenseList = DBHandler.handler.getAll();
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final List<Map<String, dynamic>> testList = [
    {"item": "cake", "cost": 10},
    {"item": "cake", "cost": 10},
    {"item": "cake", "cost": 10},
    {"item": "cake", "cost": 10},
    {"item": "cake", "cost": 10},
    {"item": "cake", "cost": 10},
    {"item": "cake", "cost": 10},
    {"item": "cake", "cost": 10},
    {"item": "cake", "cost": 10},
    {"item": "cake", "cost": 10},
    {"item": "cake", "cost": 10},
    {"item": "cake", "cost": 10},
    {"item": "cake", "cost": 10},
    {"item": "cake", "cost": 10},
    {"item": "cake", "cost": 10},
  ];

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
//    print(expenseList);

    return MaterialApp(

      theme: ThemeData(
          brightness: Brightness.dark, primaryColor: Colors.cyan[800]),
      home: homePage(context),
      debugShowCheckedModeBanner: false,
    );
  }

  homePage(BuildContext context) =>
      Scaffold(
        appBar: AppBar(
          title: const Text("Analytics"),
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: const <Widget>[
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.cyan,
                ),
                child: Text(
                  'Drawer Header',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
              ),
              ListTile(
                leading: Icon(Icons.message),
                title: Text('Messages'),
              ),
              ListTile(
                leading: Icon(Icons.account_circle),
                title: Text('Profile'),
              ),
              ListTile(
                leading: Icon(Icons.settings),
                title: Text('Settings'),
              ),
            ],
          ),
        ),
        body: tableWidget(),
        bottomNavigationBar: BottomAppBar(
          shape: CircularNotchedRectangle(),
          child: Container(
            height: 50.0,
          ),
//          color: Colors.cyan[600],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => Navigator.pushNamed(context, '/form'),
          tooltip: "Add new Expense",
          child: Icon(Icons.add),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      );

  tableWidget() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      verticalDirection: VerticalDirection.down,
      children: <Widget>[Expanded(child: dataBodyAsync())],
    );
  }

  dataBody() =>
      SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: DataTable(
          columns: [
            DataColumn(label: Text("Item")),
            DataColumn(label: Text("Cost")),
          ],
          rows: testList
              .map((test) =>
              DataRow(cells: [
                DataCell(Text(test["item"])),
                DataCell(Text(test["cost"].toString())),
              ]))
              .toList(),
        ),
      );

  dataBodyAsync() {
    return FutureBuilder(
      future: DBHandler.handler.getAll(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        Widget child;

        if (snapshot.hasData) {
          List<Expense> expenseList = snapshot.data;
          child = SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: DataTable(
              columns: [
                DataColumn(label: Text("Item")),
                DataColumn(label: Text("Cost")),
              ],
              rows: expenseList
                  .map<DataRow>((expense) =>
                  DataRow(cells: [
                    DataCell(Text(expense.item.toString())),
                    DataCell(Text(expense.cost.toString())),
                  ]))
                  .toList(),
            ),
          );
        } else if (snapshot.hasError) {
          child = Text("Error: ${snapshot.error}\nData: ${snapshot.data}");
        } else {
          child = Text("Waiting... ");
        }

        return child;
      },
    );
  }

}
