import 'dart:convert';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:jaguar/http/context/context.dart';
import 'package:jaguar/http/response/response.dart';
import 'package:mysql1/mysql1.dart';

import 'dart:async';

import '../db/bbs_dao.dart';
import '../db/global_dao.dart';
import '../db/image_dao.dart';
import '../model/bbs_model.dart';
import '../model/comment_model.dart';
import '../model/user_model.dart';
import 'base_api.dart';

///论坛请求类
class BBS extends BaseApi {
  BBS(Context ctx) : super(ctx);

  @override
  FutureOr<Response> method(String method) {
    if (method == "addBBS") return _addBBS(); //添加帖子
    if (method == "addComment") return _addComment(); //添加评论
    if (method == "getBBSList") return _getBBSList(); //获取帖子列表
    if (method == "getSubscribeBBSList") return _getSubscribeBBSList(); //获取关注帖子
    if (method == "getPopularBBSList") return _getPopularBBSList(); //获取热门帖子
    if (method == "getRecommandBBSList") return _getRecommandBBSList(); //获取推荐帖子
    if (method == "getRecentBBSList") return _getBBSList(); //获取最近帖子
    if (method == "getStarBBSList") return _getStarBBSList(); //获取精华帖子
    if (method == "getBBSComment") return _getBBSComment(); //获取评论
    if (method == "getBBSDetail") return _getBBSDetail(); //获取论坛详情
    if (method == "searchBBS") return _searchBBS(); //搜索帖子
    if (method == "deleteComment") return _deleteComment(); //删除帖子
    return pageNotFound;
  }

  ///添加帖子或问题
  FutureOr<Response> _addBBS() async {
    if (!(await validateToken())) return tokenExpired;

    UserModel? _user = await getTokenUser();

    if (_user == null) return packData(ERROR, null, "未找到当前用户");

    String title = await get<String>("title");
    String content = await get<String>("content");
    int type = await get<int>("type"); // 1问题2文章3帖子

    if (title.isEmpty) return packData(ERROR, null, "标题不能为空");

    if (content.isEmpty) return packData(ERROR, null, "内容不能为空");

    ///获取图片
    String _imageStr = await get<String>('images'); //base64格式图片json
    List<Blob> _imageList = [];
    if (_imageStr.isNotEmpty) {
      List<String> _images = List<String>.from(jsonDecode(_imageStr));
      for (String _base64Image in _images) {
        if (_base64Image.isNotEmpty) {
          try {
            Uint8List _codeUnits = base64Decode(_base64Image.split(",").last); //base64转Uint8List
            _imageList.add(Blob.fromBytes(_codeUnits));
          } catch (e) {
            print("图片错误$e");
          }
        }
      }
    }

    final _now = DateTime.now();
    BBSModel _bbs = BBSModel(
      user_id: _user.user_id,
      title: title,
      content: content,
      question_type: type,
      create_time: _now,
      update_time: _now,
    );
    Map<String, dynamic> _bbsJson = _bbs.toJson();
    _bbsJson.remove("id");

    GlobalDao _bbsDao = GlobalDao("posts");
    int id = await _bbsDao.insertReturnId(_bbsJson);
    if (id == 0) {
      return packData(ERROR, null, "添加失败");
    }

    if (_imageList.isNotEmpty) {
      await ImageDao.addImages(id, type, _user.user_id, _imageList);
    }

    return packData(SUCCESS, null, "添加成功");
  }

