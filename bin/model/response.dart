import 'dart:convert';

import '../server.dart';

class ResponseBean {
  int code = Server.SUCCESS;
  String msg = '';
  Map<String, dynamic> result = {};
  ResponseBean({this.code = Server.SUCCESS, this.msg = '', this.result = const {}});
  String toJsonString() => jsonEncode({"code": code, "msg": msg, "result": result});
}
