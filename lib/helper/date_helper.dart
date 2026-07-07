class DateHelper {
  static DateTime parseWibToLocal(String date) {
    return parseWibToUtc(date).toLocal();
  }
  
  static DateTime parseWibToUtc(String date) {
    final parsed = DateTime.parse("${date}Z");
    return parsed.subtract(const Duration(hours: 7));
  }
  
  static bool isExpiredWib(String date) {
    final targetUtc = parseWibToUtc(date);
    return DateTime.now().toUtc().isAfter(targetUtc);
  }
  
  static bool isBeforeWib(String date) {
    final targetUtc = parseWibToUtc(date);
    return DateTime.now().toUtc().isBefore(targetUtc);
  }
  
  static Duration remainingWib(String date) {
    final targetUtc = parseWibToUtc(date);
    return targetUtc.difference(DateTime.now().toUtc());
  }
}