  ///添加评论
  FutureOr<Response> _addComment() async {
    if (!(await validateToken())) return tokenExpired;

    UserModel? _user = await getTokenUser();

    if (_user == null) return packData(ERROR, null, "未找到当前用户");

    String comment = await get<String>("comment");
    int comment_id = await get<int>("comment_id");
    int sub_comment_id = await get<int>("sub_comment_id");
    int type = await get<int>("type");

    if (comment.isEmpty) return packData(ERROR, null, "评论不能为空");

    GlobalDao _bbsDao = GlobalDao("posts");
    GlobalDao _commentDao = GlobalDao("comment");

    ///TODO:楼中楼的话判断是否评论被删除
    Map<String, dynamic> _commentInComment = {};
    if (type == CommentModel.TYPE_SUB_COMMENT) {
      _commentInComment = await _commentDao.getOne(where: [Where("id", comment_id), Where("delete_time", null, "is")]);
      if (_commentInComment.isEmpty) return packData(ERROR, null, "评论被删除或不存在");
    }

    print(" comment   $_commentInComment");

    ///统一判断帖子是否被删除
    Map<String, dynamic> _bbsComment =
        await _bbsDao.getOne(where: [Where("id", type == CommentModel.TYPE_SUB_COMMENT ? _commentInComment['comment_id'] : comment_id)]);
    if (_bbsComment.isEmpty || _bbsComment['delete_time'] != null) {
      return packData(ERROR, null, "${type == 1 ? '文章' : '帖子'}被删除或不存在");
    }
    final _now = DateTime.now();
    Map<String, dynamic> _commentModel = CommentModel(
      user_id: _user.user_id,
      comment: comment,
      comment_id: comment_id,
      sub_comment_id: sub_comment_id != 0 ? sub_comment_id : null,
      comment_type: type,
      create_time: _now,
      update_time: _now,
    ).toJson();

    _commentModel.remove("id");

    int _ret = await _commentDao.insertReturnId(_commentModel);
    if (_ret > 0) {
      ///TODO：帖子回复数量+1
      if (type == CommentModel.TYPE_SUB_COMMENT) {
        //楼中楼暂不计入回复数量
      } else {
        BBSDao _bbsDao = BBSDao();
        await _bbsDao.addComment(comment_id);
      }

      return packData(SUCCESS, {"id": _ret}, "添加成功");
    } else {
      return packData(ERROR, null, "添加失败");
    }
  }

  ///获取帖子列表
  FutureOr<Response> _getBBSList() async {
    if (!(await validateToken())) return tokenExpired;

    GlobalDao _bbsDao = GlobalDao("posts");
    int _type = await get<int>("type");
    int _startIndex = await get<int>("startIndex"); //从第几条数据开始
    int _pageSize = await get<int>("pageSize"); //每次返回多少条数据

    if (_pageSize == 0) {
      _pageSize = 10;
    }

    List<Where> _where = [];
    if (BBSModel.TYPE_LIST.contains(_type)) {
      _where.add(Where('question_type', _type));
    }
    _where.add(Where("delete_time", null, "is"));
    Map<String, dynamic> _countRet = await _bbsDao.getOne(column: ["COUNT(*)"], where: _where);

    List<Map<String, dynamic>> _postList =
        await _bbsDao.getList(where: _where, order: "update_time DESC", limit: Limit(limit: _pageSize, start: _startIndex));
    final _userDao = GlobalDao("user");
    List<int> _userIdList = List.generate(_postList.length, (index) => _postList[index]['user_id'] ?? 0);
    List<Map<String, dynamic>> _userList =
        await _userDao.getList(column: ['user_id', 'avatar'], where: [Where("user_id", _userIdList, "IN")]);

    for (int i = 0; i < _postList.length; i++) {
      BBSModel _bbsModel = BBSModel.fromJson(_postList[i]);
      Map<String, dynamic> _post = _bbsModel.toJson();

      ///找用户
      int _index = _userList.indexWhere((element) => element['user_id'] == _bbsModel.user_id);
      if (_index != -1) {
        Map<String, dynamic> _user = _userList[_index];
        if (_user['avatar'] != null && _user['avatar'] is Blob) {
          _post['avatar'] = base64Encode((_user['avatar'] as Blob).toBytes());
        }
      }

      ///找图片
      // List<Blob> _images = await ImageDao.getImages(_bbsModel.id, _bbsModel.question_type);
      // _post['images'] = List.generate(_images.length, (index) => base64Encode(_images[index].toBytes())); //blob转base64
      // _postList[i] = _post;
      List<int> _imageIds = await ImageDao.getImageIds(_bbsModel.id, _bbsModel.question_type);
      _post['images'] = _imageIds;
      _postList[i] = _post;
    }

    Map<String, dynamic> _pageInfo = {
      "total": ((_countRet['COUNT(*)'] ?? 0) as int), //总共有多少条数据
      "returnDataCount": _postList.length, //本次返回多少数据
      "pageSize": _pageSize, //每次应该返回多少条数据
    };

    return packData(SUCCESS, {"data": _postList, "page": _pageInfo}, "获取帖子列表成功");
  }

