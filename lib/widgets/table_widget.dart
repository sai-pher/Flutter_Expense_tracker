import 'package:expense_tracker/db_handler/handlers/db_handler.dart';
import 'package:expense_tracker/db_handler/models/expense_model.dart';
import 'package:flutter/material.dart';

class TableWidget extends StatefulWidget {
  @override
  _TableWidgetState createState() => _TableWidgetState();
}

class _TableWidgetState extends State<TableWidget> {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      verticalDirection: VerticalDirection.down,
      children: <Widget>[Expanded(child: dataBodyAsync())],
    );
  }

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
}
