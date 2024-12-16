import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../results_component/models.dart';
import 'enums.dart';

class TimeFrameSelector extends StatelessWidget {
  final TimeFrame selectedTimeFrame;
  final Function(TimeFrame) onTimeFrameSelected;

  TimeFrameSelector({
    required this.selectedTimeFrame,
    required this.onTimeFrameSelected,
  });

  Widget _buildButton(BuildContext context, TimeFrame timeFrame, String label) {
    bool isSelected = selectedTimeFrame == timeFrame;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ElevatedButton(
        onPressed: () => onTimeFrameSelected(timeFrame),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isSelected ? Colors.deepPurpleAccent : Colors.grey.shade800,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildButton(context, TimeFrame.oneDay, '1D'),
        _buildButton(context, TimeFrame.oneWeek, '1W'),
        _buildButton(context, TimeFrame.oneMonth, '1M'),
        _buildButton(context, TimeFrame.threeMonths, '3M'),
      ],
    );
  }
}

class WatchlistButton extends StatefulWidget {
  final String symbol;
  final Map<String, dynamic>? companyOverview;
  final double? currentPrice;
  final double? previousPrice;

  WatchlistButton({
    required this.symbol,
    required this.companyOverview,
    required this.currentPrice,
    required this.previousPrice,
  });

  @override
  _WatchlistButtonState createState() => _WatchlistButtonState();
}

class _WatchlistButtonState extends State<WatchlistButton> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isInWatchlist = false;
  bool _isAddingWatchlist = false;

  @override
  void initState() {
    super.initState();
    _checkIfInWatchlist();
  }

  Future<void> _checkIfInWatchlist() async {
    User? user = _auth.currentUser;
    if (user == null) return;

    DocumentSnapshot doc = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('watchlist')
        .doc(widget.symbol)
        .get();

    setState(() {
      _isInWatchlist = doc.exists;
    });
  }

  Future<void> _toggleWatchlist() async {
    setState(() {
      _isAddingWatchlist = true;
    });

    User? user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You need to be logged in to manage your watchlist.'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isAddingWatchlist = false;
      });
      return;
    }

    try {
      if (_isInWatchlist) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('watchlist')
            .doc(widget.symbol)
            .delete();
        setState(() {
          _isInWatchlist = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed from watchlist.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('watchlist')
            .doc(widget.symbol)
            .set({
          'symbol': widget.symbol,
          'name': widget.companyOverview?['Name'] ?? 'N/A',
          'current_price': widget.currentPrice ?? 0.0,
          'price_change_percentage':
              widget.previousPrice != null && widget.previousPrice! != 0.0
                  ? ((widget.currentPrice! - widget.previousPrice!) /
                          widget.previousPrice!) *
                      100
                  : 0.0,
          'timestamp': FieldValue.serverTimestamp(),
        });
        setState(() {
          _isInWatchlist = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added to watchlist.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Error toggling watchlist: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred while updating watchlist.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isAddingWatchlist = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: _isAddingWatchlist
          ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.0,
              ),
            )
          : Icon(
              _isInWatchlist
                  ? Icons.remove_circle_outline
                  : Icons.add_circle_outline,
              color: _isInWatchlist ? Colors.red : Colors.green,
            ),
      onPressed: _isAddingWatchlist ? null : _toggleWatchlist,
      tooltip: _isInWatchlist ? 'Remove from Watchlist' : 'Add to Watchlist',
    );
  }
}
