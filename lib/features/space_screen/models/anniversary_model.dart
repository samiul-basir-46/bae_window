class AnniversaryModel {
  final DateTime? anniversaryDate;

  const AnniversaryModel({
    this.anniversaryDate,
  });

  int get daysLeft {
    if (anniversaryDate == null) return 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var target = DateTime(today.year, anniversaryDate!.month, anniversaryDate!.day);
    if (target.isBefore(today)) {
      target = DateTime(today.year + 1, anniversaryDate!.month, anniversaryDate!.day);
    }
    return target.difference(today).inDays;
  }
}
