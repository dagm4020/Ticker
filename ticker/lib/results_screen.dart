import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

import 'results_component/models.dart';
import 'results_component/info_row.dart';
import 'results_component/charts.dart';
import 'results_component/controls.dart';
import 'results_component/enums.dart';

class ResultsScreen extends StatefulWidget {
  final String symbol;
  final String apiKey;

  ResultsScreen({required this.symbol, required this.apiKey});

  @override
  _ResultsScreenState createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  Map<String, dynamic>? _companyOverview;
  Map<String, dynamic>? _timeSeriesData;
  List<FlSpot> _chartData = [];
  bool _isLoading = true;
  bool _hasChartAccess = true;
  double? _currentPrice;
  double? _previousPrice;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  TimeFrame _selectedTimeFrame = TimeFrame.oneDay;
  ChartType _selectedChartType = ChartType.line;
  Map<TimeFrame, Map<String, dynamic>> _cachedTimeSeriesData = {};
  List<CandleData> _candleData = [];

  @override
  void initState() {
    super.initState();
    _fetchCompanyOverview();
    _fetchTimeSeriesData(_selectedTimeFrame);
  }

  Future<void> _fetchCompanyOverview() async {
    final url = Uri.parse(
        'https://www.alphavantage.co/query?function=OVERVIEW&symbol=${widget.symbol}&apikey=${widget.apiKey}');

    try {
      final response = await http.get(url);
      print(
          '🔄 Received response for Company Overview with status code: ${response.statusCode}');
      print('📝 Response body for Company Overview: ${response.body}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data.isNotEmpty) {
          setState(() {
            _companyOverview = data;
          });
        } else {
          print('❌ No company overview data found.');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No company overview data found.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else if (response.statusCode == 403) {
        print(
            '❌ Access to Company Overview is forbidden. Check your API key permissions.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Access to Company Overview is restricted.'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        print(
            '❌ Error fetching company overview: ${response.statusCode} - ${response.reasonPhrase}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching company overview.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('⚠️ Exception while fetching company overview: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred while fetching company overview.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _fetchTimeSeriesData(TimeFrame timeFrame) async {
    if (_cachedTimeSeriesData.containsKey(timeFrame)) {
      setState(() {
        _timeSeriesData = _cachedTimeSeriesData[timeFrame];
        _processChartData(timeFrame);
        _isLoading = false;
        _extractPrices();
        if (_selectedChartType == ChartType.candlestick) {
          _processCandleData(timeFrame);
        }
      });
      return;
    }

    String function;
    String interval = '60min';
    switch (timeFrame) {
      case TimeFrame.oneDay:
        function = 'TIME_SERIES_INTRADAY';
        interval = '60min';
        break;
      case TimeFrame.oneWeek:
      case TimeFrame.oneMonth:
      case TimeFrame.threeMonths:
        function = 'TIME_SERIES_DAILY';
        break;
    }

    String urlString;
    if (function == 'TIME_SERIES_INTRADAY') {
      urlString =
          'https://www.alphavantage.co/query?function=$function&symbol=${widget.symbol}&interval=$interval&apikey=${widget.apiKey}';
    } else {
      urlString =
          'https://www.alphavantage.co/query?function=$function&symbol=${widget.symbol}&apikey=${widget.apiKey}&outputsize=compact';
    }

    final url = Uri.parse(urlString);

    try {
      final response = await http.get(url);
      print(
          '🔄 Received response for ${function} with status code: ${response.statusCode}');
      print('📝 Response body for ${function}: ${response.body}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        String timeSeriesKey;
        switch (function) {
          case 'TIME_SERIES_INTRADAY':
            timeSeriesKey = 'Time Series ($interval)';
            break;
          case 'TIME_SERIES_DAILY':
            timeSeriesKey = 'Time Series (Daily)';
            break;
          default:
            timeSeriesKey = '';
        }

        if (data[timeSeriesKey] != null) {
          Map<String, dynamic> allData =
              Map<String, dynamic>.from(data[timeSeriesKey]);

          bool isValid = allData.values.every((item) =>
              item.containsKey('1. open') &&
              item.containsKey('2. high') &&
              item.containsKey('3. low') &&
              item.containsKey('4. close') &&
              item.containsKey('5. volume'));

          if (!isValid) {
            print('❌ Unexpected data format in API response.');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Unexpected data format from API.'),
                backgroundColor: Colors.red,
              ),
            );
            setState(() {
              _isLoading = false;
              _hasChartAccess = false;
            });
            return;
          }

          Map<String, dynamic> filteredData =
              _filterDataByTimeFrame(allData, timeFrame);

          setState(() {
            _timeSeriesData = filteredData;
            _cachedTimeSeriesData[timeFrame] = _timeSeriesData!;
            _processChartData(timeFrame);
            _isLoading = false;
            _extractPrices();
            if (_selectedChartType == ChartType.candlestick) {
              _processCandleData(timeFrame);
            }
          });
        } else if (data['Note'] != null) {
          print('❌ API Rate Limit Reached.');
          setState(() {
            _isLoading = false;
            _hasChartAccess = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('API rate limit reached. Please try again later.'),
              backgroundColor: Colors.red,
            ),
          );
        } else if (data['Error Message'] != null) {
          print('❌ Error message from API: ${data['Error Message']}');
          setState(() {
            _isLoading = false;
            _hasChartAccess = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${data['Error Message']}'),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          print('❌ Time series data is unavailable or access is restricted.');
          setState(() {
            _isLoading = false;
            _hasChartAccess = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Time series data is unavailable or restricted.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else if (response.statusCode == 403) {
        print(
            '❌ Access to Time Series Data is forbidden. Check your API key permissions.');
        setState(() {
          _isLoading = false;
          _hasChartAccess = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Access to Time Series Data is restricted.'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        print(
            '❌ Error fetching time series data: ${response.statusCode} - ${response.reasonPhrase}');
        setState(() {
          _isLoading = false;
          _hasChartAccess = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching time series data.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('⚠️ Exception while fetching time series data: $e');
      setState(() {
        _isLoading = false;
        _hasChartAccess = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred while fetching time series data.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Map<String, dynamic> _filterDataByTimeFrame(
      Map<String, dynamic> allData, TimeFrame timeFrame) {
    if (timeFrame == TimeFrame.oneDay) {
      List<DateTime> dates =
          allData.keys.map((dateString) => DateTime.parse(dateString)).toList();
      dates.sort((a, b) => b.compareTo(a));
      if (dates.isEmpty) return {};

      DateTime latestDate =
          DateTime(dates[0].year, dates[0].month, dates[0].day);

      Map<String, dynamic> filteredData = {};

      allData.forEach((dateString, data) {
        DateTime date = DateTime.parse(dateString);
        DateTime dateOnly = DateTime(date.year, date.month, date.day);
        if (dateOnly == latestDate) {
          filteredData[dateString] = data;
        }
      });

      print('📊 Filtered Data Count for $timeFrame: ${filteredData.length}');

      return filteredData;
    }

    DateTime now = DateTime.now();
    DateTime fromDate;

    switch (timeFrame) {
      case TimeFrame.oneWeek:
        fromDate = now.subtract(Duration(days: 7));
        break;
      case TimeFrame.oneMonth:
        fromDate = DateTime(now.year, now.month - 1, now.day);
        break;
      case TimeFrame.threeMonths:
        fromDate = DateTime(now.year, now.month - 3, now.day);
        break;
      default:
        fromDate = now.subtract(Duration(days: 7));
    }

    Map<String, dynamic> filteredData = {};

    allData.forEach((dateString, data) {
      DateTime date = DateTime.parse(dateString);
      if (!date.isBefore(fromDate)) {
        filteredData[dateString] = data;
      }
    });

    print('📊 Filtered Data Count for $timeFrame: ${filteredData.length}');

    return filteredData;
  }

  void _processChartData(TimeFrame timeFrame) {
    if (_timeSeriesData == null) return;

    List<String> sortedDates = _timeSeriesData!.keys.toList()..sort();
    List<FlSpot> spots = [];

    for (int i = 0; i < sortedDates.length; i++) {
      String date = sortedDates[i];
      double closePrice =
          double.tryParse(_timeSeriesData![date]['4. close'] ?? '') ?? 0.0;
      spots.add(FlSpot(i.toDouble(), closePrice));
      print('🔹 FlSpot created - X: $i, Y: $closePrice');
    }

    print('📈 Chart Data Count for $timeFrame: ${spots.length}');

    setState(() {
      _chartData = spots;
    });
  }

  void _processCandleData(TimeFrame timeFrame) {
    if (_timeSeriesData == null) return;

    List<String> sortedDates = _timeSeriesData!.keys.toList()..sort();
    List<CandleData> candles = [];

    for (String date in sortedDates) {
      double openPrice =
          double.tryParse(_timeSeriesData![date]['1. open'] ?? '') ?? 0.0;
      double highPrice =
          double.tryParse(_timeSeriesData![date]['2. high'] ?? '') ?? 0.0;
      double lowPrice =
          double.tryParse(_timeSeriesData![date]['3. low'] ?? '') ?? 0.0;
      double closePrice =
          double.tryParse(_timeSeriesData![date]['4. close'] ?? '') ?? 0.0;
      candles.add(CandleData(
        date: date,
        open: openPrice,
        high: highPrice,
        low: lowPrice,
        close: closePrice,
      ));
    }

    setState(() {
      _candleData = candles;
    });
  }

  void _extractPrices() {
    if (_timeSeriesData == null) return;

    List<String> sortedDates = _timeSeriesData!.keys.toList()
      ..sort((a, b) => b.compareTo(a));
    if (sortedDates.length >= 1) {
      _currentPrice =
          double.tryParse(_timeSeriesData![sortedDates[0]]['4. close'] ?? '');
    }
    if (sortedDates.length >= 2) {
      _previousPrice =
          double.tryParse(_timeSeriesData![sortedDates[1]]['4. close'] ?? '');
    }
  }

  @override
  Widget build(BuildContext context) {
    String companyName = _companyOverview != null
        ? _companyOverview!['Name'] ?? widget.symbol
        : widget.symbol;

    String ticker = widget.symbol;

    String companyDescription = '';
    if (_companyOverview != null && _companyOverview!['Description'] != null) {
      companyDescription = _companyOverview!['Description'];
    } else {
      companyDescription = 'No description available.';
    }

    String todayPriceChange = '';
    Color todayPriceChangeColor = Colors.white;
    double? priceChangeAmount;
    double? priceChangePercent;

    if (_currentPrice != null && _previousPrice != null) {
      priceChangeAmount = _currentPrice! - _previousPrice!;
      priceChangePercent = (priceChangeAmount / _previousPrice!) * 100;

      if (priceChangeAmount > 0) {
        todayPriceChangeColor = Colors.green;
        todayPriceChange =
            '+\$${priceChangeAmount.toStringAsFixed(2)} (${priceChangePercent!.toStringAsFixed(2)}%)';
      } else if (priceChangeAmount < 0) {
        todayPriceChangeColor = Colors.red;
        todayPriceChange =
            '-\$${priceChangeAmount!.abs().toStringAsFixed(2)} (${priceChangePercent!.abs().toStringAsFixed(2)}%)';
      } else {
        todayPriceChangeColor = Colors.grey;
        todayPriceChange = '-';
      }
    }

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: Text(
          '$companyName ($ticker)',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.deepPurple.shade800,
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
        actions: [],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black, Colors.deepPurple.shade900],
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? Center(child: CircularProgressIndicator())
              : !_hasChartAccess
                  ? Center(
                      child: Text(
                        'Unable to load chart data.',
                        style: TextStyle(color: Colors.red, fontSize: 18),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  _selectedChartType == ChartType.line
                                      ? Icons.show_chart
                                      : Icons.bar_chart,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _selectedChartType =
                                        _selectedChartType == ChartType.line
                                            ? ChartType.candlestick
                                            : ChartType.line;
                                    if (_selectedChartType ==
                                        ChartType.candlestick) {
                                      _processCandleData(_selectedTimeFrame);
                                    }
                                  });
                                },
                                tooltip: _selectedChartType == ChartType.line
                                    ? 'Switch to Candlestick Chart'
                                    : 'Switch to Line Chart',
                              ),
                              SizedBox(width: 8),
                              Text(
                                _currentPrice != null
                                    ? '\$${_currentPrice!.toStringAsFixed(2)}'
                                    : 'Loading...',
                                style: TextStyle(
                                  fontSize: 32,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                priceChangeAmount != null
                                    ? (priceChangeAmount! > 0
                                        ? '↑ \$${priceChangeAmount!.toStringAsFixed(2)}'
                                        : priceChangeAmount! < 0
                                            ? '↓ \$${priceChangeAmount!.abs().toStringAsFixed(2)}'
                                            : '-')
                                    : '-',
                                style: TextStyle(
                                  color: todayPriceChangeColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 4),
                              Text(
                                priceChangePercent != null
                                    ? priceChangeAmount! != 0
                                        ? '(${priceChangePercent!.toStringAsFixed(2)}%)'
                                        : ''
                                    : '',
                                style: TextStyle(
                                  color: todayPriceChangeColor,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                          TimeFrameSelector(
                            selectedTimeFrame: _selectedTimeFrame,
                            onTimeFrameSelected: (TimeFrame timeFrame) {
                              setState(() {
                                _selectedTimeFrame = timeFrame;
                                _isLoading = true;
                                _hasChartAccess = true;
                                if (_selectedChartType ==
                                    ChartType.candlestick) {
                                  _candleData = [];
                                }
                              });
                              _fetchTimeSeriesData(timeFrame);
                            },
                          ),
                          SizedBox(height: 20),
                          Text(
                            'Stock Chart',
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 10),
                          Container(
                            height: MediaQuery.of(context).size.height * 0.4,
                            child: _selectedChartType == ChartType.line
                                ? LineChartWidget(
                                    chartData: _chartData,
                                    timeSeriesData: _timeSeriesData!,
                                  )
                                : CandlestickChartWidget(
                                    candleData: _candleData,
                                  ),
                          ),
                          SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'About',
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              WatchlistButton(
                                symbol: widget.symbol,
                                companyOverview: _companyOverview,
                                currentPrice: _currentPrice,
                                previousPrice: _previousPrice,
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          Text(
                            companyDescription,
                            style:
                                TextStyle(color: Colors.white70, fontSize: 16),
                          ),
                          SizedBox(height: 20),
                          Text(
                            'Information',
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: InfoRow(
                                      label: 'CEO',
                                      value: _companyOverview?['CEO'] ?? 'N/A',
                                    ),
                                  ),
                                  Expanded(
                                    child: InfoRow(
                                      label: 'Sector',
                                      value:
                                          _companyOverview?['Sector'] ?? 'N/A',
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: InfoRow(
                                      label: 'Headquarters',
                                      value:
                                          _companyOverview?['Country'] ?? 'N/A',
                                    ),
                                  ),
                                  Expanded(
                                    child: InfoRow(
                                      label: 'Industry',
                                      value: _companyOverview?['Industry'] ??
                                          'N/A',
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 10),
                              if (_companyOverview?['MarketCapitalization'] !=
                                  null)
                                InfoRow(
                                  label: 'Market Capitalization',
                                  value:
                                      '\$${_companyOverview!['MarketCapitalization']}',
                                ),
                              SizedBox(height: 10),
                              if (_companyOverview?['IPODate'] != null)
                                InfoRow(
                                  label: 'IPO Date',
                                  value: _companyOverview!['IPODate'],
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }
}
