
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'watchlist_screen.dart';
import 'newsfeed_screen.dart';
import 'settings_screen.dart';
import 'results_screen.dart'; import 'dart:convert'; import 'package:http/http.dart' as http; import 'package:flutter_dotenv/flutter_dotenv.dart'; import 'dart:async'; 
class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  int _selectedIndex = 0;

    String _apiKey = '';

    TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false; 
    Timer? _debounce;

  @override
  void initState() {
    super.initState();
    print('initState called');

        _apiKey = dotenv.env['FINNHUB_API_KEY'] ?? '';
    if (_apiKey.isEmpty) {
      print('❌ Error: FINNHUB_API_KEY not found in .env file.');
    } else {
      print('✅ API Key loaded successfully: $_apiKey');
    }

        _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
            if (index != 0) {
        _searchController.clear();
        _searchResults = [];
        _isSearching = false;
        _hasSearched = false;
      }
    });
  }

    void _onSearchChanged() {
    if (_searchController.text.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _hasSearched = false;
      });
      return;
    }

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(_searchController.text.trim());
    });
  }

    Future<void> _performSearch(String query) async {
    print('Search initiated with query: "$query"'); 
    if (_apiKey.isEmpty) {
      print('❌ API Key is missing.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('API Key is missing. Please contact support.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (query.isEmpty) {
      print('❌ Query is empty.');
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _hasSearched = true;     });

    final url = Uri.parse(
        'https://finnhub.io/api/v1/search?q=$query&token=$_apiKey');
    print('📡 Sending GET request to: $url');

    try {
      final response = await http.get(url);
      print('🔄 Received response with status code: ${response.statusCode}'); 
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Response data: ${data['result']}'); 
        if (data['result'] != null && data['result'] is List) {
          setState(() {
            _searchResults = data['result'];
            _isSearching = false;
          });
        } else {
          setState(() {
            _searchResults = [];
            _isSearching = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No valid results found.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else if (response.statusCode == 401) {
        print('❌ Unauthorized: Invalid API Key.');
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unauthorized: Invalid API Key.'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        print('❌ Error: ${response.statusCode} ${response.reasonPhrase}');
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Error: ${response.statusCode} ${response.reasonPhrase}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('⚠️ Exception during search: $e');
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred while searching.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

    void _navigateToResults(String symbol) {
    if (_apiKey.isEmpty) {
      print('❌ Cannot navigate: API Key is missing.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('API Key is missing. Cannot fetch results.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    print('Navigating to ResultsScreen for symbol: $symbol'); 
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultsScreen(symbol: symbol, apiKey: _apiKey),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
        Widget currentScreen;
    switch (_selectedIndex) {
      case 0:
        currentScreen = HomeContent(
          searchController: _searchController,
          searchResults: _searchResults,
          isSearching: _isSearching,
          hasSearched: _hasSearched,
          onSearch: _performSearch,
          onStockSelected: _navigateToResults,
        );
        break;
      case 1:
        currentScreen = WatchlistScreen();
        break;
      case 2:
        currentScreen = NewsfeedScreen();
        break;
      case 3:
        currentScreen = SettingsScreen();
        break;
      default:
        currentScreen = HomeContent(
          searchController: _searchController,
          searchResults: _searchResults,
          isSearching: _isSearching,
          hasSearched: _hasSearched,
          onSearch: _performSearch,
          onStockSelected: _navigateToResults,
        );
    }

    return Scaffold(
      extendBody: true,             body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black, Colors.deepPurple.shade900],
            begin: Alignment.bottomLeft,             end: Alignment.topRight,           ),
        ),
        child: SafeArea(
          child: Column(
            children: [
                            Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                color: Colors.transparent,
                child: Center(
                  child: Text(
                    _selectedIndex == 0
                        ? 'Dashboard'
                        : _selectedIndex == 1
                            ? 'Watchlist'
                            : _selectedIndex == 2
                                ? 'Newsfeed'
                                : 'Settings',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
                            Expanded(
                child: currentScreen,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        margin: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: Colors.deepPurple.shade800.withOpacity(0.8),           borderRadius: BorderRadius.circular(30),           boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BottomNavigationBar(
            backgroundColor: Colors.transparent,             items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.remove_red_eye),
                label: 'Watchlist',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.feed),
                label: 'Newsfeed',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.white70,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            iconSize: 24,           ),
        ),
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  final TextEditingController searchController;
  final List<dynamic> searchResults;
  final bool isSearching;
  final bool hasSearched;   final Function(String) onSearch;
  final Function(String) onStockSelected;

  HomeContent({
    required this.searchController,
    required this.searchResults,
    required this.isSearching,
    required this.hasSearched,     required this.onSearch,
    required this.onStockSelected,
  });

  @override
  Widget build(BuildContext context) {
    print(
        'HomeContent build called with searchResults length: ${searchResults.length}');
    if (searchResults.isNotEmpty) {
      print('Sample search result: ${searchResults[0]}');
    }

    return Column(
      children: [
                TextField(
          controller: searchController,
          onChanged: onSearch,
          decoration: InputDecoration(
            hintText: 'Search for stocks...',
            prefixIcon: Icon(Icons.search),
            filled: true,
            fillColor: Colors.white.withOpacity(0.8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30.0),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        SizedBox(height: 10),
        Expanded(
          child: isSearching
              ? Center(child: CircularProgressIndicator())
              : !hasSearched
                  ? Center(
                      child: Text(
                        'Please enter a stock symbol or company name to search.',
                        style: TextStyle(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : searchResults.isEmpty
                      ? Center(
                          child: Text(
                            'No results found.',
                            style: TextStyle(color: Colors.white),
                          ),
                        )
                      : ListView.builder(
                          itemCount: searchResults.length,
                          itemBuilder: (context, index) {
                            final stock = searchResults[index];
                            print(
                                'Rendering stock: ${stock['symbol']} - ${stock['description']}');                             return Column(
                              children: [
                                ListTile(
                                  leading: Icon(Icons.show_chart,
                                      color: Colors.white),
                                  title: Text(
                                    stock['description'] ?? 'No Description',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    stock['symbol'] ?? '',
                                    style:
                                        TextStyle(color: Colors.white70),
                                  ),
                                  trailing: Icon(Icons.arrow_forward_ios,
                                      color: Colors.white70),
                                  onTap: () {
                                    if (stock['symbol'] != null) {
                                      onStockSelected(stock['symbol']);
                                    }
                                  },
                                ),
                                Divider(color: Colors.white30),
                              ],
                            );
                          },
                        ),
        ),
      ],
    );
  }
}
