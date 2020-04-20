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
    return dialog();
  }

  formPage() =>
      Scaffold(
        appBar: AppBar(
          title: Text('Form'),
        ),
        body: FormLayout(),
      );

  dialog() {
    return AlertDialog(
      title: Text('Form pop up'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          FormLayout(),
        ],
      ),
      actions: <Widget>[
        FlatButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          textColor: Theme
              .of(context)
              .primaryColor,
          child: const Text('Cancel'),
        )
      ],
    );
  }


}
