import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';

class PieChartWidget extends StatefulWidget {
  @override
  _PieChartWidgetState createState() => _PieChartWidgetState();
}

class _PieChartWidgetState extends State<PieChartWidget> {
  @override
  Widget build(BuildContext context) {
    var series = [
      charts.Series(
          id: 'Sales',
          data: [
            SalesData('Jan', 35),
            SalesData('Feb', 28),
            SalesData('Mar', 34),
            SalesData('Apr', 32),
            SalesData('May', 40)
          ],
          domainFn: (SalesData sale, _) => sale.year,
          measureFn: (SalesData sale, _) => sale.sales)
    ];

    var chart = charts.PieChart(
      series,
      animate: true,
    );

    // TODO: implement build
    return Padding(
      padding: new EdgeInsets.all(32.0),
      child: new SizedBox(
        height: 500.0,
        child: chart,
      ),
    );
  }

// TODO: Use Future builder to access data points in widgets
// TODO: Create models classes for other data points
}

class SalesData {
  SalesData(this.year, this.sales);

  final String year;
  final double sales;
}
