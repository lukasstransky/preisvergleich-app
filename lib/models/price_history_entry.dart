class PriceHistoryEntry {
  final double price;
  final String date; // "YYYY-MM-DD"

  const PriceHistoryEntry({required this.price, required this.date});

  factory PriceHistoryEntry.fromFirestore(Map<String, dynamic> data) {
    return PriceHistoryEntry(
      price: (data['price'] as num).toDouble(),
      date: data['date'] as String,
    );
  }
}
