import 'package:flutter_test/flutter_test.dart';
import 'package:j_stack_flutter_app/features/transfer/domain/validators/transfer_validators.dart';

// TST-02 / TRF-01..02: transfer form validation. Mirrors backend API-06.
void main() {
  group('validateAmount', () {
    const greaterThanZero = 'Enter an amount greater than zero';

    test('empty, zero, negative and non-numeric are rejected', () {
      for (final bad in [
        '',
        '   ',
        '0',
        '0.00',
        '-5',
        'abc',
        '1e3',
        '1,500',
        '.5',
        '5.',
      ]) {
        expect(validateAmount(bad), greaterThanZero, reason: bad);
      }
    });

    test('three or more decimal places are rejected', () {
      expect(validateAmount('10.123'), 'Use at most 2 decimal places');
      expect(validateAmount('0.001'), 'Use at most 2 decimal places');
    });

    test('positive amounts with up to two decimals pass', () {
      for (final ok in ['1', '0.01', '1500', '1500.5', '1500.50', ' 25 ']) {
        expect(validateAmount(ok), isNull, reason: ok);
      }
    });

    test('there is no balance check: that is the backend\'s verdict', () {
      expect(validateAmount('99999999'), isNull);
    });
  });

  group('validateBeneficiaryName', () {
    test('empty or blank is rejected', () {
      expect(validateBeneficiaryName(''), "Enter the beneficiary's name");
      expect(validateBeneficiaryName('  '), "Enter the beneficiary's name");
    });

    test('a name passes', () {
      expect(validateBeneficiaryName('Rahul Sharma'), isNull);
    });
  });

  group('validateMobile', () {
    const message = 'Enter a valid 10-digit mobile number';

    test('short, long, non-numeric or empty is rejected', () {
      for (final bad in [
        '',
        '987654321',
        '98765432101',
        '98765abcde',
        '98765 43210',
        '+919876543210',
      ]) {
        expect(validateMobile(bad), message, reason: bad);
      }
    });

    test('exactly ten digits passes, ignoring outer spaces', () {
      expect(validateMobile('9876543210'), isNull);
      expect(validateMobile(' 9876543210 '), isNull);
    });
  });

  group('validateRemarks', () {
    test('empty is valid: remarks are optional', () {
      expect(validateRemarks(''), isNull);
    });

    test('up to 100 characters passes; more is rejected', () {
      expect(validateRemarks('a' * 100), isNull);
      expect(validateRemarks('a' * 101), 'Keep remarks to 100 characters');
    });
  });
}
