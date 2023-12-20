import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';
import 'package:jaguar/http/context/context.dart';
import 'package:jaguar/http/response/response.dart';
import 'package:mysql1/mysql1.dart';

import 'dart:async';

import '../conf/config.dart';
import '../db/global_dao.dart';
import '../db/sessionDao.dart';
import '../model/admin_user_model.dart';
import '../model/bbs_model.dart';
import '../model/comment_model.dart';
import '../model/notice_model.dart';
import '../model/user_model.dart';
import '../utils/data_utils.dart';
import 'base_api.dart';

class Admin extends BaseApi {
  Admin(Context ctx) : super(ctx);

  @override
  FutureOr<Response> method(String method) {
    if (method == 'loginAdmin') return _loginAdmin(); //登录
    if (method == 'checkLogin') return _checkLogin(); //检查登陆状态
    if (method == 'getTotalUser') return _getTotalUser(); //获取用户总数
    if (method == 'getTotalPosts') return _getTotalPosts(); //获取帖子总数
    if (method == 'getTotlaComment') return _getTotlaComment(); //获取评论总数
    if (method == 'getPostRank') return _getPostRank(); //获取发帖排行
    if (method == 'getCommentRank') return _getCommentRank(); //获取评论排行
    if (method == 'getPostLikeRank') return _getPostLikeRank(); //获取帖子点赞排行
    if (method == 'getCommentLikeRank') return _getCommentLikeRank(); //获取评论点赞排行
    if (method == 'setPostRecommand') return _setPostRecommand(); //设置推荐贴
    if (method == 'unsetPostRecommand') return _unsetPostRecommand(); //取消推荐贴
    if (method == 'setPostTop') return _setPostTop(); //设置精华贴
    if (method == 'unsetPostTop') return _unsetPostTop(); //取消精华贴
    if (method == 'deletePost') return _deletePost(); //删帖
    if (method == 'activePost') return _activePost(); //启用被删除的帖子
    if (method == 'getUserList') return _getUserList(); //获取用户列表
    if (method == 'getUserPosts') return _getUserPosts(); //获取用户发帖列表
    if (method == 'getUserComment') return _getUserComment(); //获取用户评论列表
    if (method == 'getPostList') return _getPostList(); //获取帖子列表
    if (method == 'banUser') return _banUser(); //封禁用户
    if (method == 'activeUser') return _activeUser(); //重新启用被封禁的用户
    if (method == 'getPostComment') return _getPostComment(); //获取帖子下面的评论
    if (method == 'addUser') return _addUser(); //添加用户
    if (method == 'updateUser') return _updateUser(); //更新用户
    if (method == 'addNotice') return _addNotice(); //添加公告
    if (method == 'deleteNotice') return _deleteNotice(); //删除公告
    if (method == 'addAdmin') return _addAdmin(); //添加管理员
    if (method == 'getAdminUser') return _getAdminUser(); //管理员列表
    if (method == 'resetPassword') return _resetPassword(); //重置密码
    if (method == 'modifyPassword') return _modifyPassword(); //修改密码
    if (method == 'modifyAdminUser') return _modifyAdminUser(); //编辑信息

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
      return packData(ERROR, null, "用户名或密码错误");
    }
    String _session = await SessionDao().loginSession(_ret['admin_id'], _pwd, "web_admin");
    Map<String, dynamic> _updateLogin = {"login_time": DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())};
    await _adminDao.update(_updateLogin, where: [Where("admin_id", _ret['admin_id'])]);

    return packData(SUCCESS, {"user": AdminUserModel.fromJson(_ret).toJsonBasic(), "token": _session}, "登陆成功");
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
    Map<String, dynamic> _ret = await _postsDao.getOne(column: ["COUNT(*)"], where: [Where("question_type", _type)]);
    return packData(SUCCESS, {"count": _ret["COUNT(*)"] ?? 0}, "获取帖子数量成功");
  }

  ///获取评论总数
  FutureOr<Response> _getTotlaComment() async {
    if (!(await validateToken())) return tokenExpired;
    final _commentDao = GlobalDao('comment');
    Map<String, dynamic> _ret = await _commentDao.getOne(column: ["COUNT(id)"]);
    return packData(SUCCESS, {"count": _ret["COUNT(id)"] ?? 0}, "获取帖子数量成功");
  }

  ///获取发帖排行
  FutureOr<Response> _getPostRank() async {
    if (!(await validateToken())) return tokenExpired;
    GlobalDao _postsDao = GlobalDao("posts");
    GlobalDao _userDao = GlobalDao("user");
    List<Map<String, dynamic>> _ret = await _postsDao
        .getList(column: ['user_id', 'COUNT(id)'], where: [Where('delete_time', null, 'IS')], groupBy: "user_id", order: "COUNT(id) DESC");
    List<Map<String, dynamic>> _list = [];
    for (final count in _ret) {
      int _userId = count['user_id'];
      int _count = count['COUNT(id)'];
      Map<String, dynamic> _userMap = await _userDao.getOne(where: [Where('user_id', _userId)]);
      if (_userMap.isEmpty && _userMap['disable_time']) continue;
      _list.add({"name": _userMap['username'], "count": _count});
    }

    return packData(SUCCESS, {"count": _list}, "OK");
  }

  ///获取评论排行
  FutureOr<Response> _getCommentRank() async {
    if (!(await validateToken())) return tokenExpired;
    GlobalDao _postsDao = GlobalDao("comment");
    GlobalDao _userDao = GlobalDao("user");
    List<Map<String, dynamic>> _ret = await _postsDao
        .getList(column: ['user_id', 'COUNT(id)'], where: [Where('delete_time', null, 'IS')], groupBy: "user_id", order: "COUNT(id) DESC");
    List<Map<String, dynamic>> _list = [];
    for (final count in _ret) {
      int _userId = count['user_id'];
      int _count = count['COUNT(id)'];
      Map<String, dynamic> _userMap = await _userDao.getOne(where: [Where('user_id', _userId)]);
      if (_userMap.isEmpty && _userMap['disable_time']) continue;
      _list.add({"name": _userMap['username'], "count": _count});
    }
    return packData(SUCCESS, {"count": _list}, "OK");
  }

  ///获取评论点赞排行
  FutureOr<Response> _getCommentLikeRank() async {
    if (!(await validateToken())) return tokenExpired;
    final _likeDao = GlobalDao("like");
    final _commentDao = GlobalDao("comment");
    List<Map<String, dynamic>> _ret = await _likeDao.getList(
      column: ['up_id', 'COUNT(user_id)'],
      where: [Where('up_type', 4), Where('delete_time', null, 'IS')],
      groupBy: "up_id",
      order: "COUNT(user_id) DESC",
      limit: Limit(limit: 10),
    );
    List<Map<String, dynamic>> _list = [];
    for (final ret in _ret) {
      int id = ret['up_id'];
      int count = ret['COUNT(user_id)'];
      Map<String, dynamic> post = await _commentDao.getOne(column: ['id', 'comment'], where: [Where('id', id)]);
      if (post.isNotEmpty) {
        _list.add({"title": post['comment'], "count": count});
      }
    }

    return packData(SUCCESS, {"count": _list}, "OK");
  }

  ///获取帖子点赞排行
  FutureOr<Response> _getPostLikeRank() async {
    if (!(await validateToken())) return tokenExpired;
    final _likeDao = GlobalDao("like");
    final _postDao = GlobalDao("posts");
    List<Map<String, dynamic>> _ret = await _likeDao.getList(
      column: ['up_id', 'COUNT(user_id)'],
      where: [
        Where('up_type', [1, 2, 3], "IN"),
        Where('delete_time', null, 'IS')
      ],
      groupBy: "up_id",
      order: "COUNT(user_id) DESC",
      limit: Limit(limit: 10),
    );
    List<Map<String, dynamic>> _list = [];
    for (final ret in _ret) {
      int id = ret['up_id'];
      int count = ret['COUNT(user_id)'];
      Map<String, dynamic> post = await _postDao.getOne(column: ['id', 'title'], where: [Where('id', id)]);
      if (post.isNotEmpty) {
        _list.add({"title": post['title'], "count": count});
      }
    }

    return packData(SUCCESS, {"count": _list}, "OK");
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
        await _userDao.getList(limit: Limit(limit: _pageSize, start: (_page - 1) * _pageSize), where: _where, order: "user_id DESC");

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

    List<Map<String, dynamic>> _list = await _postsDao.getList(
        where: [Where("user_id", _userId)], order: "create_time DESC", limit: Limit(limit: _pageSize, start: (_page - 1) * _pageSize));

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

    List<Map<String, dynamic>> _list = await _commentDao.getList(
        where: [Where("user_id", _userId)], order: "create_time DESC", limit: Limit(limit: _pageSize, start: (_page - 1) * _pageSize));

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

  ///获取帖子列表
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
        await _bbsDao.getList(where: _where, order: "id DESC", limit: Limit(limit: _pageSize, start: (_page - 1) * _pageSize));
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

  ///封禁用户
  FutureOr<Response> _banUser() async {
    if (!(await validateToken())) return tokenExpired;
    int _userId = await get<int>("user_id");
    GlobalDao _userDao = GlobalDao("user");

    ///查询用户是否存在和封禁状态
    Map<String, dynamic> _userJson = await _userDao.getOne(where: [Where("user_id", _userId)]);

    if (_userJson.isEmpty || _userJson['disable_time'] != null) {
      return packData(ERROR, null, "该用户不存在或已被封禁");
    }

    HashMap<String, dynamic> _modiyfMap = HashMap();
    _modiyfMap['disable_time'] = DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now());

    bool _ret = await _userDao.update(_modiyfMap, where: [Where("user_id", _userId)]);
    if (_ret) {
      return packData(SUCCESS, null, "OK");
    } else {
      return packData(ERROR, null, "封禁失败");
    }
  }

  ///重新启用被封禁的账号
  FutureOr<Response> _activeUser() async {
    if (!(await validateToken())) return tokenExpired;
    int _userId = await get<int>("user_id");
    GlobalDao _userDao = GlobalDao("user");

    ///查询用户是否存在和封禁状态
    Map<String, dynamic> _userJson = await _userDao.getOne(where: [Where("user_id", _userId)]);

    if (_userJson.isEmpty || _userJson['disable_time'] == null) {
      return packData(ERROR, null, "该用户不存在或未被封禁");
    }

    HashMap<String, dynamic> _modiyfMap = HashMap();
    _modiyfMap['disable_time'] = null;

    bool _ret = await _userDao.update(_modiyfMap, where: [Where("user_id", _userId)]);
    if (_ret) {
      return packData(SUCCESS, null, "OK");
    } else {
      return packData(ERROR, null, "解除封禁失败");
    }
  }

  ///获取帖子的评论
  FutureOr<Response> _getPostComment() async {
    if (!(await validateToken())) return tokenExpired;
    int _commentId = await get<int>("comment_id");
    int _page = await get<int>("page");
    int _pageSize = await get<int>("pageSize");
    if (_page < 1) {
      _page = 1;
    }

    if (_pageSize == 0) {
      _pageSize = 10;
    }

    final _commentDao = GlobalDao("comment");
    List<Map<String, dynamic>> _ret =
        await _commentDao.getList(where: [Where("comment_id", _commentId)], limit: Limit(limit: _pageSize, start: (_page - 1) * _pageSize));
    List<Map<String, dynamic>> _list = [];
    for (final _json in _ret) {
      _list.add(CommentModel.fromJson(_json).toJson());
    }

    return packData(SUCCESS, {"list": _list}, "OK");
  }

  ///添加患者
  FutureOr<Response> _addUser() async {
    if (!(await validateToken())) return tokenExpired;
    String _userName = await get<String>("userName"); //姓名
    String _email = await get<String>("email"); //邮箱
    String _password = await get<String>("password"); //密码
    int _rank = await get<int>("rank");
    if (_userName.isEmpty) return packData(ERROR, null, "用户名不能为空");
    if (_email.isEmpty) return packData(ERROR, null, "邮箱不能为空");
    final _userDao = GlobalDao("user");

    ///检查邮箱是否已注册
    final chk = await _userDao.getOne(where: [Where("email", _email)]);
    if (chk.isNotEmpty) return packData(ERROR, null, "当前邮箱已注册");

    ///检查密码长度
    if (_password.length < Config.MIN_USER_PASSWORD_LENGTH) return packData(ERROR, null, "密码不能小于${Config.MIN_USER_PASSWORD_LENGTH}位");

    ///添加用户
    _password = md5.convert(_password.codeUnits).toString();
    UserModel _user = UserModel(email: _email, password: _password, username: _userName, rank: _rank);
    Map<String, dynamic> _userJson = _user.toJson();
    _userJson.remove("user_id");
    _userJson['create_time'] = DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now());
    _userJson['update_time'] = DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now());
    bool _ret = await _userDao.insert(_userJson);
    if (_ret) {
      return packData(SUCCESS, {'user': jsonEncode(_user.toJson())}, '添加成功');
    } else {
      return packData(ERROR, null, '添加失败');
    }
  }

  FutureOr<Response> _updateUser() async {
    if (!(await validateToken())) return tokenExpired;
    int _userId = await get<int>("user_id");
    String _modifyStr = await get<String>("modifyJson");
    final _userDao = GlobalDao("user");
    if (_modifyStr.isEmpty) return packData(ERROR, null, "修改信息不能为空");
    Map<String, dynamic> _modifyJson = {};
    try {
      _modifyJson = jsonDecode(_modifyStr);
    } catch (e) {
      return packData(ERROR, null, "修改信息有误");
    }
    Map<String, dynamic> _user = await _userDao.getOne(where: [Where("user_id", _userId)]);
    if (_user.isEmpty) return packData(ERROR, null, "查无此人");
    Map<String, dynamic> _modify = {};
    _modifyJson.forEach((key, value) {
      if (_user.containsKey(key) && _user[key] != value) {
        _modify[key] = value;
      }
    });
    if (_modify.isEmpty) return packData(SUCCESS, null, "没什么可以更新的");
    bool _ret = await _userDao.update(_modify, where: [Where("user_id", _userId)]);
    if (_ret) {
      return packData(SUCCESS, null, "OK");
    } else {
      return packData(ERROR, null, "更新失败");
    }
  }

  ///设置推荐帖
  FutureOr<Response> _setPostRecommand() async {
    if (!(await validateToken())) return tokenExpired;
    int _postId = await get<int>("id"); //帖子id
    final _postDao = GlobalDao("posts");
    Map<String, dynamic> _chk = await _postDao.getOne(where: [Where("id", _postId), Where("is_recommand", 1)]);
    if (_chk.isNotEmpty) return packData(SUCCESS, null, "已经是推荐帖了");
    Map<String, dynamic> _modify = {"is_recommand": 1, "update_time": DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())};
    bool _ret = await _postDao.update(_modify, where: [Where("id", _postId)]);
    if (_ret) {
      return packData(SUCCESS, null, "OK");
    } else {
      return packData(ERROR, null, "更新失败");
    }
  }

  ///取消推荐帖
  FutureOr<Response> _unsetPostRecommand() async {
    if (!(await validateToken())) return tokenExpired;
    int _postId = await get<int>("id"); //帖子id
    final _postDao = GlobalDao("posts");
    Map<String, dynamic> _chk = await _postDao.getOne(where: [Where("id", _postId), Where("is_recommand", 0)]);
    if (_chk.isNotEmpty) return packData(SUCCESS, null, "没有推荐这个帖子");
    Map<String, dynamic> _modify = {"is_recommand": 0, "update_time": DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())};
    bool _ret = await _postDao.update(_modify, where: [Where("id", _postId)]);
    if (_ret) {
      return packData(SUCCESS, null, "OK");
    } else {
      return packData(ERROR, null, "更新失败");
    }
  }

  ///设置精华贴
  FutureOr<Response> _setPostTop() async {
    if (!(await validateToken())) return tokenExpired;
    int _postId = await get<int>("id"); //帖子id
    final _postDao = GlobalDao("posts");
    Map<String, dynamic> _chk = await _postDao.getOne(where: [Where("id", _postId), Where("is_top", 1)]);
    if (_chk.isNotEmpty) return packData(SUCCESS, null, "已经是精华帖了");
    Map<String, dynamic> _modify = {"is_top": 1, "update_time": DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())};
    bool _ret = await _postDao.update(_modify, where: [Where("id", _postId)]);
    if (_ret) {
      return packData(SUCCESS, null, "OK");
    } else {
      return packData(ERROR, null, "更新失败");
    }
  }

  ///取消精华贴
  FutureOr<Response> _unsetPostTop() async {
    if (!(await validateToken())) return tokenExpired;
    int _postId = await get<int>("id"); //帖子id
    final _postDao = GlobalDao("posts");
    Map<String, dynamic> _chk = await _postDao.getOne(where: [Where("id", _postId), Where("is_top", 0)]);
    if (_chk.isNotEmpty) return packData(SUCCESS, null, "没有设置这个帖子");
    Map<String, dynamic> _modify = {"is_top": 0, "update_time": DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())};
    bool _ret = await _postDao.update(_modify, where: [Where("id", _postId)]);
    if (_ret) {
      return packData(SUCCESS, null, "OK");
    } else {
      return packData(ERROR, null, "更新失败");
    }
  }

  FutureOr<Response> _deletePost() async {
    if (!(await validateToken())) return tokenExpired;
    int _postId = await get<int>("id"); //帖子id
    final _postDao = GlobalDao("posts");
    Map<String, dynamic> _chk = await _postDao.getOne(where: [Where("id", _postId), Where("delete_time", null, "IS")]);
    if (_chk.isEmpty) return packData(SUCCESS, null, "没有设置这个帖子");
    final _date = DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now());
    Map<String, dynamic> _modify = {"update_time": _date, "delete_time": _date};
    bool _ret = await _postDao.update(_modify, where: [Where("id", _postId)]);
    if (_ret) {
      return packData(SUCCESS, null, "OK");
    } else {
      return packData(ERROR, null, "删除失败");
    }
  }

  ///启用被删除的帖子
  FutureOr<Response> _activePost() async {
    if (!(await validateToken())) return tokenExpired;
    int _postId = await get<int>("id"); //帖子id
    final _postDao = GlobalDao("posts");
    Map<String, dynamic> _chk = await _postDao.getOne(where: [Where("id", _postId), Where("delete_time", null, "IS NOT")]);
    if (_chk.isEmpty) return packData(SUCCESS, null, "没有设置这个帖子");
    final _date = DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now());
    Map<String, dynamic> _modify = {"update_time": _date, "delete_time": null};
    bool _ret = await _postDao.update(_modify, where: [Where("id", _postId)]);
    if (_ret) {
      return packData(SUCCESS, null, "OK");
    } else {
      return packData(ERROR, null, "启用失败");
    }
  }

  ///添加公告
  ///仅超管
  FutureOr<Response> _addNotice() async {
    if (!(await validateToken())) return tokenExpired;
    AdminUserModel? _adminUser = await getTokenAdmin();
    if (_adminUser == null) return packData(ERROR, null, "查无此人");
    if (_adminUser.rank != 1) return packData(ERROR, null, "当前管理员无权限添加公告");
    String _title = await get<String>("title");
    String _content = await get<String>("content");
    if (_title.isEmpty) return packData(ERROR, null, "标题不能为空");
    if (_content.isEmpty) return packData(ERROR, null, "正文不能为空");
    String _imageBase64 = await get<String>("image");
    Blob? _image;
    if (_imageBase64.isNotEmpty) {
      try {
        Uint8List _codeUnits = base64Decode(_imageBase64.split(",").last); //base64转Uint8List
        _image = Blob.fromBytes(_codeUnits);
        File file = File('D:/code_demo/64_1.txt');
        file.writeAsStringSync(_image.toString());
      } catch (e) {
        print("[Admin][addNotice] 图片解析错误");
      }
    }
    NoticeModel _notice = NoticeModel(
      admin_id: _adminUser.admin_id,
      title: _title,
      content: _content,
      create_time: DateTime.now(),
      image: _image,
    );
    final _noticeDao = GlobalDao("notice");
    Map<String, dynamic> _data = _notice.toJson();
    _data.remove("id");
    bool _ret = await _noticeDao.insert(_data);
    if (_ret) {
      return packData(SUCCESS, null, "OK");
    } else {
      return packData(ERROR, null, "添加失败");
    }
  }

  ///删除公告
  ///仅超管
  FutureOr<Response> _deleteNotice() async {
    if (!(await validateToken())) return tokenExpired;
    AdminUserModel? _adminUser = await getTokenAdmin();
    if (_adminUser == null) return packData(ERROR, null, "查无此人");
    if (_adminUser.rank != 1) return packData(ERROR, null, "当前管理员无权限删除公告");
    int _id = await get<int>("id");
    final _noticeDao = GlobalDao("notice");
    Map<String, dynamic> _chk = await _noticeDao.getOne(where: [Where('id', _id), Where("delete_time", null, "IS")]);
    if (_chk.isEmpty) return packData(ERROR, null, "公告不存在或已被删除");
    Map<String, dynamic> _modify = {"delete_time": DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())};
    bool _ret = await _noticeDao.update(_modify, where: [Where('id', _id)]);
    if (_ret) {
      return packData(SUCCESS, null, "OK");
    } else {
      return packData(ERROR, null, "删除失败");
    }
  }

  ///添加管理员
  ///仅超管
  FutureOr<Response> _addAdmin() async {
    if (!(await validateToken())) return tokenExpired;
    AdminUserModel? _adminUser = await getTokenAdmin();
    if (_adminUser == null) return packData(ERROR, null, "查无此人");
    if (_adminUser.rank != 1) return packData(ERROR, null, "当前管理员无权限添加管理员");
    String _name = await get<String>("name"); //名称
    String _pwd = await get<String>("password"); //密码
    final _adminDao = GlobalDao("admin_user");
    if (_name.isEmpty) return packData(ERROR, null, "名称不能为空");
    if (_pwd.isEmpty) return packData(ERROR, null, "密码不能为空");
    if (_pwd.length < Config.MIN_USER_PASSWORD_LENGTH) return packData(ERROR, null, "密码不能小于${Config.MIN_USER_PASSWORD_LENGTH}位");

    ///查询名称有没有被注册过
    final _adminChk = await _adminDao.getOne(where: [Where("name", _name)]);
    if (_adminChk.isNotEmpty) return packData(ERROR, null, "该管理员名称已注册");
    _pwd = DataUtils.generate_MD5(_pwd);
    AdminUserModel _admin = AdminUserModel(password: _pwd, name: _name, create_time: DateTime.now());
    final _data = _admin.toJson();
    _data.remove("id");
    bool _ret = await _adminDao.insert(_data);
    if (_ret) {
      return packData(SUCCESS, null, "OK");
    } else {
      return packData(ERROR, null, "添加失败");
    }
  }

  ///获取管理员列表
  ///仅超管
  FutureOr<Response> _getAdminUser() async {
    if (!(await validateToken())) return tokenExpired;
    AdminUserModel? _adminUser = await getTokenAdmin();
    if (_adminUser == null) return packData(ERROR, null, "查无此人");
    if (_adminUser.rank != 1) return packData(ERROR, null, "当前管理员无权限");
    final _adminDao = GlobalDao("admin_user");
    List<Map<String, dynamic>> _ret = await _adminDao.getList(order: "admin_id ASC");
    List<Map<String, dynamic>> _list = [];
    for (final json in _ret) {
      final _admin = AdminUserModel.fromJson(json);
      if (_admin.admin_id == _adminUser.admin_id) continue;
      _list.add(_admin.toJsonBasic());
    }
    return packData(SUCCESS, {"list": _list}, "OK");
  }

  ///编辑管理员信息
  FutureOr<Response> _modifyAdminUser() async {
    if (!(await validateToken())) return tokenExpired;
    AdminUserModel? _adminUser = await getTokenAdmin();
    if (_adminUser == null) return packData(ERROR, null, "查无此人");
    int _adminId = await get<int>("admin_id");
    final _adminDao = GlobalDao("admin_user");
    late Map<String, dynamic> _userChk;
    if (_adminId != _adminUser.admin_id) {
      ///编辑其他管理员 检查账号权限
      if (_adminUser.rank != 1) return packData(ERROR, null, "当前管理员无权限");
      _userChk = await _adminDao.getOne(where: [Where("admin_id", _adminId)]);
      if (_userChk.isEmpty) return packData(ERROR, null, "当前管理员不存在");
    } else {
      _userChk = _adminUser.toJsonBasic();
    }
    String _modifyJson = await get<String>("modify");
    Map<String, dynamic> _modify = {};
    try {
      _modify = jsonDecode(_modifyJson);
    } catch (e) {
      return packData(ERROR, null, "修改内容格式错误");
    }
    for (final key in _modify.keys.toList()) {
      ///去除一致的字段
      if (_userChk[key] == _modify[key]) {
        _modify.remove(key);
      }
    }
    if (_modify.isEmpty) return packData(ERROR, null, "没什么好修改的");
    bool _ret = await _adminDao.update(_modify, where: [Where("admin_id", _adminId)]);
    if (_ret) {
      return packData(SUCCESS, null, 'OK');
    } else {
      return packData(ERROR, null, "修改失败");
    }
  }

  ///重置密码
  ///仅超管
  FutureOr<Response> _resetPassword() async {
    if (!(await validateToken())) return tokenExpired;
    AdminUserModel? _adminUser = await getTokenAdmin();
    if (_adminUser == null) return packData(ERROR, null, "查无此人");
    if (_adminUser.rank != 1) return packData(ERROR, null, "当前管理员无权限");
    int _adminId = await get<int>("admin_id"); //重置的管理员id
    String _resetPasswd = await get<String>("reset_password"); //重置的管理员密码
    final _adminDao = GlobalDao("admin_user");
    Map<String, dynamic> _userChk = await _adminDao.getOne(where: [Where("admin_id", _adminId)]);
    if (_userChk.isEmpty) return packData(ERROR, null, "当前管理员不存在");
    if (_resetPasswd.length < Config.MIN_USER_PASSWORD_LENGTH) return packData(ERROR, null, "密码不得小于${Config.MIN_USER_PASSWORD_LENGTH}位");
    _resetPasswd = DataUtils.generate_MD5(_resetPasswd); //加密
    if (_resetPasswd == _userChk['password']) return packData(ERROR, null, '新旧密码不能一致');
    Map<String, dynamic> _modify = {"password": _resetPasswd};
    bool _ret = await _adminDao.update(_modify, where: [Where("admin_id", _adminId)]);
    if (_ret) {
      ///修改密码后重置当前账号的所有有效token
      await SessionDao().clearSession(_adminId);
      return packData(SUCCESS, null, "OK");
    } else {
      return packData(ERROR, null, "修改失败");
    }
  }

  ///修改密码
  FutureOr<Response> _modifyPassword() async {
    if (!(await validateToken())) return tokenExpired;
    AdminUserModel? _adminUser = await getTokenAdmin();
    if (_adminUser == null) return packData(ERROR, null, "查无此人");
    String _passwordOld = await get<String>("old_password"); //旧密码
    String _passwordNew = await get<String>("new_password"); //新密码
    if (_passwordNew.length < Config.MIN_USER_PASSWORD_LENGTH) return packData(ERROR, null, "密码不得小于${Config.MIN_USER_PASSWORD_LENGTH}位");
    _passwordOld = DataUtils.generate_MD5(_passwordOld);
    _passwordNew = DataUtils.generate_MD5(_passwordNew);
    if (_adminUser.password != _passwordOld) return packData(ERROR, null, '旧密码错误');
    final _adminDao = GlobalDao("admin_user");
    bool _ret = await _adminDao.update({"password": _passwordNew}, where: [Where('admin_id', _adminUser.admin_id)]);
    if (_ret) {
      ///修改密码后重置当前账号的所有有效token
      await SessionDao().clearSession(_adminUser.admin_id);
      return packData(SUCCESS, null, 'OK');
    } else {
      return packData(ERROR, null, "修改错误");
    }
  }
}
