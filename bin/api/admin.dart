import 'package:crypto/crypto.dart';
import 'package:jaguar/http/context/context.dart';
import 'package:jaguar/http/response/response.dart';

import 'dart:async';

import '../db/global_dao.dart';
import '../db/sessionDao.dart';
import '../model/admin_user_model.dart';
import '../model/bbs_model.dart';
import '../model/comment_model.dart';
import '../model/user_model.dart';
import 'base_api.dart';

class Admin extends BaseApi {
  Admin(Context ctx) : super(ctx);

  @override
  FutureOr<Response> method(String method) {
    if (method == 'loginAdmin') return _loginAdmin(); //登录
    if (method == 'checkLogin') return _checkLogin(); //检查登陆状态
    if (method == 'getTotalUser') return _getTotalUser(); //获取用户总数
    if (method == 'getTotalPosts') return _getTotalPosts(); //获取帖子总数
    if (method == 'getUserList') return _getUserList(); //获取用户列表
    if (method == 'getUserPosts') return _getUserPosts(); //获取用户发帖列表
    if (method == 'getUserComment') return _getUserComment(); //获取用户评论列表
    if (method == 'getPostList') return _getPostList(); //获取帖子列表
    return pageNotFound;
  }

  ///检查登陆状态
  FutureOr<Response> _checkLogin() async {
    if (!(await validateToken())) return tokenExpired;
    AdminUserModel? _admin = await getTokenAdmin();
    if (_admin != null) {
      return packData(SUCCESS, {"user": _admin.toJson()}, 'OK');
    } else {
      return tokenExpired;
    }
  }

  ///登录
  FutureOr<Response> _loginAdmin() async {
    String _id = await get<String>("id");
    String _pwd = await get<String>("pwd");
    _pwd = md5.convert(_pwd.codeUnits).toString();

    GlobalDao _adminDao = GlobalDao("admin_user");
    Map<String, dynamic> _ret = await _adminDao.getOne(where: [Where("name", _id)]);
    if (_ret.isEmpty || _ret['password'] != _pwd) {
      return packData(ERROR, {}, "用户名或密码错误");
    }
    String _session = await SessionDao().loginSession(_ret['admin_id'], _pwd, "web_admin");
    return packData(SUCCESS, {"user": AdminUserModel.fromJson(_ret).toJson(), "token": _session}, "登陆成功");
  }

  ///获取用户数量
  FutureOr<Response> _getTotalUser() async {
    if (!(await validateToken())) return tokenExpired;
    GlobalDao _userDao = GlobalDao("user");
    Map<String, dynamic> _ret = await _userDao.getOne(column: ["COUNT(*)"], where: [Where("disable_time", null, "IS")]);
    return packData(SUCCESS, {"count": _ret["COUNT(*)"] ?? 0}, "获取用户数量成功");
  }

  ///获取帖子/文章/问答总数
  FutureOr<Response> _getTotalPosts() async {
    if (!(await validateToken())) return tokenExpired;
    int _type = await get<int>("type");
    GlobalDao _postsDao = GlobalDao("posts");
    Map<String, dynamic> _ret =
        await _postsDao.getOne(column: ["COUNT(*)"], where: [Where("question_type", _type), Where("delete_time", null, "IS")]);
    return packData(SUCCESS, {"count": _ret["COUNT(*)"] ?? 0}, "获取帖子数量成功");
  }

  ///获取用户列表
  ///支持用户名，邮箱模糊搜索
  FutureOr<Response> _getUserList() async {
    if (!(await validateToken())) return tokenExpired;
    int _page = await get<int>("page");
    int _pageSize = await get<int>("pageSize");
    String _email = await get<String>("email");
    String _userName = await get<String>("username");
    GlobalDao _userDao = GlobalDao("user");
    if (_page < 1) {
      _page = 1;
    }

    if (_pageSize == 0) {
      _pageSize = 10;
    }

    List<Where> _where = [];

    if (_email.isNotEmpty) {
      _where.add(Where("email", "%$_email%", "LIKE"));
    }
    if (_userName.isNotEmpty) {
      _where.add(Where("username", "%$_userName%", "LIKE"));
    }

    Map<String, dynamic> _count = await _userDao.getOne(column: ["COUNT(*)"], where: _where);
    List<Map<String, dynamic>> _ret =
        await _userDao.getList(limit: Limit(limit: _pageSize, start: _page - 1), where: _where, order: "update_time DESC");

    int _totalPage = (((_count['COUNT(*)'] ?? 0) as int) / _pageSize).ceil();
    Map<String, dynamic> _pageInfo = {
      "total": _totalPage,
      "currentPage": _page,
      "pageSize": _pageSize,
    };

    Map<String, dynamic> _data = {};

    _data['data'] = List.generate(_ret.length, (index) => UserModel.fromJson(_ret[index]).toJson());
    _data['page'] = _pageInfo;

    return packData(SUCCESS, _data, "获取用户列表成功");
  }

