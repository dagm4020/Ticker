import 'package:flutter/material.dart';

class WatchlistScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.black, Colors.deepPurple.shade900],
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        ),
      ),
      child: Center(
        child: Text(
          'Watchlist',
          style: TextStyle(
            fontSize: 24,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
