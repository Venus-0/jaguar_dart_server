import 'dart:async';

import 'package:jaguar/http/context/context.dart';
import 'package:jaguar/http/request/request.dart';
import 'package:jaguar/http/response/response.dart';

import '../db/global_dao.dart';
import '../model/user_bean.dart';
import '../server.dart';
import '../model/token_model.dart';

abstract class BaseApi {
  final Context ctx;
  BaseApi(this.ctx);

  FutureOr<Response> method(String method); //方法索引基类

  Future<Token?> _getToken() async {
    String _token = ctx.headers.value("user") ?? "";
    print("getToken:$_token");
    if (_token.isEmpty) {
      return null;
    }
    GlobalDao _tokenDao = GlobalDao("token");
    Map<String, dynamic> _tokenRecord = await _tokenDao.getOne(where: [Where("token", _token)]);
    if (_tokenRecord.isNotEmpty) {
      return Token.fromJson(_tokenRecord);
    }
  }

  Future<bool> validateToken() async {
    Token? _token = await _getToken();
    if (_token == null) return false;
    return _token.tokenIsAvailable();
  }

  ///根据token获取用户信息
  Future<UserModel?> getTokenUser() async {
    Token? _token = await _getToken();
    if ((_token?.user_id ?? 0) == 0) {
      return null;
    }
    GlobalDao _userDao = GlobalDao("user");

    Map<String, dynamic> _userJson = await _userDao.getOne(where: [Where("user_id", _token!.user_id)]);

    if (_userJson.isEmpty) return null;
    return UserModel.fromJson(_userJson);
  }

  ///获取参数基类
  Future<T> get<T>(String key) async {
    var value;
    if (ctx.method == Server.GET) {
      value = ctx.query.get(key);
    } else if (ctx.method == Server.POST) {
      Map<String, dynamic> res = {};
      if (ctx.isFormData) {
        Map<String, FormField<dynamic>> formData = await ctx.bodyAsFormData();
        formData.forEach((key, value) {
          res[key] = value.value;
        });
      } else if (ctx.isJson) {
        res = await ctx.bodyAsJson();
      } else if (ctx.isUrlEncodedForm) {
        res = await ctx.bodyAsUrlEncodedForm();
      }
      print(res);
      value = res[key];
    }
    if (value == null) {
      if (T == String) {
        value = "";
      } else if (T == int) {
        value = 0;
      } else if (T == double) {
        value = 0.0;
      }
    } else {
      if (T == String) {
        value = value.toString();
      } else if (T == int) {
        value = int.tryParse(value.toString()) ?? 0;
      } else if (T == double) {
        value = double.tryParse(value.toString()) ?? 0.0;
      }
    }
    print("get type ${value.runtimeType} $T $value");
    return value as T;
  }
}
