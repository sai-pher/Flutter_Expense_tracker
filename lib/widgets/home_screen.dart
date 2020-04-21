import 'package:expense_tracker/widgets/pie_chart_widget.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return homeScreen();
  }

  homeScreen() {
    return Container(
      child: Center(
        child: ListView(
          children: <Widget>[
            PieChartWidget(),
            PieChartWidget(),
            PieChartWidget(),
            PieChartWidget(),
            Text("thing 2"),
            Text("thing 3"),
            Text("thing 4"),
          ],
        ),
      ),
    );
  }
}
