import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'dart:math';
import 'models.dart';
import 'enums.dart';

class LineChartWidget extends StatelessWidget {
  final List<FlSpot> chartData;
  final Map<String, dynamic> timeSeriesData;

  LineChartWidget({required this.chartData, required this.timeSeriesData});

  @override
  Widget build(BuildContext context) {
    if (chartData.isEmpty) {
      return Center(
        child: Text(
          'No data available for the selected TimeFrame.',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    List<String> sortedDates = timeSeriesData.keys.toList()..sort();

    double minY = chartData.map((spot) => spot.y).reduce(min) * 0.95;
    double maxY = chartData.map((spot) => spot.y).reduce(max) * 1.05;

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (LineBarSpot touchedSpot) =>
                Colors.blueAccent.withOpacity(0.8),
            getTooltipItems: (touchedSpots) {
              return touchedSpots
                  .map((spot) {
                    int index = spot.x.toInt();
                    if (index < 0 || index >= sortedDates.length) return null;
                    String date = sortedDates[index];
                    double price = spot.y;
                    return LineTooltipItem(
                      '$date\n\$${price.toStringAsFixed(2)}',
                      TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  })
                  .whereType<LineTooltipItem>()
                  .toList();
            },
          ),
        ),
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: chartData,
            isCurved: true,
            color: Colors.blueAccent,
            barWidth: 2,
            dotData: FlDotData(show: false),
          ),
        ],
      ),
    );
  }
}

class CandlestickChartWidget extends StatelessWidget {
  final List<CandleData> candleData;

  CandlestickChartWidget({required this.candleData});

  @override
  Widget build(BuildContext context) {
    if (candleData.isEmpty) {
      return Center(
        child: Text(
          'No candlestick data available for the selected TimeFrame.',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return SfCartesianChart(
      primaryXAxis: CategoryAxis(
        majorGridLines: MajorGridLines(width: 0),
        labelStyle: TextStyle(color: Colors.white70),
      ),
      primaryYAxis: NumericAxis(
        majorGridLines: MajorGridLines(width: 0),
        labelStyle: TextStyle(color: Colors.white70),
        isVisible: false,
      ),
      tooltipBehavior: TooltipBehavior(
        enable: true,
        header: '',
        format:
            'point.x\nOpen: point.open\nHigh: point.high\nLow: point.low\nClose: point.close',
      ),
      series: <CandleSeries>[
        CandleSeries<CandleData, String>(
          dataSource: candleData,
          xValueMapper: (CandleData data, _) => data.date,
          lowValueMapper: (CandleData data, _) => data.low,
          highValueMapper: (CandleData data, _) => data.high,
          openValueMapper: (CandleData data, _) => data.open,
          closeValueMapper: (CandleData data, _) => data.close,
          bearColor: Colors.red,
          bullColor: Colors.green,
        )
      ],
      plotAreaBorderWidth: 0,
      trackballBehavior: TrackballBehavior(
        enable: true,
        activationMode: ActivationMode.singleTap,
        tooltipDisplayMode: TrackballDisplayMode.floatAllPoints,
        tooltipSettings: InteractiveTooltip(
          enable: true,
          color: Colors.blueAccent.withOpacity(0.8),
          textStyle: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
