import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';
import 'package:jaguar/jaguar.dart';

import '../db/global_dao.dart';
import '../db/sessionDao.dart';
import '../model/mail_model.dart';
import '../model/response.dart';
import '../model/user_model.dart';
import '../utils/mail_utils.dart';
import 'base_api.dart';

class User extends BaseApi {
  User(Context ctx) : super(ctx);

  @override
  FutureOr<Response> method(String method) async {
    if (method == "login") return await _login();
    if (method == "register") return await _register();
    // if (method == "validateCode") return await _validateCode();

    return Response(body: jsonEncode({}), statusCode: NOT_FOUND);
  }

  FutureOr<Response> _login() async {
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
      return packData(ERROR, null, '账号不能为空');
    }
    if (pwd.isEmpty) {
      return packData(ERROR, null, '密码不能为空');
    }

    pwd = md5.convert(pwd.codeUnits).toString();
    UserModel? user;
    GlobalDao _userDao = GlobalDao("user");

    Map<String, dynamic> _ret = await _userDao.getOne(where: [Where("email", email)]);
    if (_ret.isNotEmpty) {
      user = UserModel.fromJson(_ret);
    }

    if (user == null) {
      return packData(ERROR, null, '账户或密码错误');
    } else {
      if (user.password != pwd) {
        return packData(ERROR, null, '账户或密码错误');
      } else {
        String session = await SessionDao().loginSession(user.user_id, pwd, device);
        return packData(SUCCESS, {"user": user.toJson(), 'token': session}, '登陆成功');
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
      return packData(ERROR, null, '当前邮箱已注册');
    }

    Map<String, dynamic> _userJson = _user.toJson();
    _userJson.remove("user_id");
    _userJson['create_time'] = DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now());
    _userJson['update_time'] = DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now());
    bool _ret = await _globalDao.insert(_userJson);
    if (_ret) {
      return packData(SUCCESS, {'user': jsonEncode(_user.toJson())}, '注册成功');
    } else {
      return packData(ERROR, null, '注册失败');
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
      responseBean.code = ERROR;
      responseBean.msg = "该邮箱未注册账号";
      return Response(statusCode: responseBean.code, body: responseBean.toJsonString());
    } else {
      MailSender _mailSender = MailSender();
      MailModel _mailModel = MailModel(address: email, subject: "这是一条测试", text: "这是一条测试右键", html: "<h1>测试测试</h1>");
      bool _ret = await _mailSender.sendMail(_mailModel);
      if (_ret) {
        responseBean.code = SUCCESS;
        responseBean.msg = "发送成功";
        return Response(statusCode: responseBean.code, body: responseBean.toJsonString());
      } else {
        responseBean.code = ERROR;
        responseBean.msg = "发送失败";
        return Response(statusCode: responseBean.code, body: responseBean.toJsonString());
      }
    }
  }
}
