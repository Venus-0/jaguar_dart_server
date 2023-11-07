import 'dart:convert';

class ResponseBean {
  int code = 200;
  String msg = '';
  Map<String, dynamic> result = {};
  ResponseBean({this.code = 200, this.msg = '', this.result = const {}});
  String toJsonString() {
    print(DateTime.now().toString() + "jsonData: ${{"code": code, "msg": msg, "result": result}}");
    return jsonEncode({"code": code, "msg": msg, "result": result});
  }
}
