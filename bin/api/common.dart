import 'dart:async';
import 'dart:convert';

import 'package:jaguar/jaguar.dart';
import 'package:mysql1/mysql1.dart';

import '../db/global_dao.dart';
import '../db/mysql.dart';
import '../db/sessionDao.dart';
import '../model/response.dart';
import '../model/user_bean.dart';
import '../server.dart';
import 'base_api.dart';

class Common extends BaseApi {
  Common(Context ctx) : super(ctx);

  @override
  FutureOr<Response> method(String method) async {
    if (method == "test") return await serverTest();
    if (method == "checkLogin") return await checkLogin();
    return Response(body: jsonEncode({}), statusCode: Server.NOT_FOUND);
  }

  FutureOr<Response> serverTest() async {
    UserModel? _user = await getTokenUser();

    if (_user != null) {
      print(_user.toJson());
    } else {
      print("---NULL---");
    }

    ResponseBean responseBean = ResponseBean();

    MySqlConnection? conn = await Mysql.getDB();
    responseBean.msg = "114514";
    return Response(statusCode: responseBean.code, body: responseBean.toJsonString());
  }

  FutureOr<Response> checkLogin() async {
    ResponseBean responseBean = ResponseBean();
    if (await validateToken()) {
      UserModel? _user = await getTokenUser();
      if (_user != null) {
        responseBean.code = Server.SUCCESS;
        responseBean.msg = "OK";
        responseBean.result = {"user": _user.toJson()};
        return Response(statusCode: responseBean.code, body: responseBean.toJsonString());
      } else {
        responseBean.code = Server.TOKEN_EXPIRED;
        responseBean.msg = "验证过期";
        return Response(statusCode: responseBean.code, body: responseBean.toJsonString());
      }
    } else {
      responseBean.code = Server.TOKEN_EXPIRED;
      responseBean.msg = "验证过期";
      return Response(statusCode: responseBean.code, body: responseBean.toJsonString());
    }
  }
}
