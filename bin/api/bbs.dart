import 'dart:convert';

import 'package:jaguar/http/context/context.dart';
import 'package:jaguar/http/response/response.dart';

import 'dart:async';

import '../db/bbs_dao.dart';
import '../db/global_dao.dart';
import '../model/bbs_model.dart';
import '../model/comment_model.dart';
import '../model/response.dart';
import '../model/user_bean.dart';
import '../server.dart';
import 'base_api.dart';

///论坛请求类
class BBS extends BaseApi {
  BBS(Context ctx) : super(ctx);

  @override
  FutureOr<Response> method(String method) {
    if (method == "addBBS") return _addBBS();
    if (method == "addComment") return _addComment();
    if (method == "getBBSList") return _getBBSList();
    if (method == "getBBSComment") return _getBBSComment();
    return Response(body: jsonEncode({}), statusCode: Server.NOT_FOUND);
  }

  ///添加帖子或问题
  FutureOr<Response> _addBBS() async {
    ResponseBean responseBean = ResponseBean();
    if (!(await validateToken())) return tokenExpired;

    UserModel? _user = await getTokenUser();

    if (_user == null) {
      responseBean.code = Server.ERROR;
      responseBean.msg = "未找到当前用户";
      return Response(statusCode: responseBean.code, body: responseBean.toJsonString());
    }

    String title = await get<String>("title");
    String content = await get<String>("content");
    int type = await get<int>("type"); // 1问题2文章3帖子

    if (title.isEmpty) {
      responseBean.code = Server.ERROR;
      responseBean.msg = "标题不能为空";
      return Response(statusCode: responseBean.code, body: responseBean.toJsonString());
    }

    if (content.isEmpty) {
      responseBean.code = Server.ERROR;
      responseBean.msg = "内容不能为空";
      return Response(statusCode: responseBean.code, body: responseBean.toJsonString());
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
    bool _ret = await _bbsDao.insert(_bbsJson);

    if (_ret) {
      responseBean.code = Server.SUCCESS;
      responseBean.msg = "添加成功";
      return Response(statusCode: responseBean.code, body: responseBean.toJsonString());
    } else {
      responseBean.code = Server.ERROR;
      responseBean.msg = "添加失败";
      return Response(statusCode: responseBean.code, body: responseBean.toJsonString());
    }
  }

  ///添加评论
  FutureOr<Response> _addComment() async {
    ResponseBean responseBean = ResponseBean();
    if (!(await validateToken())) return tokenExpired;

    UserModel? _user = await getTokenUser();

    if (_user == null) {
      responseBean.code = Server.ERROR;
      responseBean.msg = "未找到当前用户";
      return Response(statusCode: responseBean.code, body: responseBean.toJsonString());
    }

    String comment = await get<String>("comment");
    int comment_id = await get<int>("comment_id");
    int sub_comment_id = await get<int>("sub_comment_id");
    int type = await get<int>("type");

    if (comment.isEmpty) {
      responseBean.code = Server.ERROR;
      responseBean.msg = "评论不能为空";
      return Response(statusCode: responseBean.code, body: responseBean.toJsonString());
    }

    GlobalDao _bbsDao = GlobalDao("posts");
    GlobalDao _commentDao = GlobalDao("comment");

    ///TODO:楼中楼的话判断是否评论被删除
    if (type == CommentModel.TYPE_SUB_COMMENT) {
      Map<String, dynamic> _commentInComment = await _commentDao.getOne(where: [Where("id", comment_id), Where("delete_time", null, "is")]);
      if (_commentInComment.isEmpty) {
        responseBean.code = Server.ERROR;
        responseBean.msg = "评论被删除或不存在";
        return Response(statusCode: responseBean.code, body: responseBean.toJsonString());
      }
    }

    ///统一判断帖子是否被删除
    Map<String, dynamic> _bbsComment = await _bbsDao.getOne(where: [Where("id", comment_id)]);
    if (_bbsComment.isEmpty || _bbsComment['delete_time'] != null) {
      responseBean.code = Server.ERROR;
      responseBean.msg = "${type == 1 ? '文章' : '帖子'}被删除或不存在";
      return Response(statusCode: responseBean.code, body: responseBean.toJsonString());
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

    bool _ret = await _commentDao.insert(_commentModel);
    if (_ret) {
      ///TODO：帖子回复数量+1
      if (type == CommentModel.TYPE_SUB_COMMENT) {
        //楼中楼暂不计入回复数量
      } else {
        BBSDao _bbsDao = BBSDao();
        await _bbsDao.addComment(comment_id);
      }

      responseBean.code = Server.SUCCESS;
      responseBean.msg = "添加成功";
      return Response(statusCode: responseBean.code, body: responseBean.toJsonString());
    } else {
      responseBean.code = Server.ERROR;
      responseBean.msg = "添加失败";
      return Response(statusCode: responseBean.code, body: responseBean.toJsonString());
    }
  }

  ///获取帖子列表
  FutureOr<Response> _getBBSList() async {
    ResponseBean responseBean = ResponseBean();
    if (!(await validateToken())) return tokenExpired;

    GlobalDao _bbsDao = GlobalDao("posts");

    List<Map<String, dynamic>> _postList = await _bbsDao.getList(where: [Where("delete_time", null, "is")], order: "update_time DESC");
    for (int i = 0; i < _postList.length; i++) {
      BBSModel _bbsModel = BBSModel.fromJson(_postList[i]);
      _postList[i] = _bbsModel.toJson();
    }

    responseBean.code = Server.SUCCESS;
    responseBean.msg = "获取帖子列表成功";
    responseBean.result = {"data": _postList};
    return Response(statusCode: responseBean.code, body: responseBean.toJsonString());
  }

  ///获取评论
  FutureOr<Response> _getBBSComment() async {
    ResponseBean responseBean = ResponseBean();
    if (!(await validateToken())) return tokenExpired;
    int _id = await get<int>("id"); //文章，帖子，问答id
    int _page = await get<int>("page"); //第几页
    int _pageSize = await get<int>("pageSize"); //一次返回多少条数据

    if (_pageSize == 0) {
      _pageSize = 10;
    }

    if (_page - 1 < 0) {
      _page = 1;
    }

    ///查贴
    GlobalDao _bbsDao = GlobalDao('posts');
    Map<String, dynamic> _bbsJson = await _bbsDao.getOne(where: [Where("id", _id)]);
    if (_bbsJson.isEmpty) {
      responseBean.code = Server.ERROR;
      responseBean.msg = "查无此贴";
      return Response(statusCode: responseBean.code, body: responseBean.toJsonString());
    }
    BBSModel _bbs = BBSModel.fromJson(_bbsJson);

    ///查评论
    GlobalDao _commentDao = GlobalDao("comment");
    List<Map<String, dynamic>> _list = await _commentDao.getList(
      where: [Where("comment_id", _bbs.id), Where("comment_type", _bbs.question_type)],
      limit: Limit(limit: _pageSize, start: (_page - 1) * _pageSize),
      order: "create_time DESC",
    );

    GlobalDao _userDao = GlobalDao("user");

    ///查楼中楼
    List<Map<String, dynamic>> _listWithComment = [];
    for (Map<String, dynamic> _commentMap in _list) {
      ///每层默认显示两条楼中楼
      CommentModel _comment = CommentModel.fromJson(_commentMap);
      List<Map<String, dynamic>> _subCommentList = await _commentDao.getList(
        where: [
          Where("comment_id", _comment.id),
          Where("comment_type", CommentModel.TYPE_SUB_COMMENT),
          Where("delete_time", null, "IS"),
        ],
        limit: Limit(limit: 2),
        order: "create_time DESC",
      );

      ///查用户
      for (int i = 0; i < _subCommentList.length; i++) {
        CommentModel _subComment = CommentModel.fromJson(_subCommentList[i]);
        Map<String, dynamic> _user = await _userDao.getOne(
          column: ["user_id", "username", "email"],
          where: [Where("user_id", _subComment.user_id), Where("disable_time", null, 'IS')],
        );
        _subCommentList[i] = {
          "user": _user,
          "comment": _subComment.toJson(),
        };
      }

      ///查层主
      Map<String, dynamic> _user = await _userDao.getOne(
        column: ["user_id", "username", "email"],
        where: [Where("user_id", _comment.user_id), Where("disable_time", null, 'IS')],
      );

      _listWithComment.add({
        "user": _user,
        "commnet": _comment.toJson(),
        "subComment": _subCommentList,
      });
    }

    responseBean.code = Server.SUCCESS;
    responseBean.msg = "获取评论列表成功";
    responseBean.result = {"list": _listWithComment};
    return Response(statusCode: responseBean.code, body: responseBean.toJsonString());
  }
}
