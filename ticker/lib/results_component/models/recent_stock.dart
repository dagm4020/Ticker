import 'package:cloud_firestore/cloud_firestore.dart';

class RecentStock {
  final String symbol;
  final String name;

  RecentStock({required this.symbol, required this.name});

  Map<String, dynamic> toMap() {
    return {
      'symbol': symbol,
      'name': name,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }

  factory RecentStock.fromMap(Map<String, dynamic> map) {
    return RecentStock(
      symbol: map['symbol'] ?? '',
      name: map['name'] ?? '',
    );
  }
}
