import 'package:charts_flutter/flutter.dart' as charts;
import 'package:expense_tracker/db_handler/handlers/db_handler.dart';
import 'package:expense_tracker/db_handler/models/category_cost_sums_model.dart';
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
    return Container(
      height: 300,
      padding: EdgeInsets.all(16.0),
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: pieChart(),
        ),
      ),
    );
  }

  pieChart() =>
      FutureBuilder(
        future: DBHandler.handler.getCategoryCostSums(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          Widget child;

          if (snapshot.hasData) {
            List<CategoryCostSum> categorySumList = snapshot.data;

            var series = [
              charts.Series(
                  id: 'Category Sums',
                  data: categorySumList,
                  domainFn: (CategoryCostSum category, _) =>
                  category.categoryName,
                  measureFn: (CategoryCostSum category, _) => category.costSum)
            ];

            var chart = charts.PieChart(
              series,
              animate: true,
            );

            child = SizedBox(
//          height: 300,
              child: chart,
            );
          } else if (snapshot.hasError) {
            child = Text("Error: ${snapshot.error}\nData: ${snapshot.data}");
          } else {
            child = Text("Waiting... ");
          }

          return child;
        },
      );

// TODO: Use Future builder to access data points in widgets
// TODO: Create models classes for other data points
}

class SalesData {
  SalesData(this.year, this.sales);

  final String year;
  final double sales;
}
