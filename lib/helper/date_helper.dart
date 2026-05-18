class DateHelper {
  /// Parse datetime API yang dianggap WIB (UTC+7)
  /// contoh input: "2026-05-05 14:00:00"
  ///
  /// Return:
  /// DateTime lokal device user
  ///
  /// Contoh:
  /// WIB 14:00
  /// User WIT -> jadi 16:00
  static DateTime parseWibToLocal(String date) {
    return parseWibToUtc(date).toLocal();
  }

  /// Parse WIB -> UTC
  static DateTime parseWibToUtc(String date) {

    // paksa parse sebagai UTC netral
    final parsed = DateTime.parse("${date}Z");

    // karena source sebenarnya WIB,
    // convert WIB -> UTC
    return parsed.subtract(const Duration(hours: 7));
  }

  /// Apakah waktu sekarang sudah lewat
  static bool isExpiredWib(String date) {
    final targetUtc = parseWibToUtc(date);

    return DateTime.now().toUtc().isAfter(targetUtc);
  }

  /// Apakah sekarang masih sebelum target
  static bool isBeforeWib(String date) {
    final targetUtc = parseWibToUtc(date);

    return DateTime.now().toUtc().isBefore(targetUtc);
  }

  /// Sisa waktu menuju target
  static Duration remainingWib(String date) {
    final targetUtc = parseWibToUtc(date);

    return targetUtc.difference(DateTime.now().toUtc());
  }
}