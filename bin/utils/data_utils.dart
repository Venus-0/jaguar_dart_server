import 'dart:convert';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:mysql1/mysql1.dart';

class DataUtils {
  static String generate_MD5(String data) {
    var content = new Utf8Encoder().convert(data);
    var digest = md5.convert(content);
    return hex.encode(digest.bytes);
  }

  static DateTime formatDateTime(DateTime time) {
    return DateTime(time.year, time.month, time.day, time.hour, time.minute, time.second);
  }

  static String blobTobase64(Blob blob) => base64Encode(blob.toBytes());

  static Blob base64ToBlob(String str) => Blob.fromBytes(base64Decode(str.split(",").last));

  static Uint8List blobToUnit8List(Blob blob) => Uint8List.fromList(blob.toBytes());
}