  ///获取加精贴
  FutureOr<Response> _getStarBBSList() async {
    if (!(await validateToken())) return tokenExpired;

    GlobalDao _bbsDao = GlobalDao("posts");
    int _type = await get<int>("type");
    int _startIndex = await get<int>("startIndex"); //从第几条数据开始
    int _pageSize = await get<int>("pageSize"); //每次返回多少条数据

    if (_pageSize == 0) {
      _pageSize = 10;
    }

    List<Where> _where = [];
    if (BBSModel.TYPE_LIST.contains(_type)) {
      _where.add(Where('question_type', _type));
    }
    _where.add(Where("delete_time", null, "is"));
    _where.add(Where("is_top", 1));
    Map<String, dynamic> _countRet = await _bbsDao.getOne(column: ["COUNT(*)"], where: _where);

    List<Map<String, dynamic>> _postList =
        await _bbsDao.getList(where: _where, order: "update_time DESC", limit: Limit(limit: _pageSize, start: _startIndex));
    final _userDao = GlobalDao("user");
    List<int> _userIdList = List.generate(_postList.length, (index) => _postList[index]['user_id'] ?? 0);
    List<Map<String, dynamic>> _userList =
        await _userDao.getList(column: ['user_id', 'avatar'], where: [Where("user_id", _userIdList, "IN")]);

    for (int i = 0; i < _postList.length; i++) {
      BBSModel _bbsModel = BBSModel.fromJson(_postList[i]);
      Map<String, dynamic> _post = _bbsModel.toJson();

      ///找用户
      int _index = _userList.indexWhere((element) => element['user_id'] == _bbsModel.user_id);
      if (_index != -1) {
        Map<String, dynamic> _user = _userList[_index];
        if (_user['avatar'] != null && _user['avatar'] is Blob) {
          _post['avatar'] = base64Encode((_user['avatar'] as Blob).toBytes());
        }
      }

      ///找图片
      // List<Blob> _images = await ImageDao.getImages(_bbsModel.id, _bbsModel.question_type);
      // _post['images'] = List.generate(_images.length, (index) => base64Encode(_images[index].toBytes())); //blob转base64
      // _postList[i] = _post;
      List<int> _imageIds = await ImageDao.getImageIds(_bbsModel.id, _bbsModel.question_type);
      _post['images'] = _imageIds;
      _postList[i] = _post;
    }

    Map<String, dynamic> _pageInfo = {
      "total": ((_countRet['COUNT(*)'] ?? 0) as int), //总共有多少条数据
      "returnDataCount": _postList.length, //本次返回多少数据
      "pageSize": _pageSize, //每次应该返回多少条数据
    };

    return packData(SUCCESS, {"data": _postList, "page": _pageInfo}, "获取帖子列表成功");
  }

