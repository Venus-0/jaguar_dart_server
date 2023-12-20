import 'package:mysql1/mysql1.dart';

import 'mysql.dart';

class Limit {
  final int start;
  final int limit;
  Limit({this.start = 0, required this.limit});
}

class Where {
  final String key;
  final Object? value;
  final String operator;
  final String cond;
  Where(this.key, [this.value, this.operator = "=", this.cond = "AND"]);
}

class GlobalDao {
  final String tableName;
  GlobalDao(this.tableName);

  Future<Map<String, dynamic>> getOne({
    List<String> column = const [],
    List<Where> where = const [],
    String order = "",
    Limit? limit,
    String groupBy = "",
  }) async {
    MySqlConnection conn = await Mysql.getDB();
    String _column = column.isEmpty ? "*" : column.join(",");
    String _where = "";
    List<Object?>? _whereList;

    ///构建where
    if (where.isNotEmpty) {
      _whereList = [];
      for (int i = 0; i < where.length; i++) {
        Where _value = where[i];
        if (_value.operator == "=") {
          _where += "`${_value.key}` = ?";
          _whereList.add(_value.value);
        } else {
          if (_value.operator == "IN") {
            _where += '`${_value.key}` IN (${List.generate((_value.value as List).length, (index) => "?").join(",")})';
            _whereList.addAll(_value.value as List);
          } else if (_value.operator == "LIKE") {
            _where += '`${_value.key}` LIKE "%${_value.value}%"';
          } else {
            _where += "`${_value.key}` ${_value.operator} ${_value.value}";
          }
        }
        if (i + 1 < where.length) {
          _where += " ${_value.cond} ";
        }
      }
    }

    ///初始sql
    String _sql = "SELECT $_column FROM `$tableName`";

    ///拼接where
    if (_where.isNotEmpty) {
      _sql += " WHERE $_where";
    }

    ///拼接group
    if (groupBy.isNotEmpty) {
      _sql += " GROUP BY $groupBy";
    }

    ///拼接order
    if (order.isNotEmpty) {
      _sql += " ORDER BY $order";
    }

    ///拼接limit
    if (limit != null) {
      _sql += " LIMIT ${limit.start},${limit.limit}";
    }
    print("[DAO][$tableName] SQL: $_sql  $_whereList");
    Results _res = await conn.query(_sql, _whereList);
    if (_res.isEmpty) {
      return {};
    }
    return _res.first.fields;
  }

  Future<List<Map<String, dynamic>>> getList({
    List<String> column = const [],
    List<Where> where = const [],
    String order = "",
    Limit? limit,
    String groupBy = "",
  }) async {
    MySqlConnection conn = await Mysql.getDB();
    String _column = column.isEmpty ? "*" : column.join(",");
    String _where = "";
    List<Object?>? _whereList;

    ///构建where
    if (where.isNotEmpty) {
      _whereList = [];
      for (int i = 0; i < where.length; i++) {
        Where _value = where[i];
        if (_value.operator == "=") {
          _where += "`${_value.key}` = ?";
          _whereList.add(_value.value);
        } else {
          if (_value.operator == "IN") {
            _where += '`${_value.key}` IN (${List.generate((_value.value as List).length, (index) => "?").join(",")})';
            _whereList.addAll(_value.value as List);
          } else if (_value.operator == "LIKE") {
            _where += '`${_value.key}` LIKE "%${_value.value}%"';
          } else {
            _where += "`${_value.key}` ${_value.operator} ${_value.value}";
          }
        }
        if (i + 1 < where.length) {
          _where += " ${_value.cond} ";
        }
      }
    }

    ///初始化sql语句
    String _sql = "SELECT $_column FROM `$tableName`";

    ///拼接where
    if (_where.isNotEmpty) {
      _sql += " WHERE $_where";
    }

    ///拼接group
    if (groupBy.isNotEmpty) {
      _sql += " GROUP BY $groupBy";
    }

    ///拼接roder
    if (order.isNotEmpty) {
      _sql += " ORDER BY $order";
    }

    ///拼接limit
    if (limit != null) {
      _sql += " LIMIT ${limit.start},${limit.limit}";
    }
    print("[DAO][$tableName] SQL: $_sql VALUE:$_whereList ");
    Results _res = await conn.query(_sql, _whereList);
    List<Map<String, dynamic>> _list = [];
    for (final row in _res) {
      _list.add(row.fields);
    }
    return _list;
  }

