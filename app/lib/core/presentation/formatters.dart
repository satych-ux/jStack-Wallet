import 'package:intl/intl.dart';

/// Display formatting shared by every screen. Money is only ever formatted
/// here, never computed (WIRING-TASKS "Money").
abstract final class Formatters {
  static final NumberFormat _rupees = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
  static final NumberFormat _plain = NumberFormat.currency(locale: 'en_IN', symbol: '', decimalDigits: 2);
  static final DateFormat _shortDate = DateFormat('d MMM');
  static final DateFormat _dateTime = DateFormat('d MMM y, HH:mm');

  /// `23950` → `₹23,950.00`.
  static String rupees(double amount) => _rupees.format(amount);

  /// `1500` → `1,500.00` (the row adds its own sign and symbol).
  static String amount(double amount) => _plain.format(amount).trim();

  /// The backend sends UTC; people read local time. `20 Oct`.
  static String shortDate(DateTime at) => _shortDate.format(at.toLocal());

  /// `20 Oct 2026, 16:04`, local time.
  static String dateTime(DateTime at) => _dateTime.format(at.toLocal());

  /// `Aditi Verma` → `AV`; at most two letters.
  static String initials(String name) => name
      .split(' ')
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part[0].toUpperCase())
      .join();
}
