class ProgressMetric {
  final String subject;
  final double completion; // 0..1
  final double weeklyDelta; // разница с прошлой неделей

  const ProgressMetric({
    required this.subject,
    required this.completion,
    required this.weeklyDelta,
  });

  String get trendLabel {
    if (weeklyDelta == 0) return 'без изменений';
    return weeklyDelta > 0 ? '+${(weeklyDelta * 100).toStringAsFixed(1)}%' : '${(weeklyDelta * 100).toStringAsFixed(1)}%';
  }
}

