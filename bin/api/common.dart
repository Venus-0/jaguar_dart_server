import 'dart:async';

import 'package:jaguar/jaguar.dart';

import '../model/response.dart';

class Common {
  static FutureOr<Response> serverTest(Context ctx) {
    ResponseBean responseBean = ResponseBean();
    responseBean.msg = "114514";
    return Response(statusCode: responseBean.code, body: responseBean.toJsonString());
  }
}
