import 'package:expense_tracker/db_handler/handlers/db_handler.dart';
import 'package:expense_tracker/db_handler/models/expense_model.dart';
import 'package:flutter/material.dart';

class FormLayout extends StatefulWidget {
  @override
  _FormLayoutState createState() => _FormLayoutState();
}

class _FormLayoutState extends State<FormLayout> {
  final _formKey = GlobalKey<FormState>();
  static final List<String> categories = ["Food", "Health", "miscellaneous"];
  String _itemName = '';
  double _cost = 0;
  String _selectedCategory = categories[0];
  var _now = DateTime.now();

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return formLayout();
  }

  formLayout() {
    List<DropdownMenuItem> categoryList = categories
        .map((category) =>
            DropdownMenuItem(child: Text(category), value: category))
        .toList();

    return Form(
      key: _formKey,
      child: Column(
        children: <Widget>[
          TextFormField(
            decoration: InputDecoration(
              hintText: 'Item Name',
            ),
            validator: (name) {
              return null;
            },
            onSaved: (name) {
              setState(() {
                _itemName = name;
              });
            },
          ),
          TextFormField(
            decoration: InputDecoration(
              hintText: 'Cost',
            ),
            keyboardType: TextInputType.numberWithOptions(),
            validator: (cost) {
              return null;
            },
            onSaved: (cost) {
              setState(() {
                _cost = double.tryParse(cost);
              });
            },
          ),
          DropdownButtonFormField(
              items: categoryList,
              value: _selectedCategory,
              validator: (category) {
                return null;
              },
              onChanged: (newValue) {
                setState(() {
                  _selectedCategory = newValue;
                });
              },
              onSaved: (category) {
                setState(() {
                  _selectedCategory = category;
                });
              }),
          Builder(
              builder: (context) => RaisedButton(
                    child: Text('Add'),
                    onPressed: () {
                      print('Adding diswans...');
                      if (_formKey.currentState.validate()) {
                        _formKey.currentState.save();
                        var expense = Expense(_itemName, _selectedCategory,
                            _cost, DateTime.now());
                        DBHandler.handler.insert(expense);
                        Navigator.pop(context);
                      }
                    },
                  ))
        ],
      ),
    );
  }
}
