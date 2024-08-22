// budget_model.dart

class Budget {
  final String category;
  final double amount;
  final String emoji;

  Budget({
    required this.category,
    required this.amount,
    required this.emoji,
  });

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      category: json['category_name'],
      amount: json['amount'],
      emoji: json['emoji'],
    );
  }
}
