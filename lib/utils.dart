const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _weekdaysLong = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
];
const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];
const _monthsLong = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

/// Fixed booking fee (baht) and VAT rate used on the review screen.
const bookingFee = 15.0;
const vatRate = 0.07;

DateTime today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

DateTime addDays(DateTime d, int days) =>
    DateTime(d.year, d.month, d.day + days);

DateTime nextSaturday() {
  var d = addDays(today(), 1);
  while (d.weekday != DateTime.saturday) {
    d = addDays(d, 1);
  }
  return d;
}

bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String formatDay(DateTime d) =>
    '${_weekdays[d.weekday - 1]}, ${d.day} ${_months[d.month - 1]}';

String formatFullDate(DateTime d) => '${formatDay(d)} ${d.year}';

String formatLongDate(DateTime d) =>
    '${_weekdaysLong[d.weekday - 1]}, ${d.day} ${_monthsLong[d.month - 1]} ${d.year}';

String formatBadgeDate(DateTime d) =>
    '${_weekdays[d.weekday - 1].toUpperCase()}, ${d.day} ${_months[d.month - 1].toUpperCase()}';

String formatDayMonth(DateTime d) => '${d.day} ${_months[d.month - 1]}';

String baht(double v) => '฿${v.toStringAsFixed(0)}';

String money(double v) => '฿${v.toStringAsFixed(2)}';

double vatFor(double price) => (price + bookingFee) * vatRate;

double totalFor(double price) => price + bookingFee + vatFor(price);

String cleanError(Object e) => e.toString().replaceFirst('Exception: ', '');