  ///获取用户发帖列表
  FutureOr<Response> _getUserPosts() async {
    if (!(await validateToken())) return tokenExpired;
    String _userId = await get<String>("user_id");

    int _page = await get<int>("page");
    int _pageSize = await get<int>("pageSize");

    if (_page < 1) {
      _page = 1;
    }

    if (_pageSize == 0) {
      _pageSize = 10;
    }

    GlobalDao _postsDao = GlobalDao("posts");
    Map<String, dynamic> _count = await _postsDao.getOne(column: ["COUNT(*)"], where: [Where("user_id", _userId)]);

    List<Map<String, dynamic>> _list = await _postsDao
        .getList(where: [Where("user_id", _userId)], order: "create_time DESC", limit: Limit(limit: _pageSize, start: _page - 1));

    int _totalPage = (((_count['COUNT(*)'] ?? 0) as int) / _pageSize).ceil();
    Map<String, dynamic> _pageInfo = {
      "total": _totalPage,
      "currentPage": _page,
      "pageSize": _pageSize,
    };

    Map<String, dynamic> _data = {};

    _data['data'] = List.generate(_list.length, (index) => BBSModel.fromJson(_list[index]).toJson());
    _data['page'] = _pageInfo;

    return packData(SUCCESS, _data, "获取用户帖子列表成功");
  }

  ///获取用户评论列表
  FutureOr<Response> _getUserComment() async {
    if (!(await validateToken())) return tokenExpired;
    String _userId = await get<String>("user_id");

    int _page = await get<int>("page");
    int _pageSize = await get<int>("pageSize");

    if (_page < 1) {
      _page = 1;
    }

    if (_pageSize == 0) {
      _pageSize = 10;
    }

    GlobalDao _commentDao = GlobalDao("commnet");
    Map<String, dynamic> _count = await _commentDao.getOne(column: ["COUNT(*)"], where: [Where("user_id", _userId)]);

    List<Map<String, dynamic>> _list = await _commentDao
        .getList(where: [Where("user_id", _userId)], order: "create_time DESC", limit: Limit(limit: _pageSize, start: _page - 1));

    int _totalPage = (((_count['COUNT(*)'] ?? 0) as int) / _pageSize).ceil();
    Map<String, dynamic> _pageInfo = {
      "total": _totalPage,
      "currentPage": _page,
      "pageSize": _pageSize,
    };

    Map<String, dynamic> _data = {};

    _data['data'] = List.generate(_list.length, (index) => CommentModel.fromJson(_list[index]).toJson());
    _data['page'] = _pageInfo;

    return packData(SUCCESS, _data, "获取用户评论列表成功");
  }

  ///
  FutureOr<Response> _getPostList() async {
    if (!(await validateToken())) return tokenExpired;
    int _type = await get<int>("type");
    int _page = await get<int>("page");
    int _pageSize = await get<int>("pageSize");
    if (!BBSModel.TYPE_LIST.contains(_type)) {
      _type = 0;
    }
    if (_page < 1) {
      _page = 1;
    }

    if (_pageSize == 0) {
      _pageSize = 10;
    }

    List<Where> _where = [];

    if (_type != 0) {
      _where.add(Where("question_type", _type));
    }

    GlobalDao _bbsDao = GlobalDao("posts");

    Map<String, dynamic> _count = await _bbsDao.getOne(column: ["COUNT(*)"], where: _where);
    List<Map<String, dynamic>> _list =
        await _bbsDao.getList(where: _where, order: "create_time DESC", limit: Limit(limit: _pageSize, start: _page - 1));
    int _totalPage = (((_count['COUNT(*)'] ?? 0) as int) / _pageSize).ceil();
    Map<String, dynamic> _pageInfo = {
      "total": _totalPage,
      "currentPage": _page,
      "pageSize": _pageSize,
    };

    Map<String, dynamic> _data = {};

    _data['data'] = List.generate(_list.length, (index) => BBSModel.fromJson(_list[index]).toJson());
    _data['page'] = _pageInfo;

    return packData(SUCCESS, _data, "获取帖子列表成功");
  }
}
