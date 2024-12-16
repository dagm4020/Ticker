import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class WatchlistScreen extends StatefulWidget {
  @override
  _WatchlistScreenState createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot>? _watchlistStream;

  String _selectedFilter = 'Symbol Ascending';

  @override
  void initState() {
    super.initState();
    _setupWatchlistStream();
  }

  void _setupWatchlistStream() {
    User? user = _auth.currentUser;

    if (user != null) {
      setState(() {
        _watchlistStream = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('watchlist')
            .orderBy('timestamp', descending: true)
            .snapshots();
      });
    } else {
      setState(() {
        _watchlistStream = null;
      });
    }
  }

  Future<void> _removeFromWatchlist(String symbol) async {
    User? user = _auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You need to be logged in to remove from watchlist.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('watchlist')
          .doc(symbol)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Stock removed from watchlist.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('❌ Error removing from watchlist: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove from watchlist. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<Map<String, dynamic>> _getSortedWatchlist(
      List<Map<String, dynamic>> watchlist) {
    List<Map<String, dynamic>> sortedList = List.from(watchlist);

    if (_selectedFilter == 'Symbol Ascending') {
      sortedList.sort((a, b) => a['symbol'].compareTo(b['symbol']));
    } else if (_selectedFilter == 'Symbol Descending') {
      sortedList.sort((a, b) => b['symbol'].compareTo(a['symbol']));
    } else if (_selectedFilter == 'Price Change Ascending') {
      sortedList.sort((a, b) => (a['price_change_percentage'] ?? 0.0)
          .compareTo(b['price_change_percentage'] ?? 0.0));
    } else if (_selectedFilter == 'Price Change Descending') {
      sortedList.sort((a, b) => (b['price_change_percentage'] ?? 0.0)
          .compareTo(a['price_change_percentage'] ?? 0.0));
    }

    return sortedList;
  }

  @override
  Widget build(BuildContext context) {
    String apiKey = dotenv.env['ALPHA_VANTAGE_API_KEY'] ?? '';

    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black, Colors.deepPurple.shade900],
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
          ),
        ),
        child: _watchlistStream == null
            ? Center(
                child: Text(
                  'You need to be logged in to view your watchlist.',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              )
            : StreamBuilder<QuerySnapshot>(
                stream: _watchlistStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'An error occurred while fetching your watchlist.',
                        style: TextStyle(color: Colors.red, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final watchlistDocs = snapshot.data!.docs;

                  if (watchlistDocs.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 50.0),
                      child: Center(
                        child: Text(
                          'Save a stock to see it on this screen.',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  List<Map<String, dynamic>> watchlist = watchlistDocs
                      .map((doc) => (doc.data() as Map<String, dynamic>))
                      .toList();

                  List<Map<String, dynamic>> sortedWatchlist =
                      _getSortedWatchlist(watchlist);

                  return Column(
                    children: [
                      SizedBox(height: 70.0),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            PopupMenuButton<String>(
                              icon: Icon(
                                Icons.filter_list,
                                color: Colors.white,
                              ),
                              offset: Offset(0, 40),
                              color: Colors.deepPurple.shade900,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              elevation: 8.0,
                              onSelected: (value) {
                                setState(() {
                                  _selectedFilter = value;
                                });
                              },
                              itemBuilder: (BuildContext context) {
                                return [
                                  PopupMenuItem(
                                    value: 'Symbol Ascending',
                                    child: Container(
                                      width: 250,
                                      child: Row(
                                        children: [
                                          if (_selectedFilter ==
                                              'Symbol Ascending')
                                            Icon(Icons.check,
                                                color: Colors.white),
                                          SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Sort by Symbol (A-Z)',
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'Symbol Descending',
                                    child: Container(
                                      width: 250,
                                      child: Row(
                                        children: [
                                          if (_selectedFilter ==
                                              'Symbol Descending')
                                            Icon(Icons.check,
                                                color: Colors.white),
                                          SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Sort by Symbol (Z-A)',
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'Price Change Ascending',
                                    child: Container(
                                      width: 250,
                                      child: Row(
                                        children: [
                                          if (_selectedFilter ==
                                              'Price Change Ascending')
                                            Icon(Icons.check,
                                                color: Colors.white),
                                          SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Sort by Price Change (%) Ascending',
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'Price Change Descending',
                                    child: Container(
                                      width: 250,
                                      child: Row(
                                        children: [
                                          if (_selectedFilter ==
                                              'Price Change Descending')
                                            Icon(Icons.check,
                                                color: Colors.white),
                                          SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Sort by Price Change (%) Descending',
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ];
                              },
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'Filter: $_selectedFilter',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 16.0),
                      Expanded(
                        child: ListView.builder(
                          padding: EdgeInsets.only(
                              left: 16.0, right: 16.0, bottom: 16.0),
                          itemCount: sortedWatchlist.length,
                          itemBuilder: (context, index) {
                            var data = sortedWatchlist[index];

                            String symbol = data['symbol'] ?? 'N/A';
                            String name = data['name'] ?? 'No Name';
                            double currentPrice =
                                (data['current_price'] ?? 0.0).toDouble();
                            double priceChangePercent =
                                (data['price_change_percentage'] ?? 0.0)
                                    .toDouble();

                            bool isPositive = priceChangePercent >= 0;
                            Color changeColor;
                            IconData changeIcon;

                            if (priceChangePercent > 0) {
                              changeColor = Colors.green;
                              changeIcon = Icons.arrow_upward;
                            } else if (priceChangePercent < 0) {
                              changeColor = Colors.red;
                              changeIcon = Icons.arrow_downward;
                            } else {
                              changeColor = Colors.grey;
                              changeIcon = Icons.remove;
                            }

                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: Card(
                                color:
                                    Colors.deepPurple.shade700.withOpacity(0.8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                child: InkWell(
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/results',
                                      arguments: {
                                        'symbol': symbol,
                                        'apiKey': apiKey,
                                      },
                                    );
                                  },
                                  onLongPress: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: Text('Remove from Watchlist'),
                                        content: Text(
                                            'Are you sure you want to remove $symbol from your watchlist?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                              _removeFromWatchlist(symbol);
                                            },
                                            child: Text('Remove'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                symbol,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                name,
                                                style: TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              '\$${currentPrice.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  changeIcon,
                                                  color: changeColor,
                                                  size: 16,
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  '${priceChangePercent.toStringAsFixed(2)}%',
                                                  style: TextStyle(
                                                    color: changeColor,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
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
    return Row(
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
    );
  }
}
