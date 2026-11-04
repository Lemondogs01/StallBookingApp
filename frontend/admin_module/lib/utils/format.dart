import 'package:intl/intl.dart';

final _money = NumberFormat('#,##0');
final _date = DateFormat('d MMM yyyy');

String baht(num value) => '฿${_money.format(value)}';
String fmtDate(DateTime d) => _date.format(d);
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
