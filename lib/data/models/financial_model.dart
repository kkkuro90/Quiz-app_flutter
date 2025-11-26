class FinancialRecord {
  final String id;
  final String quizId;
  final String quizTitle;
  final DateTime period;
  final double plannedIncome;
  final double actualIncome;
  final double expenses;

  FinancialRecord({
    required this.id,
    required this.quizId,
    required this.quizTitle,
    required this.period,
    required this.plannedIncome,
    required this.actualIncome,
    required this.expenses,
  });

  double get profit => actualIncome - expenses;

  double get executionRate =>
      plannedIncome == 0 ? 0 : actualIncome / plannedIncome;
}

class FinancialMetrics {
  final double totalIncome;
  final double totalExpenses;
  final double netProfit;
  final double monthlyProjection;
  final double trendPercentage;

  const FinancialMetrics({
    required this.totalIncome,
    required this.totalExpenses,
    required this.netProfit,
    required this.monthlyProjection,
    required this.trendPercentage,
  });
}

class FinancialCalculator {
  static FinancialMetrics calculateMetrics(List<FinancialRecord> records) {
    if (records.isEmpty) {
      return const FinancialMetrics(
        totalIncome: 0,
        totalExpenses: 0,
        netProfit: 0,
        monthlyProjection: 0,
        trendPercentage: 0,
      );
    }

    final totalIncome =
        records.fold<double>(0, (sum, record) => sum + record.actualIncome);
    final totalExpenses =
        records.fold<double>(0, (sum, record) => sum + record.expenses);
    final netProfit = totalIncome - totalExpenses;

    final monthsCovered = _calculateCoveredMonths(records);
    final monthlyProjection =
        monthsCovered == 0 ? netProfit : netProfit / monthsCovered;

    final sortedByDate = [...records]..sort(
        (a, b) => a.period.compareTo(b.period),
      );
    final recentHalf = sortedByDate.skip((records.length / 2).floor()).toList();
    final previousHalf =
        sortedByDate.take((records.length / 2).floor()).toList();

    final recentProfit = recentHalf.fold<double>(
      0,
      (sum, record) => sum + record.profit,
    );
    final previousProfit = previousHalf.fold<double>(
      0,
      (sum, record) => sum + record.profit,
    );

    final trendPercentage = previousProfit == 0
        ? 100.0
        : ((recentProfit - previousProfit) / previousProfit) * 100;

    return FinancialMetrics(
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      netProfit: netProfit,
      monthlyProjection: monthlyProjection,
      trendPercentage: trendPercentage.isNaN ? 0.0 : trendPercentage,
    );
  }

  static int _calculateCoveredMonths(List<FinancialRecord> records) {
    final months = records
        .map((record) => DateTime(record.period.year, record.period.month))
        .toSet();
    return months.length;
  }
}

