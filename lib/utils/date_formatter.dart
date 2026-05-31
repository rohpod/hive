import 'package:intl/intl.dart';

class DateFormatter {
  static String format(DateTime? date) {
    if (date == null) return 'TBD';
    
    final month = DateFormat('MMM').format(date);
    final year = DateFormat('yyyy').format(date);
    final day = date.day;
    
    String suffix = 'th';
    if (day % 10 == 1 && day != 11) {
      suffix = 'st';
    } else if (day % 10 == 2 && day != 12) {
      suffix = 'nd';
    } else if (day % 10 == 3 && day != 13) {
      suffix = 'rd';
    }

    return '${day}${suffix} ${month}, ${year}';
  }
}
