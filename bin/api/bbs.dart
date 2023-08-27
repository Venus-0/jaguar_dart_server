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
    if (method == "addBBS") return addBBS();
    return Response(body: jsonEncode({}), statusCode: Server.NOT_FOUND);
  }

  ///添加帖子或问题
  FutureOr<Response> addBBS() async {
    ResponseBean responseBean = ResponseBean();
    if (!(await validateToken())) {
      responseBean.code = Server.TOKEN_EXPIRED;
      responseBean.msg = "身份验证过期";
      return Response(statusCode: responseBean.code, body: responseBean.toJsonString());
    }

    UserModel? _user = await getTokenUser();

    if (_user == null) {
      responseBean.code = Server.ERROR;
      responseBean.msg = "未找到当前用户";
      return Response(statusCode: responseBean.code, body: responseBean.toJsonString());
    }

    String title = await get<String>("title");
    String content = await get<String>("content");
    int type = await get<int>("type"); // 1问题2文章帖子

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

    BBSModel _bbs = BBSModel(user_id: _user.user_id, title: title, content: content, question_type: type, create_time: DateTime.now());
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

  FutureOr<Response> addComment() async {
    ResponseBean responseBean = ResponseBean();
    if (!(await validateToken())) {
      responseBean.code = Server.TOKEN_EXPIRED;
      responseBean.msg = "身份验证过期";
      return Response(statusCode: responseBean.code, body: responseBean.toJsonString());
    }

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
    if (type == CommentModel.TYPE_COMMENT) {
      Map<String, dynamic> _commentInComment = await _commentDao.getOne(where: [Where("comment_id", comment_id)]);
      if (_commentInComment.isEmpty || _commentInComment['delete_time'] != null) {
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

    Map<String, dynamic> _commentModel = CommentModel(
      comment: comment,
      comment_id: comment_id,
      sub_comment_id: sub_comment_id != 0 ? sub_comment_id : null,
      comment_type: type,
      create_time: DateTime.now(),
    ).toJson();

    _commentModel.remove("id");

    bool _ret = await _commentDao.insert(_commentModel);
    if (_ret) {
      ///TODO：帖子回复数量+1
      if (type == 3) {
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
}
