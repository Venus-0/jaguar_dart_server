import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';
import 'package:jaguar/jaguar.dart';

import '../db/global_dao.dart';
import '../db/sessionDao.dart';
import '../model/mail_model.dart';
import '../model/response.dart';
import '../model/user_bean.dart';
import '../server.dart';
import '../utils/mail_utils.dart';
import 'base_api.dart';

class User extends BaseApi {
  User(Context ctx) : super(ctx);

  @override
  FutureOr<Response> method(String method) async {
    if (method == "login") return await _login();
    if (method == "register") return await _register();
    // if (method == "validateCode") return await _validateCode();

    return Response(body: jsonEncode({}), statusCode: Server.NOT_FOUND);
  }

  FutureOr<Response> _login() async {
    ResponseBean responseBean = ResponseBean();
    String email = "";
    String pwd = "";
    String device = "";
    email = await get<String>("email");
    pwd = await get<String>("pwd");
    device = await get<String>("device");

    if (device.isEmpty) {
      device = "Unknow";
    }

    if (email.isEmpty) {
      responseBean.code = Server.ERROR;
      responseBean.msg = "账号不能为空";
      return Response(statusCode: responseBean.code, body: responseBean.toJsonString());
    }
    if (pwd.isEmpty) {
      responseBean.code = Server.ERROR;
      responseBean.msg = "密码不能为空";
      return Response(statusCode: responseBean.code, body: responseBean.toJsonString());
    }

    pwd = md5.convert(pwd.codeUnits).toString();
    UserModel? user;
    GlobalDao _userDao = GlobalDao("user");

    Map<String, dynamic> _ret = await _userDao.getOne(where: [Where("email", email)]);
    if (_ret.isNotEmpty) {
      user = UserModel.fromJson(_ret);
    }

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
        String session = await SessionDao().loginSession(user.user_id, pwd, device);
        responseBean.result = {"user": user.toJson(), 'token': session};
        responseBean.msg = "登陆成功";
        return Response(statusCode: responseBean.code, body: responseBean.toJsonString(), headers: {"Set-Cookie": "userSession=$session"});
      }
    }
  }

  FutureOr<Response> _register() async {
    String username = await get<String>("username");
    String email = await get<String>("email");
    String password = await get<String>("password");
    GlobalDao _globalDao = GlobalDao("user");
    ResponseBean responseBean = ResponseBean();

    ///密码加密
    password = md5.convert(password.codeUnits).toString();
    UserModel _user = UserModel(username: username, email: email, password: password, avatar: "123");

    ///判断邮箱是否已经注册
    Map<String, dynamic> _checkUser = await _globalDao.getOne(where: [Where("email", email)]);
    if (_checkUser.isNotEmpty) {
      responseBean.code = Server.ERROR;
      responseBean.msg = "当前邮箱已注册";
      return Response(statusCode: responseBean.code, body: responseBean.toJsonString());
    }

    Map<String, dynamic> _userJson = _user.toJson();
    _userJson.remove("user_id");
    _userJson['create_time'] = DateFormat("yyyy-MM-dd").format(DateTime.now());
    _userJson['update_time'] = DateFormat("yyyy-MM-dd").format(DateTime.now());
    bool _ret = await _globalDao.insert(_userJson);
    if (_ret) {
      responseBean.result = {'user': jsonEncode(_user.toJson())};
      responseBean.msg = "注册成功";
      return Response(statusCode: responseBean.code, body: responseBean.toJsonString());
    } else {
      responseBean.code = Server.ERROR;
      responseBean.msg = "注册失败";
      return Response(statusCode: responseBean.code, body: responseBean.toJsonString());
    }
  }

  ///邮箱发送验证码
  ///
  ///跑不通
  FutureOr<Response> _validateCode() async {
    String email = await get<String>("email");

    GlobalDao _userDao = GlobalDao("user");
    Map<String, dynamic> _user = await _userDao.getOne(where: [Where("email", email)]);
    ResponseBean responseBean = ResponseBean();

    if (_user.isEmpty) {
      responseBean.code = Server.ERROR;
      responseBean.msg = "该邮箱未注册账号";
      return Response(statusCode: responseBean.code, body: responseBean.toJsonString());
    } else {
      MailSender _mailSender = MailSender();
      MailModel _mailModel = MailModel(address: email, subject: "这是一条测试", text: "这是一条测试右键", html: "<h1>测试测试</h1>");
      bool _ret = await _mailSender.sendMail(_mailModel);
      if (_ret) {
        responseBean.code = Server.SUCCESS;
        responseBean.msg = "发送成功";
        return Response(statusCode: responseBean.code, body: responseBean.toJsonString());
      } else {
        responseBean.code = Server.ERROR;
        responseBean.msg = "发送失败";
        return Response(statusCode: responseBean.code, body: responseBean.toJsonString());
      }
    }
  }
}
