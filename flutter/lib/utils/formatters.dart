import 'package:intl/intl.dart';

final NumberFormat currencyFormat =
    NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

String formatCurrency(double value) {
  return currencyFormat.format(value);
}

String formatShortDate(DateTime date) {
  return DateFormat('MMM d, hh:mm a').format(date);
}
