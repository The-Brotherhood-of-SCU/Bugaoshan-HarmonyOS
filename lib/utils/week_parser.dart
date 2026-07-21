import 'package:bugaoshan/models/course.dart';

/// Parses a week description string from the academic affairs system
/// into (startWeek, endWeek, weekType).
///
/// zcsm formats:
///   "1-10周"      → (1, 10, every)
///   "1-10,12周"   → (1, 12, every)  (week 12 is standalone)
///   "1-16(单)"    → (1, 16, odd)
///   "第16周"      → (16, 16, every)
///   "1-16(双)"    → (1, 16, even)
(int startWeek, int endWeek, WeekType weekType) parseWeeks(String zcsm) {
  if (zcsm.isEmpty) return (1, 20, WeekType.every);
  final text = zcsm.replaceAll('周', '').trim();
  WeekType weekType = WeekType.every;
  if (text.contains('单')) weekType = WeekType.odd;
  if (text.contains('双')) weekType = WeekType.even;
  final numbers = text.replaceAll(RegExp(r'[^\d,\-]'), '');
  if (numbers.isEmpty) return (1, 20, weekType);
  final parts = numbers.split(',');
  int? minStart;
  int? maxEnd;
  for (final part in parts) {
    final range = part.split('-');
    if (range.length == 2) {
      final s = int.tryParse(range[0]);
      final e = int.tryParse(range[1]);
      if (s != null && e != null) {
        minStart = minStart == null ? s : (s < minStart ? s : minStart);
        maxEnd = maxEnd == null ? e : (e > maxEnd ? e : maxEnd);
      }
    } else if (range.length == 1) {
      final w = int.tryParse(range[0]);
      if (w != null) {
        minStart = minStart == null ? w : (w < minStart ? w : minStart);
        maxEnd = maxEnd == null ? w : (w > maxEnd ? w : maxEnd);
      }
    }
  }
  return (minStart ?? 1, maxEnd ?? 20, weekType);
}
