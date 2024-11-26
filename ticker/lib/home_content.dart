import 'package:flutter/material.dart';

class HomeContent extends StatelessWidget {
  final TextEditingController searchController;
  final List<dynamic> searchResults;
  final bool isSearching;
  final Function(String) onSearch;
  final Function(String) onStockSelected;

  HomeContent({
    required this.searchController,
    required this.searchResults,
    required this.isSearching,
    required this.onSearch,
    required this.onStockSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
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
          isSearching
              ? Center(child: CircularProgressIndicator())
              : searchResults.isEmpty
                  ? Center(
                      child: Text(
                        'No results',
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  : ListView.builder(
                      physics: NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: searchResults.length,
                      itemBuilder: (context, index) {
                        final stock = searchResults[index];
                        return ListTile(
                          leading: Icon(Icons.show_chart, color: Colors.white),
                          title: Text(
                            stock['description'] ?? 'No Description',
                            style: TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            stock['symbol'] ?? '',
                            style: TextStyle(color: Colors.white70),
                          ),
                          onTap: () {
                            if (stock['symbol'] != null) {
                              onStockSelected(stock['symbol']);
                            }
                          },
                        );
                      },
                    ),
        ],
      ),
    );
  }
}
