/// Send-money form checks (TRF-01, TRF-02). They mirror the backend's
/// API-06 rules so the user sees the problem before a round trip.
///
/// There is deliberately no balance check: whether the wallet can afford
/// the transfer is the backend's verdict (409), not the app's (TRF-08).
library;

/// Digits, optionally a dot and more digits. No sign, commas or exponent.
final RegExp _plainNumber = RegExp(r'^\d+(\.\d+)?$');

/// The same, with at most two digits after the dot.
final RegExp _twoDecimals = RegExp(r'^\d+(\.\d{1,2})?$');

final RegExp _tenDigits = RegExp(r'^\d{10}$');

const int remarksMaxLength = 100;

String? validateAmount(String value) {
  final text = value.trim();
  final amount = double.tryParse(text);
  if (amount == null || amount <= 0 || !_plainNumber.hasMatch(text)) {
    return 'Enter an amount greater than zero';
  }
  if (!_twoDecimals.hasMatch(text)) return 'Use at most 2 decimal places';
  return null;
}

String? validateBeneficiaryName(String value) {
  if (value.trim().isEmpty) return "Enter the beneficiary's name";
  return null;
}

String? validateMobile(String value) {
  if (!_tenDigits.hasMatch(value.trim())) {
    return 'Enter a valid 10-digit mobile number';
  }
  return null;
}

/// Optional, so empty is fine.
String? validateRemarks(String value) {
  if (value.trim().length > remarksMaxLength) {
    return 'Keep remarks to $remarksMaxLength characters';
  }
  return null;
}
