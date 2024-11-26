import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';

class ResultsScreen extends StatefulWidget {
  final String symbol;
  final String apiKey;

  ResultsScreen({required this.symbol, required this.apiKey});

  @override
  _ResultsScreenState createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  Map<String, dynamic>? _companyProfile;
  List<FlSpot> _chartData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCompanyProfile();
    _fetchChartData();
  }

  Future<void> _fetchCompanyProfile() async {
    final url = Uri.parse(
        'https://finnhub.io/api/v1/stock/profile2?symbol=${widget.symbol}&token=${widget.apiKey}');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _companyProfile = data;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Error fetching company profile: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred while fetching company profile.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _fetchChartData() async {
    final now = DateTime.now();
    final oneWeekAgo = now.subtract(Duration(days: 7));
    final to = (now.millisecondsSinceEpoch / 1000).round();
    final from = (oneWeekAgo.millisecondsSinceEpoch / 1000).round();

    final url = Uri.parse(
        'https://finnhub.io/api/v1/stock/candle?symbol=${widget.symbol}&resolution=D&from=$from&to=$to&token=${widget.apiKey}');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['s'] == 'ok') {
          List<dynamic> closes = data['c'];
          List<dynamic> t = data['t'];

          List<FlSpot> spots = [];
          for (int i = 0; i < closes.length; i++) {
            spots.add(FlSpot(i.toDouble(), closes[i].toDouble()));
          }

          setState(() {
            _chartData = spots;
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No chart data available for this stock.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching chart data: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred while fetching chart data.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String companyName = _companyProfile != null
        ? _companyProfile!['name'] ?? widget.symbol
        : widget.symbol;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          companyName,
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.deepPurple.shade800,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black, Colors.deepPurple.shade900],
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
          ),
        ),
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                      height: MediaQuery.of(context).size.height * 0.3,
                      child: _chartData.isNotEmpty
                          ? LineChart(
                              LineChartData(
                                gridData: FlGridData(show: false),
                                borderData: FlBorderData(show: false),
                                titlesData: FlTitlesData(
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 40,
                                      getTitlesWidget: (value, meta) {
                                        return Text('\$${value.toInt()}',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 10));
                                      },
                                    ),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 30,
                                      getTitlesWidget: (value, meta) {
                                        return Text('${value.toInt()}',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 10));
                                      },
                                    ),
                                  ),
                                ),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: _chartData,
                                    isCurved: true,
                                    color: Colors.blueAccent,
                                    barWidth: 2,
                                    dotData: FlDotData(show: false),
                                  ),
                                ],
                              ),
                            )
                          : Center(
                              child: Text(
                                'No chart data available.',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'About',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      _companyProfile != null
                          ? _companyProfile!['description'] ??
                              'No description available.'
                          : 'No description available.',
                      style: TextStyle(color: Colors.white70),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Company Information',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    _companyProfile != null
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              InfoRow(
                                  label: 'CEO',
                                  value: _companyProfile!['ceo'] ?? 'N/A'),
                              InfoRow(
                                  label: 'Sector',
                                  value: _companyProfile!['finnhubIndustry'] ??
                                      'N/A'),
                              InfoRow(
                                  label: 'Headquarters',
                                  value: _companyProfile!['country'] ?? 'N/A'),
                              InfoRow(
                                  label: 'Market Capitalization',
                                  value: _companyProfile![
                                              'marketCapitalization'] !=
                                          null
                                      ? '\$${_companyProfile!['marketCapitalization'].toString()}'
                                      : 'N/A'),
                              InfoRow(
                                  label: 'IPO',
                                  value: _companyProfile!['ipo'] ?? 'N/A'),
                            ],
                          )
                        : Text(
                            'No company information available.',
                            style: TextStyle(color: Colors.white70),
                          ),
                  ],
                ),
              ),
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  final String label;
  final String value;

  InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
