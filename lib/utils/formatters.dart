import 'package:intl/intl.dart';

class AppFormatters {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: 'MAD ',
    decimalDigits: 2,
  );

  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');

  static String currency(double amount) => _currencyFormat.format(amount);

  static String date(DateTime dt) => _dateFormat.format(dt);

  static String dateTime(DateTime dt) => _dateTimeFormat.format(dt);

  static String percentage(double value, double total) {
    if (total == 0) return '0%';
    return '${((value / total) * 100).toStringAsFixed(1)}%';
  }
}
