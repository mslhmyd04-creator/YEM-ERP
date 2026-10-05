/// Phase 0 monetary precision: two decimal places, exact integer minor units.
/// This value never converts financial input through double.
class Money {
  Money(this.minor) {
    if (minor < 0 || minor > maximumMinor) { throw ArgumentError('Amount outside supported range.'); }
  }
  static const maximumMinor = 9000000000000000;
  final int minor;

  factory Money.parse(String input) {
    var text = input.trim();
    const arabic = '٠١٢٣٤٥٦٧٨٩';
    for (var i = 0; i < 10; i++) { text = text.replaceAll(arabic[i], '$i'); }
    text = text.replaceAll('٫', '.');
    if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(text)) { throw const FormatException('Use a nonnegative amount with at most two decimal places.'); }
    final parts = text.split('.');
    final value = BigInt.parse(parts.first) * BigInt.from(100) +
      BigInt.parse(parts.length == 1 ? '0' : parts.last.padRight(2, '0'));
    if (value > BigInt.from(maximumMinor)) { throw const FormatException('Amount exceeds supported range.'); }
    return Money(value.toInt());
  }
  @override
  String toString() => '${minor ~/ 100}.${(minor % 100).toString().padLeft(2, '0')}';
}