  ///获取推荐贴
  FutureOr<Response> _getPopularBBSList() async {
    if (!(await validateToken())) return tokenExpired;

    GlobalDao _bbsDao = GlobalDao("posts");
    int _type = await get<int>("type");
    int _startIndex = await get<int>("startIndex"); //从第几条数据开始
    int _pageSize = await get<int>("pageSize"); //每次返回多少条数据

    if (_pageSize == 0) {
      _pageSize = 10;
    }

    List<Where> _where = [];
    if (BBSModel.TYPE_LIST.contains(_type)) {
      _where.add(Where('question_type', _type));
    }
    _where.add(Where("delete_time", null, "is"));
    Map<String, dynamic> _countRet = await _bbsDao.getOne(column: ["COUNT(*)"], where: _where);

    List<Map<String, dynamic>> _postList =
        await _bbsDao.getList(where: _where, order: "up_count DESC", limit: Limit(limit: _pageSize, start: _startIndex));
    final _userDao = GlobalDao("user");
    List<int> _userIdList = List.generate(_postList.length, (index) => _postList[index]['user_id'] ?? 0);
    List<Map<String, dynamic>> _userList =
        await _userDao.getList(column: ['user_id', 'avatar'], where: [Where("user_id", _userIdList, "IN")]);

    for (int i = 0; i < _postList.length; i++) {
      BBSModel _bbsModel = BBSModel.fromJson(_postList[i]);
      Map<String, dynamic> _post = _bbsModel.toJson();

      ///找用户
      int _index = _userList.indexWhere((element) => element['user_id'] == _bbsModel.user_id);
      if (_index != -1) {
        Map<String, dynamic> _user = _userList[_index];
        if (_user['avatar'] != null && _user['avatar'] is Blob) {
          _post['avatar'] = base64Encode((_user['avatar'] as Blob).toBytes());
        }
      }

      ///找图片
      // List<Blob> _images = await ImageDao.getImages(_bbsModel.id, _bbsModel.question_type);
      // _post['images'] = List.generate(_images.length, (index) => base64Encode(_images[index].toBytes())); //blob转base64
      // _postList[i] = _post;
      List<int> _imageIds = await ImageDao.getImageIds(_bbsModel.id, _bbsModel.question_type);
      _post['images'] = _imageIds;
      _postList[i] = _post;
    }

    Map<String, dynamic> _pageInfo = {
      "total": ((_countRet['COUNT(*)'] ?? 0) as int), //总共有多少条数据
      "returnDataCount": _postList.length, //本次返回多少数据
      "pageSize": _pageSize, //每次应该返回多少条数据
    };

    return packData(SUCCESS, {"data": _postList, "page": _pageInfo}, "获取帖子列表成功");
  }

  ///获取推荐贴
  FutureOr<Response> _getRecommandBBSList() async {
    if (!(await validateToken())) return tokenExpired;

    GlobalDao _bbsDao = GlobalDao("posts");
    int _type = await get<int>("type");
    int _startIndex = await get<int>("startIndex"); //从第几条数据开始
    int _pageSize = await get<int>("pageSize"); //每次返回多少条数据

    if (_pageSize == 0) {
      _pageSize = 10;
    }

    List<Where> _where = [];
    if (BBSModel.TYPE_LIST.contains(_type)) {
      _where.add(Where('question_type', _type));
    }
    _where.add(Where("delete_time", null, "is"));
    _where.add(Where("is_recommand", 1));
    Map<String, dynamic> _countRet = await _bbsDao.getOne(column: ["COUNT(*)"], where: _where);

    List<Map<String, dynamic>> _postList =
        await _bbsDao.getList(where: _where, order: "update_time DESC", limit: Limit(limit: _pageSize, start: _startIndex));
    final _userDao = GlobalDao("user");
    List<int> _userIdList = List.generate(_postList.length, (index) => _postList[index]['user_id'] ?? 0);
    List<Map<String, dynamic>> _userList =
        await _userDao.getList(column: ['user_id', 'avatar'], where: [Where("user_id", _userIdList, "IN")]);

    for (int i = 0; i < _postList.length; i++) {
      BBSModel _bbsModel = BBSModel.fromJson(_postList[i]);
      Map<String, dynamic> _post = _bbsModel.toJson();

      ///找用户
      int _index = _userList.indexWhere((element) => element['user_id'] == _bbsModel.user_id);
      if (_index != -1) {
        Map<String, dynamic> _user = _userList[_index];
        if (_user['avatar'] != null && _user['avatar'] is Blob) {
          _post['avatar'] = base64Encode((_user['avatar'] as Blob).toBytes());
        }
      }

      ///找图片
      // List<Blob> _images = await ImageDao.getImages(_bbsModel.id, _bbsModel.question_type);
      // _post['images'] = List.generate(_images.length, (index) => base64Encode(_images[index].toBytes())); //blob转base64
      // _postList[i] = _post;
      List<int> _imageIds = await ImageDao.getImageIds(_bbsModel.id, _bbsModel.question_type);
      _post['images'] = _imageIds;
      _postList[i] = _post;
    }

    Map<String, dynamic> _pageInfo = {
      "total": ((_countRet['COUNT(*)'] ?? 0) as int), //总共有多少条数据
      "returnDataCount": _postList.length, //本次返回多少数据
      "pageSize": _pageSize, //每次应该返回多少条数据
    };

    return packData(SUCCESS, {"data": _postList, "page": _pageInfo}, "获取帖子列表成功");
  }