  Future<bool> update(
    Map<String, dynamic> value, {
    List<Where> where = const [],
  }) async {
    if (value.isEmpty) return false;
    MySqlConnection conn = await Mysql.getDB();
    List<Object?> _whereList = [];
    String _set = '';

    ///构建value
    value.forEach((key, value) {
      _set += "`$key` = ? ,";
      _whereList.add(value);
    });

    ///构建set
    if (value.isNotEmpty) {
      _set = _set.substring(0, _set.length - 1);
    }

    ///构建where
    String _where = "";
    if (where.isNotEmpty) {
      for (int i = 0; i < where.length; i++) {
        Where _value = where[i];
        if (_value.operator == "=") {
          _where += "`${_value.key}` = ?";
          _whereList.add(_value.value);
        } else {
          if (_value.operator == "IN") {
            _where += '`${_value.key}` IN (${List.generate((_value.value as List).length, (index) => "?").join(",")})';
            _whereList.addAll(_value.value as List);
          } else if (_value.operator == "LIKE") {
            _where += '`${_value.key}` LIKE "%${_value.value}%"';
          } else {
            _where += "`${_value.key}` ${_value.operator} ${_value.value}";
          }
        }
        if (i + 1 < where.length) {
          _where += " ${_value.cond} ";
        }
      }
    }

    ///初始化sql
    String _sql = "UPDATE `$tableName` SET $_set";

    ///拼接where
    if (_where.isNotEmpty) {
      _sql += " WHERE $_where";
    }
    print("[DAO][$tableName] SQL: $_sql ${_whereList}");
    Results _res = await conn.query(_sql, _whereList);
    return (_res.affectedRows ?? 0) >= 1;
  }

  Future<bool> insert(Map<String, dynamic> data) async {
    MySqlConnection conn = await Mysql.getDB();
    if (data.isEmpty) return false;

    List<String> columns = List.generate(data.keys.toList().length, (index) => "`${data.keys.toList()[index]}`");
    String _sql =
        "INSERT INTO `$tableName` (${columns.join(",")}) VALUES (${List.generate(data.keys.toList().length, (index) => "?").join(',')})";
    print("[DAO][$tableName] SQL: $_sql");
    Results _res = await conn.query(_sql, data.values.toList());
    return (_res.affectedRows ?? 0) >= 1;
  }

  ///批量插入
  Future<bool> insertMulti(List<Map<String, dynamic>> datas) async {
    MySqlConnection conn = await Mysql.getDB();
    if (datas.isEmpty) return false;
    Map<String, dynamic> data = datas[0];
    if (data.isEmpty) return false;
    List<String> columns = List.generate(data.keys.toList().length, (index) => "`${data.keys.toList()[index]}`");
    String values =
        List.generate(datas.length, (index) => "(${List.generate(datas[index].keys.toList().length, (dataIndex) => "?").join(',')})")
            .join(',');

    String _sql = "INSERT INTO `$tableName` (${columns.join(",")}) VALUES $values";
    print("[DAO][$tableName] SQL: $_sql");
    List<dynamic> queryDatas = [];
    for (Map<String, dynamic> _data in datas) {
      queryDatas.addAll(_data.values.toList());
    }
    Results _res = await conn.query(_sql, queryDatas);
    return (_res.affectedRows ?? 0) >= 1;
  }

  ///插入数据返回插入id
  Future<int> insertReturnId(Map<String, dynamic> data) async {
    MySqlConnection conn = await Mysql.getDB();
    if (data.isEmpty) return 0;

    List<String> columns = List.generate(data.keys.toList().length, (index) => "`${data.keys.toList()[index]}`");
    String _sql =
        "INSERT INTO `$tableName` (${columns.join(",")}) VALUES (${List.generate(data.keys.toList().length, (index) => "?").join(',')})";
    print("[DAO][$tableName] SQL: $_sql");
    Results _res = await conn.query(_sql, data.values.toList());
    return _res.insertId ?? 0;
  }
}
