class AdminAnalyticsModel {
  const AdminAnalyticsModel({
    required this.totalRevenue,
    required this.selectedDateRevenue,
    required this.categoryRevenue,
    required this.dailyBreakdown,
    required this.monthlyBreakdown,
  });

  final double totalRevenue;
  final double selectedDateRevenue;
  final Map<String, double> categoryRevenue;
  final List<DailyRevenue> dailyBreakdown;
  final List<MonthlyRevenue> monthlyBreakdown;

  factory AdminAnalyticsModel.fromJson(Map<String, dynamic> json) {
    final rawCategories = json['categoryRevenue'];
    final categories = rawCategories is Map
        ? rawCategories.map(
            (key, value) => MapEntry(
              key.toString(),
              double.tryParse(value.toString()) ?? 0,
            ),
          )
        : <String, double>{};
    final rawDaily = json['dailyBreakdown'];
    final rawMonthly = json['monthlyBreakdown'];

    return AdminAnalyticsModel(
      totalRevenue: double.tryParse('${json['totalRevenue'] ?? 0}') ?? 0,
      selectedDateRevenue:
          double.tryParse('${json['selectedDateRevenue'] ?? 0}') ?? 0,
      categoryRevenue: categories,
      dailyBreakdown: rawDaily is List
          ? rawDaily
                .whereType<Map>()
                .map(
                  (item) =>
                      DailyRevenue.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList(growable: false)
          : const [],
      monthlyBreakdown: rawMonthly is List
          ? rawMonthly
                .whereType<Map>()
                .map(
                  (item) =>
                      MonthlyRevenue.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList(growable: false)
          : const [],
    );
  }
}

class DailyRevenue {
  const DailyRevenue({required this.date, required this.revenue});

  final DateTime date;
  final double revenue;

  factory DailyRevenue.fromJson(Map<String, dynamic> json) {
    return DailyRevenue(
      date: DateTime.tryParse('${json['date'] ?? ''}') ?? DateTime.now(),
      revenue: double.tryParse('${json['revenue'] ?? 0}') ?? 0,
    );
  }
}

class MonthlyRevenue {
  const MonthlyRevenue({required this.month, required this.revenue});

  final DateTime month;
  final double revenue;

  factory MonthlyRevenue.fromJson(Map<String, dynamic> json) {
    return MonthlyRevenue(
      month: DateTime.tryParse('${json['month'] ?? ''}') ?? DateTime.now(),
      revenue: double.tryParse('${json['revenue'] ?? 0}') ?? 0,
    );
  }
}