  ///获取关注人的帖子
  FutureOr<Response> _getSubscribeBBSList() async {
    if (!(await validateToken())) return tokenExpired;
    final _user = await getTokenUser();
    if (_user == null) return packData(ERROR, null, "查无此人");
    int _startIndex = await get<int>("startIndex"); //从第几条数据开始
    int _pageSize = await get<int>("pageSize"); //每次返回多少条数据

    if (_pageSize == 0) {
      _pageSize = 10;
    }

    ///找关注
    final _subDao = GlobalDao("subscribe");
    List<Map<String, dynamic>> _subList = await _subDao.getList(column: [
      'subscribe_id'
    ], where: [
      Where("user_id", _user.user_id),
      Where("delete_time", null, 'IS'),
    ]);
    Map<String, dynamic> _pageInfo = {
      "total": 0, //总共有多少条数据
      "returnDataCount": 0, //本次返回多少数据
      "pageSize": _pageSize, //每次应该返回多少条数据
    };
    List<Map<String, dynamic>> _postList = [];

    ///找帖子
    if (_subList.isNotEmpty) {
      final _postDao = GlobalDao("posts");
      final _userDao = GlobalDao("user");
      List<Where> _where = [
        Where("user_id", List.generate(_subList.length, (index) => _subList[index]['subscribe_id'])),
        Where("delete_time", null, "is"),
      ];
      Map<String, dynamic> _countRet = await _postDao.getOne(column: ["COUNT(*)"], where: _where);

      _postList = await _postDao.getList(where: _where, order: "update_time DESC", limit: Limit(limit: _pageSize, start: _startIndex));
      List<int> _userIdList = List.generate(_postList.length, (index) => _postList[index]['user_id'] ?? 0);
      List<Map<String, dynamic>> _userList =
          await _userDao.getList(column: ['user_id', 'avatar'], where: [Where("user_id", _userIdList, "IN")]);
      for (int i = 0; i < _postList.length; i++) {
        BBSModel _bbsModel = BBSModel.fromJson(_postList[i]);
        Map<String, dynamic> _post = _bbsModel.toJson();

        ///找用户
        int _index = _userList.indexWhere((element) => element['user_id'] == _bbsModel.user_id);
        if (_index != -1) {
          Map<String, dynamic> _user = _userList[_index];
          if (_user['avatar'] != null && _user['avatar'] is Blob) {
            _post['avatar'] = base64Encode((_user['avatar'] as Blob).toBytes());
          }
        }

        ///找图片
        // List<Blob> _images = await ImageDao.getImages(_bbsModel.id, _bbsModel.question_type);
        // _post['images'] = List.generate(_images.length, (index) => base64Encode(_images[index].toBytes())); //blob转base64
        // _postList[i] = _post;
        List<int> _imageIds = await ImageDao.getImageIds(_bbsModel.id, _bbsModel.question_type);
        _post['images'] = _imageIds;
        _postList[i] = _post;
      }

      _pageInfo = {
        "total": ((_countRet['COUNT(*)'] ?? 0) as int), //总共有多少条数据
        "returnDataCount": _postList.length, //本次返回多少数据
        "pageSize": _pageSize, //每次应该返回多少条数据
      };
    }
    return packData(SUCCESS, {"data": _postList, "page": _pageInfo}, "获取帖子列表成功");
  }

