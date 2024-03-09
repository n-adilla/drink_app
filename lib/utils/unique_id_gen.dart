import 'package:intl/intl.dart';

String generateShortUniqueId() {
  DateTime now = DateTime.now();
  String formattedDate = DateFormat('yyyyMMddHHmmss').format(now);
  return encodeShortId(formattedDate);
}

String encodeShortId(String input) {
  const characters = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  const base = characters.length;
  int value = int.parse(input);

  String encoded = '';
  while (value > 0) {
    int remainder = value % base;
    encoded = characters[remainder] + encoded;
    value = (value / base).floor();
  }
  return encoded;
}
