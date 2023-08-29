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
  }) async {
    MySqlConnection conn = await Mysql.getDB();
    String _column = column.isEmpty ? "*" : column.join(",");
    String _where = "";
    List<Object?>? _whereList;

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
            _where += "`${_value.key}` LIKE ${_value.value}";
          } else {
            _where += "`${_value.key}` ${_value.operator} ${_value.value}";
          }
        }
        if (i + 1 < where.length) {
          _where += " ${_value.cond} ";
        }
      }
    }

    String _sql = "SELECT $_column FROM $tableName";
    if (_where.isNotEmpty) {
      _sql += " WHERE $_where";
    }

    if (order.isNotEmpty) {
      _sql += " ORDER BY $order";
    }

    if (limit != null) {
      _sql += " LIMIT ${limit.start},${limit.limit}";
    }
    print("[DAO][$tableName] SQL: $_sql");
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
  }) async {
    MySqlConnection conn = await Mysql.getDB();
    String _column = column.isEmpty ? "*" : column.join(",");
    String _where = "";
    List<Object?>? _whereList;

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
            _where += "`${_value.key}` LIKE ${_value.value}";
          } else {
            _where += "`${_value.key}` ${_value.operator} ${_value.value}";
          }
        }
        if (i + 1 < where.length) {
          _where += " ${_value.cond} ";
        }
      }
    }

    String _sql = "SELECT $_column FROM $tableName";
    if (_where.isNotEmpty) {
      _sql += " WHERE $_where";
    }

    if (order.isNotEmpty) {
      _sql += " ORDER BY $order";
    }

    if (limit != null) {
      _sql += " LIMIT ${limit.start},${limit.limit}";
    }
    Results _res = await conn.query(_sql, _whereList);
    List<Map<String, dynamic>> _list = [];
    for (final row in _res) {
      _list.add(row.fields);
    }
    print("[DAO][$tableName] SQL: $_sql VALUE:$_whereList  RES:$_list");
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
    value.forEach((key, value) {
      _set += "$key = ? ,";
      _whereList.add(value);
    });

    if (value.isNotEmpty) {
      _set = _set.substring(0, _set.length - 1);
    }

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
            _where += "`${_value.key}` LIKE ${_value.value}";
          } else {
            _where += "`${_value.key}` ${_value.operator} ${_value.value}";
          }
        }
        if (i + 1 < where.length) {
          _where += " ${_value.cond} ";
        }
      }
    }
    String _sql = "UPDATE $tableName SET $_set";

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
        "INSERT INTO $tableName (${columns.join(",")}) VALUES (${List.generate(data.keys.toList().length, (index) => "?").join(',')})";
    print("[DAO][$tableName] SQL: $_sql");
    Results _res = await conn.query(_sql, data.values.toList());
    return (_res.affectedRows ?? 0) >= 1;
  }
}
