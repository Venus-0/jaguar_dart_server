import 'dart:convert';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';

class DataUtils {
  static String generate_MD5(String data) {
    var content = new Utf8Encoder().convert(data);
    var digest = md5.convert(content);
    return hex.encode(digest.bytes);
  }

  static DateTime formatDateTime(DateTime time) {
    return DateTime(time.year, time.month, time.day, time.hour, time.minute, time.second);
  }
}
