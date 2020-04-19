import 'package:expense_tracker/pages/form_page.dart';
import 'package:expense_tracker/pages/home_page.dart';
import 'package:flutter/material.dart';

void main() => runApp(ExpenseTracker());

class ExpenseTracker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return MaterialApp(
      initialRoute: '/home',
      routes: {
        '/home': (context) => Home(),
        '/form': (context) => ExpenseForm(),
      },
      theme: ThemeData(
          brightness: Brightness.dark, primaryColor: Colors.cyan[800]),
      debugShowCheckedModeBanner: false,
    );
  }

}


