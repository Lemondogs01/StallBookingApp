import 'package:intl/intl.dart';

final _money = NumberFormat('#,##0');
final _date = DateFormat('d MMM yyyy');
final _dateTime = DateFormat('d MMM yyyy, HH:mm');

String baht(num value) => '฿${_money.format(value)}';
String fmtDate(DateTime d) => _date.format(d);
String fmtDateTime(DateTime d) => _dateTime.format(d);
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

String bookingCode(int id) => 'BK-${id.toString().padLeft(4, '0')}';

/// PromptPay ID is a 10-digit phone number or a 13-digit national ID.
String formatPromptPayId(String id) {
  if (id.length == 10) {
    return '${id.substring(0, 3)}-${id.substring(3, 6)}-${id.substring(6)}';
  }
  if (id.length == 13) {
    return '${id[0]}-${id.substring(1, 5)}-${id.substring(5, 10)}-'
        '${id.substring(10, 12)}-${id[12]}';
  }
  return id;
}
