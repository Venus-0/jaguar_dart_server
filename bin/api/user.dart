import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';
import 'package:jaguar/jaguar.dart';
import '../db/global_dao.dart';
import '../db/sessionDao.dart';
import '../model/bbs_model.dart';
import '../model/like_model.dart';
import '../model/mail_model.dart';
import '../model/response.dart';
import '../model/subscribe_model.dart';
import '../model/user_model.dart';
import '../utils/data_utils.dart';
import '../utils/mail_utils.dart';
import 'base_api.dart';

class User extends BaseApi {
  User(Context ctx) : super(ctx);

  @override
  FutureOr<Response> method(String method) async {
    if (method == "login") return _login(); //登录
    if (method == "register") return _register(); //注册
    if (method == "validateCode") return await _validateCode();
    if (method == "updateUserInfo") return _updateUserInfo(); //修改用户信息
    if (method == "editPassword") return _editPassword(); //修改密码
    if (method == "getUserDetail") return _getUserDetail(); //获取指定用户信息
    if (method == "getSubscribeList") return _getSubscribeList(); //获取关注列表
    if (method == "getLikeList") return _getLikeList(); //获取喜欢列表
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

    ///密码加密
    password = md5.convert(password.codeUnits).toString();
    UserModel _user = UserModel(username: username, email: email, password: password);

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

    if (_user.isNotEmpty) {
      responseBean.code = ERROR;
      responseBean.msg = "该邮箱已注册";
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

  ///更新用户信息
  FutureOr<Response> _updateUserInfo() async {
    if (!(await validateToken())) return tokenExpired;
    String _userName = await get("username"); //用户名
    String _avatar = await get("avatar"); //头像
    UserModel? _user = await getTokenUser();
    if (_user == null) return userNotFind;

    final _userDao = GlobalDao("user");
    Map<String, dynamic> _modify = {};

    if (_userName.isNotEmpty) {
      _modify['username'] = _userName;
    }
    if (_avatar.isNotEmpty) {
      _modify['avatar'] = DataUtils.base64ToBlob(_avatar);
    }

    if (_modify.isEmpty) return packData(SUCCESS, null, "没什么需要修改的");
    _modify['update_time'] = DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now());
    bool _ret = await _userDao.update(_modify, where: [Where('user_id', _user.user_id)]);
    if (_ret) {
      return packData(SUCCESS, null, "OK");
    } else {
      return packData(ERROR, null, "修改失败");
    }
  }

  ///修改密码
  FutureOr<Response> _editPassword() async {
    if (!(await validateToken())) return tokenExpired;
    UserModel? _user = await getTokenUser();
    if (_user == null) return userNotFind;
    String _oldPwd = await get("oldPwd"); //旧密码
    String _newPwd = await get("newPwd"); //新密码
    String _twoPwd = await get("twoPwd"); //旧密码
    _oldPwd = md5.convert(_oldPwd.codeUnits).toString();
    _newPwd = md5.convert(_newPwd.codeUnits).toString();
    _twoPwd = md5.convert(_twoPwd.codeUnits).toString();

    if (_oldPwd != _user.password) return packData(ERROR, null, "旧密码不正确");
    if (_oldPwd == _newPwd) return packData(ERROR, null, "新旧密码不能一致");
    if (_newPwd != _twoPwd) return packData(ERROR, null, "两次密码不一致");

    final _userDao = GlobalDao("user");
    Map<String, dynamic> _modify = {
      "password": _newPwd,
      "update_time": DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now()),
    };

    bool _ret = await _userDao.update(_modify, where: [Where("user_id", _user.user_id)]);
    if (_ret) {
      return packData(SUCCESS, null, "OK");
    } else {
      return packData(ERROR, null, "修改失败");
    }
  }

