import 'dart:async';
import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:jaguar/jaguar.dart';
import 'package:mysql1/mysql1.dart';

import '../db/bbs_dao.dart';
import '../db/comment_dao.dart';
import '../db/global_dao.dart';
import '../db/mysql.dart';
import '../db/sessionDao.dart';
import '../model/like_model.dart';
import '../model/response.dart';
import '../model/user_bean.dart';
import '../server.dart';
import 'base_api.dart';

class Common extends BaseApi {
  Common(Context ctx) : super(ctx);

  @override
  FutureOr<Response> method(String method) async {
    if (method == "test") return await serverTest();
    if (method == "checkLogin") return await _checkLogin();
    if (method == "like") return await _like();
    if (method == "unlike") return await _unlike();
    return Response(body: jsonEncode({}), statusCode: Server.NOT_FOUND);
  }

  FutureOr<Response> serverTest() async {
    UserModel? _user = await getTokenUser();

    if (_user != null) {
      print(_user.toJson());
    } else {
      print("---NULL---");
    }

    ResponseBean responseBean = ResponseBean();
    responseBean.msg = "114514";
    return Response(statusCode: responseBean.code, body: responseBean.toJsonString());
  }

  FutureOr<Response> _checkLogin() async {
    ResponseBean responseBean = ResponseBean();
    if (await validateToken()) {
      UserModel? _user = await getTokenUser();
      if (_user != null) {
        responseBean.code = Server.SUCCESS;
        responseBean.msg = "OK";
        responseBean.result = {"user": _user.toJson()};
        return Response(statusCode: responseBean.code, body: responseBean.toJsonString());
      } else {
        return tokenExpired;
      }
    } else {
      return tokenExpired;
    }
  }

  FutureOr<Response> _like() async {
    ResponseBean responseBean = ResponseBean();
    if (await validateToken()) {
      UserModel? _user = await getTokenUser();
      if (_user != null) {
        int _type = await get<int>("up_type");
        int _upId = await get<int>("up_id");
        LikeModel _like = LikeModel(user_id: _user.user_id, up_type: _type, up_id: _upId, create_time: DateTime.now());

        GlobalDao _likeDao = GlobalDao("like");
        bool _ret = await _likeDao.insert(_like.toJson());
        if (_ret) {
          ///对应文章/问答/帖子/评论点赞+1
          if (_type == LikeModel.TYPE_COMMENT) {
            await CommentDao().addLike(_upId);
          } else {
            await BBSDao().addLike(_upId);
          }
          responseBean.code = Server.SUCCESS;
          responseBean.msg = "点赞成功";
          return Response(statusCode: responseBean.code, body: responseBean.toJsonString());
        } else {
          responseBean.code = Server.ERROR;
          responseBean.msg = "点赞失败";
          return Response(statusCode: responseBean.code, body: responseBean.toJsonString());
        }
      } else {
        responseBean.code = Server.ERROR;
        responseBean.msg = "未找到当前用户";
        return Response(statusCode: responseBean.code, body: responseBean.toJsonString());
      }
    } else {
      return tokenExpired;
    }
  }

  ///取消点赞
  FutureOr<Response> _unlike() async {
    ResponseBean responseBean = ResponseBean();
    if (await validateToken()) {
      UserModel? _user = await getTokenUser();
      if (_user != null) {
        int _type = await get<int>("up_type");
        int _upId = await get<int>("up_id");
        GlobalDao _likeDao = GlobalDao("like");
        Map<String, dynamic> _likeJson = await _likeDao.getOne(where: [Where("user_id", _user.user_id), Where("up_id", _upId)]);
        _likeJson['delete_time'] = DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now());

        bool _ret = await _likeDao.update(_likeJson, where: [Where("user_id", _user.user_id), Where("up_id", _upId)]);
        if (_ret) {
          ///对应文章/问答/帖子/评论点赞-1
          if (_type == LikeModel.TYPE_COMMENT) {
            await CommentDao().subLike(_upId);
          } else {
            await BBSDao().subLike(_upId);
          }
          responseBean.code = Server.SUCCESS;
          responseBean.msg = "撤销点赞成功";
          return Response(statusCode: responseBean.code, body: responseBean.toJsonString());
        } else {
          responseBean.code = Server.ERROR;
          responseBean.msg = "点赞失败";
          return Response(statusCode: responseBean.code, body: responseBean.toJsonString());
        }
      } else {
        responseBean.code = Server.ERROR;
        responseBean.msg = "未找到当前用户";
        return Response(statusCode: responseBean.code, body: responseBean.toJsonString());
      }
    } else {
      return tokenExpired;
    }
  }

  // FutureOr<Response> getBBSComment() async {
  //   ResponseBean responseBean = ResponseBean();
  //   if (!(await validateToken())) return tokenExpired;


  // }
}
