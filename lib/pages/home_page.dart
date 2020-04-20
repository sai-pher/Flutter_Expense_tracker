import 'package:expense_tracker/widgets/drawer_widget.dart';
import 'package:expense_tracker/widgets/table_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
//    print(expenseList);

    return homePage(context);
  }

  homePage(BuildContext context) =>
      Scaffold(
        appBar: AppBar(
          title: const Text("Analytics"),
        ),
        drawer: DrawerWidget(),
        body: TableWidget(),
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

}
