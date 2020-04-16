import 'package:expense_tracker/db_handler/handlers/db_handler.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Home extends StatelessWidget {
//  final List<Expense> expenseList = DBHandler.handler.getAll();
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
      home: Scaffold(
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
          onPressed: () => print("Add button pressed"),
          tooltip: "Add new Expense",
          child: Icon(Icons.add),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
      debugShowCheckedModeBanner: false,
    );
  }

  tableWidget() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      verticalDirection: VerticalDirection.down,
      children: <Widget>[Expanded(child: dataBodyAsync())],
    );
  }

  dataBody() => SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: DataTable(
          columns: [
            DataColumn(label: Text("Item")),
            DataColumn(label: Text("Cost")),
          ],
          rows: testList
              .map((test) => DataRow(cells: [
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
//          List<Expense> eList = snapshot.data;
          child = SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: DataTable(
              columns: [
                DataColumn(label: Text("Item")),
                DataColumn(label: Text("Cost")),
              ],
              rows: snapshot.data
                  .map<DataRow>((expense) => DataRow(cells: [
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

//  dataBodyAsyncish() {
//    var snapshot = DBHandler.handler.getAll();
//    return SingleChildScrollView(
//      scrollDirection: Axis.vertical,
//      child: DataTable(
//        columns: [
//          DataColumn(label: Text("Item")),
//          DataColumn(label: Text("Cost")),
//        ],
//        rows: snapshot.data
//            .map((expense) => DataRow(cells: [
//          DataCell(Text(expense.item)),
//          DataCell(Text(expense.cost.toString())),
//        ]))
//            .toList(),
//      ),
//    );
//  }

}
