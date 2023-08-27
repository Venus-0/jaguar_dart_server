import 'dart:math';

import 'package:intl/intl.dart';

import 'global_dao.dart';

class BBSDao {
  late GlobalDao _globalDao;

  BBSDao() {
    _globalDao = GlobalDao("posts");
  }

  ///点赞+1
  Future<bool> addLike(int id) async {
    Map<String, dynamic> _postJson = await _globalDao.getOne(where: [Where("id", id)], column: ['up_count']);
    if (_postJson.isEmpty) return false;
    _postJson['up_count'] = (_postJson['up_count'] ?? 0) + 1;
    _postJson['update_time'] = DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now());
    bool _ret = await _globalDao.update(_postJson, where: [Where("id", id)]);
    return _ret;
  }

  ///点赞-1
  Future<bool> subLike(int id) async {
    Map<String, dynamic> _postJson = await _globalDao.getOne(where: [Where("id", id)], column: ['up_count']);
    if (_postJson.isEmpty) return false;
    _postJson['up_count'] = max<int>(0, (_postJson['up_count'] ?? 0) + 1);
    _postJson['update_time'] = DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now());
    bool _ret = await _globalDao.update(_postJson, where: [Where("id", id)]);
    return _ret;
  }

  ///评论数+1
  Future<bool> addComment(int id) async {
    Map<String, dynamic> _postJson = await _globalDao.getOne(where: [Where("id", id)], column: ['reply_count']);
    if (_postJson.isEmpty) return false;
    _postJson['up_count'] = (_postJson['reply_count'] ?? 0) + 1;
    _postJson['update_time'] = DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now());
    bool _ret = await _globalDao.update(_postJson, where: [Where("id", id)]);
    return _ret;
  }

  ///评论数-1
  Future<bool> subComment(int id) async {
    Map<String, dynamic> _postJson = await _globalDao.getOne(where: [Where("id", id)], column: ['reply_count']);
    if (_postJson.isEmpty) return false;
    _postJson['up_count'] = max<int>(0, (_postJson['reply_count'] ?? 0) + 1);
    _postJson['update_time'] = DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now());
    bool _ret = await _globalDao.update(_postJson, where: [Where("id", id)]);
    return _ret;
  }
}
