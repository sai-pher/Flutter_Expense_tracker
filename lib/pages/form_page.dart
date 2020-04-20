import 'package:expense_tracker/widgets/form_layout.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ExpenseForm extends StatefulWidget {
  @override
  _ExpenseFormState createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<ExpenseForm> {


  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        title: Text('Form'),
      ),
      body: FormLayout(),
    );
  }


}
