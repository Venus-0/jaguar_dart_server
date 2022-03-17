import 'dart:async';
import 'dart:io';

import 'package:jaguar/jaguar.dart';

import '../db/sessionDao.dart';
import '../db/userDao.dart';
import '../model/response.dart';
import '../model/user_bean.dart';
import '../server.dart';

class Login {
  static FutureOr<Response> login(Context ctx) async {
    ResponseBean responseBean = ResponseBean();
    String account = "";
    String pwd = "";
    if (ctx.method == Server.GET) {
      account = ctx.query.get("account") ?? "";
      pwd = ctx.query.get("pwd") ?? "";
    } else if (ctx.method == Server.POST) {
      final res = await ctx.bodyAsUrlEncodedForm();
      print(res);
      account = res['account'] ?? '';
      pwd = res['pwd'] ?? '';
    }
    print(account);
    print(pwd);
    if (account.isEmpty) {
      responseBean.code = Server.ERROR;
      responseBean.msg = "账号不能为空";
      return Response(statusCode: responseBean.code, body: responseBean.toJsonString());
    }
    if (pwd.isEmpty) {
      responseBean.code = Server.ERROR;
      responseBean.msg = "密码不能为空";
      return Response(statusCode: responseBean.code, body: responseBean.toJsonString());
    }

    User? user = await UserDao().queryUser(account);
    if (user == null) {
      responseBean.code = Server.ERROR;
      responseBean.msg = "账户或密码错误";
      return Response(statusCode: responseBean.code, body: responseBean.toJsonString());
    } else {
      if (user.password != pwd) {
        responseBean.code = Server.ERROR;
        responseBean.msg = "账户或密码错误";
        return Response(statusCode: responseBean.code, body: responseBean.toJsonString());
      } else {
        String session = await SessionDao().loginSession(account, pwd);
        responseBean.result = {'user': session};
        responseBean.msg = "登陆成功";
        return Response(statusCode: responseBean.code, body: responseBean.toJsonString(), headers: {"Set-Cookie": "user=$session"});
      }
    }
  }
}