  ///获取评论
  FutureOr<Response> _getBBSComment() async {
    if (!(await validateToken())) return tokenExpired;
    int _id = await get<int>("id"); //文章，帖子，问答id
    int _startIndex = await get<int>("startIndex"); //从第几条数据开始查询
    int _pageSize = await get<int>("pageSize"); //一次返回多少条数据

    if (_pageSize == 0) {
      _pageSize = 10;
    }

    ///查贴
    GlobalDao _bbsDao = GlobalDao('posts');
    Map<String, dynamic> _bbsJson = await _bbsDao.getOne(where: [Where("id", _id)]);
    if (_bbsJson.isEmpty) {
      return packData(ERROR, null, "查无此贴");
    }
    BBSModel _bbs = BBSModel.fromJson(_bbsJson);

    ///查评论
    GlobalDao _commentDao = GlobalDao("comment");
    Map<String, dynamic> _pageCount = await _commentDao.getOne(
      column: ["COUNT(*)"],
      where: [Where("comment_id", _bbs.id), Where("comment_type", _bbs.question_type), Where("delete_time", null, "IS")],
    );

    List<Map<String, dynamic>> _list = await _commentDao.getList(
      where: [Where("comment_id", _bbs.id), Where("comment_type", _bbs.question_type), Where("delete_time", null, "IS")],
      limit: Limit(limit: _pageSize, start: _startIndex),
      order: "create_time ASC",
    );

    GlobalDao _userDao = GlobalDao("user");

    ///查楼中楼
    List<Map<String, dynamic>> _listWithComment = [];
    for (Map<String, dynamic> _commentMap in _list) {
      CommentModel _comment = CommentModel.fromJson(_commentMap);
      List<Map<String, dynamic>> _subCommentList = await _commentDao.getList(
        where: [
          Where("comment_id", _comment.id),
          Where("comment_type", CommentModel.TYPE_SUB_COMMENT),
          Where("delete_time", null, "IS"),
        ],
        // limit: Limit(limit: 2),
        order: "create_time ASC",
      );

      ///查用户
      for (int i = 0; i < _subCommentList.length; i++) {
        CommentModel _subComment = CommentModel.fromJson(_subCommentList[i]);
        Map<String, dynamic> _user = await _userDao.getOne(
          column: ["user_id", "username", "email", "avatar"],
          where: [Where("user_id", _subComment.user_id), Where("disable_time", null, 'IS')],
        );
        if (_user['avatar'] != null && _user['avatar'] is Blob) {
          _user['avatar'] = base64Encode((_user['avatar'] as Blob).toBytes());
        }
        _subCommentList[i] = {
          "user": _user,
          "comment": _subComment.toJson(),
        };
      }

      ///查层主
      Map<String, dynamic> _user = await _userDao.getOne(
        column: ["user_id", "username", "email", "avatar"],
        where: [Where("user_id", _comment.user_id), Where("disable_time", null, 'IS')],
      );
      if (_user['avatar'] != null && _user['avatar'] is Blob) {
        _user['avatar'] = base64Encode((_user['avatar'] as Blob).toBytes());
      }

      _listWithComment.add({
        "user": _user,
        "comment": _comment.toJson(),
        "subComment": _subCommentList,
      });
    }

    Map<String, dynamic> _pageInfo = {
      "total": ((_pageCount['COUNT(*)'] ?? 0) as int), //总共有多少条数据
      "returnDataCount": _listWithComment.length, //本次返回多少数据
      "pageSize": _pageSize, //每次应该返回多少条数据
    };

    return packData(SUCCESS, {"list": _listWithComment, "page": _pageInfo}, "获取评论列表成功");
  }

  ///获取当前用户点赞状态
  FutureOr<Response> _getLike() async {
    if (!(await validateToken())) return tokenExpired;
    UserModel? _user = await getTokenUser();
    if (_user == null) return userNotFind;

    int _id = await get<int>("id");
    int _type = await get<int>("type");

    GlobalDao _like = GlobalDao("like");

    Map<String, dynamic> _likeMap = await _like.getOne(
      where: [Where('up_id', _id), Where("user_id", _user.user_id), Where("up_type", _type), Where("delete", null, "IS")],
      order: "create_time DESC",
    );

    return packData(SUCCESS, _likeMap, "获取点赞信息成功");
  }

  ///获取帖子详情
  FutureOr<Response> _getBBSDetail() async {
    if (!(await validateToken())) return tokenExpired;
    int _id = await get<int>("id");
    final _bbsDao = GlobalDao("posts");
    Map<String, dynamic> _bbsJson = await _bbsDao.getOne(where: [Where("id", _id)]);
    if (_bbsJson.isEmpty) return packData(ERROR, null, "该贴不存在");
    final _bbs = BBSModel.fromJson(_bbsJson);
    if (_bbs.delete_time != null) return packData(ERROR, null, "该贴已被删除");
    final _userDao = GlobalDao("user");
    Map<String, dynamic> _userJson = await _userDao.getOne(where: [Where("user_id", _bbs.user_id)]);
    UserModel? _user;
    if (_userJson.isNotEmpty) {
      _user = UserModel.fromJson(_userJson);
    }
    return packData(SUCCESS, {"post": _bbs.toJson(), "user": _user?.toJson() ?? {}}, "OK");
  }

