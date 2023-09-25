import 'dart:async';
import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:jaguar/jaguar.dart';

import '../db/bbs_dao.dart';
import '../db/comment_dao.dart';
import '../db/global_dao.dart';
import '../model/like_model.dart';
import '../model/user_model.dart';
import 'base_api.dart';

class Common extends BaseApi {
  Common(Context ctx) : super(ctx);

  @override
  FutureOr<Response> method(String method) async {
    if (method == "checkLogin") return await _checkLogin(); //检查更新
    if (method == "like") return await _like(); //点赞
    if (method == "unlike") return await _unlike(); //撤销点赞
    if (method == "checkLike") return await _checkLike(); //检查是否点赞
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
        //检查是否已经点过赞
        Map<String, dynamic> _likeRet =
            await _likeDao.getOne(where: [Where("user_id", _user.user_id), Where("up_type", _type), Where("up_id", _upId)]);
        print(_likeRet);
        if (_likeRet.isNotEmpty && _likeRet['delete_time'] == null) return packData(SUCCESS, null, '已经点过赞了');
        bool _ret = false;
        if (_likeRet.isEmpty) {
          _ret = await _likeDao.insert(_like.toJson());
        } else {
          Map<String, dynamic> _update = {
            "delete_time": null,
            "update_time": DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now()),
          };
          _ret = await _likeDao.update(_update, where: [Where("user_id", _user.user_id), Where("up_type", _type), Where("up_id", _upId)]);
        }
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
        Map<String, dynamic> _likeJson =
            await _likeDao.getOne(where: [Where("user_id", _user.user_id), Where("up_id", _upId), Where("delete_time", null, "IS NOT")]);
        print(_likeJson);
        if (_likeJson.isNotEmpty) return packData(SUCCESS, null, "OK");
        bool _ret = await _likeDao.update({
          "delete_time": DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now()),
          "update_time": DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now()),
        }, where: [
          Where("user_id", _user.user_id),
          Where("up_id", _upId)
        ]);
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

  FutureOr<Response> _checkLike() async {
    if (!(await validateToken())) return tokenExpired;
    UserModel? _user = await getTokenUser();
    if (_user == null) return packData(ERROR, null, "未找到当前用户");
    int _likeType = await get<int>("likeType");
    int _likeId = await get<int>("likeId");
    final _likeDao = GlobalDao("like");
    Map<String, dynamic> _ret = await _likeDao.getOne(
        where: [Where("user_id", _user.user_id), Where("up_type", _likeType), Where("up_id", _likeId), Where("delete_time", null, "IS")]);
    return packData(SUCCESS, LikeModel.fromJson(_ret).toJson(), "OK");
  }
}
