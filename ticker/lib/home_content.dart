import 'package:flutter/material.dart';

class HomeContent extends StatelessWidget {
  final TextEditingController searchController;
  final List<dynamic> searchResults;
  final bool isSearching;
  final bool hasSearched;
  final Function(String) onSearch;
  final Function(String) onStockSelected;

  HomeContent({
    required this.searchController,
    required this.searchResults,
    required this.isSearching,
    required this.hasSearched,
    required this.onSearch,
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
          onChanged: (value) => onSearch(value),
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
                                'Rendering stock: ${stock['1. symbol']} - ${stock['2. name']}');
                            return Column(
                              children: [
                                ListTile(
                                  leading: Icon(Icons.show_chart,
                                      color: Colors.white),
                                  title: Text(
                                    stock['2. name'] ?? 'No Description',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    stock['1. symbol'] ?? '',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                  trailing: Icon(Icons.arrow_forward_ios,
                                      color: Colors.white70),
                                  onTap: () {
                                    if (stock['1. symbol'] != null) {
                                      onStockSelected(stock['1. symbol']);
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