  ///获取指定用户的信息，发帖情况
  FutureOr<Response> _getUserDetail() async {
    if (!(await validateToken())) return tokenExpired;
    UserModel? _currentUser = await getTokenUser();
    if (_currentUser == null) return userNotFind;
    int _userId = await get<int>("user_id");

    ///用户信息
    final _userDao = GlobalDao('user');
    Map<String, dynamic> _userJson = await _userDao.getOne(where: [Where("user_id", _userId)]);
    if (_userJson.isEmpty) return packData(ERROR, null, "查无此人");
    UserModel _user = UserModel.fromJson(_userJson);

    ///关注数量
    final _subDao = GlobalDao('subscribe');
    Map<String, dynamic> _subPostCountRet = await _subDao.getOne(column: [
      'COUNT(*)'
    ], where: [
      Where("user_id", _userId),
      Where("subscribe_type", SubscribeModel.TYPE_USER),
      Where("delete_time", null, "IS"),
    ]);

    int _subPostCount = _subPostCountRet['COUNT(*)'] ?? 0;

    ///粉丝
    Map<String, dynamic> _subUserCountRet = await _subDao.getOne(column: [
      'COUNT(*)'
    ], where: [
      Where("subscribe_id", _userId),
      Where("subscribe_type", SubscribeModel.TYPE_USER),
      Where("delete_time", null, "IS"),
    ]);

    int _subUserCount = _subUserCountRet['COUNT(*)'] ?? 0;

    ///当前用户是否关注
    Map<String, dynamic> _isSubscribe = await _subDao.getOne(where: [
      Where("user_id", _currentUser.user_id),
      Where("subscribe_id", _userId),
      Where("subscribe_type", SubscribeModel.TYPE_USER),
      Where("delete_time", null, "IS"),
    ]);

    ///发帖列表
    final _postDao = GlobalDao("posts");

    List<Map<String, dynamic>> _postJson =
        await _postDao.getList(where: [Where("user_id", _userId), Where("delete_time", null, "IS")], order: "last_reply_time DESC");

    Map<String, dynamic> _data = {};
    _data['user'] = _user.toJsonBasic(); //用户基本信息
    _data['subPostCount'] = _subPostCount; //用户关注人数
    _data['subUserCount'] = _subUserCount; //用户粉丝
    _data['isSubscribe'] = _isSubscribe.isNotEmpty; //是否关注该用户
    _data['posts'] = List.generate(_postJson.length, (index) => BBSModel.fromJson(_postJson[index]).toJson());

    return packData(SUCCESS, _data, "OK");
  }

  ///获取关注列表
  FutureOr<Response> _getSubscribeList() async {
    if (!(await validateToken())) return tokenExpired;
    int _userId = await get<int>("user_id");
    int _subType = await get<int>("type");
    int _start = await get<int>("start"); //从第几条数据开始加载
    int _size = await get<int>("size"); //每次获取多少条数据
    if (_subType == 0) {
      _subType = SubscribeModel.TYPE_USER;
    }
    if (_start < 0) {
      _start = 0;
    }
    if (_size == 0) {
      _size = 20;
    }

    final _subscribeDao = GlobalDao("subscribe");
    Map<String, dynamic> _count = await _subscribeDao.getOne(column: [
      'COUNT(*)'
    ], where: [
      Where("user_id", _userId),
      Where("subscribe_type", _subType),
      Where("delete_time", null, "IS"),
    ]);
    List<Map<String, dynamic>> _subUserList = await _subscribeDao.getList(column: [
      'user_id',
      'subscribe_id'
    ], where: [
      Where("user_id", _userId),
      Where("subscribe_type", _subType),
      Where("delete_time", null, "IS"),
    ], limit: Limit(limit: _size, start: _start));
    final _userDao = GlobalDao("user");
    List<Map<String, dynamic>> _subscribeUserList = [];
    for (final _sub in _subUserList) {
      Map<String, dynamic> _userJson = await _userDao.getOne(where: [Where('user_id', _sub['subscribe_id'])]);
      if (_userJson.isNotEmpty) {
        _subscribeUserList.add(UserModel.fromJson(_userJson).toJsonBasic());
      }
    }

    return packData(SUCCESS, {"list": _subscribeUserList, "total": _count['COUNT(*)'] ?? 0}, "OK");
  }

  ///获取点赞列表
  FutureOr<Response> _getLikeList() async {
    if (!(await validateToken())) return tokenExpired;
    int _userId = await get<int>("user_id");
    int _likeType = await get<int>("type");
    int _start = await get<int>("start"); //从第几条数据开始加载
    int _size = await get<int>("size"); //每次获取多少条数据
    if (_likeType == 0) {
      _likeType = LikeModel.TYPE_QUESTION;
    }
    if (_start < 0) {
      _start = 0;
    }
    if (_size == 0) {
      _size = 20;
    }
    final _likeDao = GlobalDao("like");
    Map<String, dynamic> _count = await _likeDao.getOne(column: [
      'COUNT(*)'
    ], where: [
      Where("up_type", _likeType),
      Where("user_id", _userId),
      Where("delete_time", null, "IS"),
    ]);
    List<Map<String, dynamic>> _likeJson = await _likeDao.getList(where: [
      Where("up_type", _likeType),
      Where("user_id", _userId),
      Where("delete_time", null, "IS"),
    ], limit: Limit(limit: _size, start: _start), order: "create_time DESC");
    List<Map<String, dynamic>> _list = [];
    for (final json in _likeJson) {
      _list.add(LikeModel.fromJson(json).toJson());
    }
    return packData(SUCCESS, {"list": _list, "total": _count['COUNT(*)'] ?? 0}, "OK");
  }
}
