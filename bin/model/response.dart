import 'dart:convert';
class ResponseBean {
  int code = 200;
  String msg = '';
  Map<String, dynamic> result = {};
  ResponseBean({this.code = 200, this.msg = '', this.result = const {}});
  String toJsonString() => jsonEncode({"code": code, "msg": msg, "result": result});
}