  ///搜索
  FutureOr<Response> _searchBBS() async {
    if (!(await validateToken())) return tokenExpired;
    String _search = await get<String>("search"); //搜索内容
    int _searchType = await get<int>("searchType"); //搜索类型0综合1问题2文章3帖子
    int _startIndex = await get<int>("startIndex"); //从第几条数据开始
    int _pageSize = await get<int>("pageSize"); //每次返回多少条数据
    if (_pageSize == 0) {
      _pageSize = 10;
    }
    if (_search.isEmpty) return packData(ERROR, null, "空的搜索内容");
    final _bbsDao = GlobalDao("posts");
    final _userDao = GlobalDao("user");
    List<Where> _where = [];
    if (_searchType != 0) {
      _where.add(Where('question_type', _searchType));
    }
    _where.add(Where("title", _search, "LIKE", "OR"));
    _where.add(Where("content", _search, "LIKE"));
    Map<String, dynamic> _countRet = await _bbsDao.getOne(column: ["COUNT(*)"], where: _where);
    List<Map<String, dynamic>> _ret = await _bbsDao.getList(
      where: _where,
      order: "update_time DESC",
      limit: Limit(limit: _pageSize, start: _startIndex),
    );
    if (_ret.isNotEmpty) {
      List<int> _userIdList = List.generate(_ret.length, (index) => _ret[index]['user_id'] ?? 0);
      List<Map<String, dynamic>> _userList =
          await _userDao.getList(column: ['user_id', 'avatar'], where: [Where("user_id", _userIdList, "IN")]);

      for (int i = 0; i < _ret.length; i++) {
        BBSModel _bbsModel = BBSModel.fromJson(_ret[i]);
        Map<String, dynamic> _post = _bbsModel.toJson();

        ///找用户
        int _index = _userList.indexWhere((element) => element['user_id'] == _bbsModel.user_id);
        if (_index != -1) {
          Map<String, dynamic> _user = _userList[_index];
          if (_user['avatar'] != null && _user['avatar'] is Blob) {
            _post['avatar'] = base64Encode((_user['avatar'] as Blob).toBytes());
          }
        }

        ///找图片
        // List<Blob> _images = await ImageDao.getImages(_bbsModel.id, _bbsModel.question_type);
        // _post['images'] = List.generate(_images.length, (index) => base64Encode(_images[index].toBytes())); //blob转base64
        // _postList[i] = _post;
        List<int> _imageIds = await ImageDao.getImageIds(_bbsModel.id, _bbsModel.question_type);
        _post['images'] = _imageIds;
        _ret[i] = _post;
      }
    }

    Map<String, dynamic> _pageInfo = {
      "total": ((_countRet['COUNT(*)'] ?? 0) as int), //总共有多少条数据
      "returnDataCount": _ret.length, //本次返回多少数据
      "pageSize": _pageSize, //每次应该返回多少条数据
    };

    return packData(SUCCESS, {"data": _ret, "page": _pageInfo}, "获取帖子列表成功");
  }

  ///删除评论
  FutureOr<Response> _deleteComment() async {
    if (!(await validateToken())) return tokenExpired;
    UserModel? _user = await getTokenUser();
    if (_user == null) return packData(ERROR, null, '查无此人');
    int _commentId = await get<int>("comment_id");
    final _commentDao = GlobalDao("comment");
    Map<String, dynamic> _chk = await _commentDao.getOne(where: [Where('id', _commentId)]);
    if (_chk.isEmpty || _chk['delete_time'] != null) return packData(ERROR, null, "评论不存在或已删除");
    Map<String, dynamic> _modify = {"delete_time": DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())};
    bool _ret = await _commentDao.update(_modify, where: [Where('id', _commentId)]);
    if (_ret) {
      return packData(SUCCESS, null, "OK");
    } else {
      return packData(ERROR, null, "删除评论失败");
    }
  }
}
