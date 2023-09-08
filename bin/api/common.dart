import 'dart:async';
import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:jaguar/jaguar.dart';

import '../db/bbs_dao.dart';
import '../db/comment_dao.dart';
import '../db/global_dao.dart';
import '../model/like_model.dart';
import '../model/user_bean.dart';
import 'base_api.dart';

class Common extends BaseApi {
  Common(Context ctx) : super(ctx);

  @override
  FutureOr<Response> method(String method) async {
    if (method == "checkLogin") return await _checkLogin();
    if (method == "like") return await _like();
    if (method == "unlike") return await _unlike();
    return Response(body: jsonEncode({}), statusCode: NOT_FOUND);
  }

  FutureOr<Response> _checkLogin() async {
    if (await validateToken()) {
      UserModel? _user = await getTokenUser();
      if (_user != null) {
        return packData(SUCCESS, {"user": _user.toJson()}, 'OK');
      } else {
        return tokenExpired;
      }
    } else {
      return tokenExpired;
    }
  }

  FutureOr<Response> _like() async {
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
          return packData(SUCCESS, null, '点赞成功');
        } else {
          return packData(ERROR, null, '点赞失败');
        }
      } else {
        return packData(ERROR, null, '未找到当前用户');
      }
    } else {
      return tokenExpired;
    }
  }

  ///取消点赞
  FutureOr<Response> _unlike() async {
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
          return packData(SUCCESS, null, '撤销点赞成功');
        } else {
          return packData(ERROR, null, '撤销点赞失败');
        }
      } else {
        return packData(ERROR, null, '未找到当前用户');
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
