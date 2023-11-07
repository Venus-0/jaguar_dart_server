import 'package:mysql1/mysql1.dart';

import '../model/image_model.dart';
import 'global_dao.dart';

class ImageDao {
  ///添加图片
  static Future<bool> addImages(int bbsId, int type, int userId, List<Blob> images) async {
    List<Map<String, dynamic>> _insertData = [];
    for (Blob _image in images) {
      ImageModel _imageModel = ImageModel(file_data: _image, create_time: DateTime.now(), type: type, type_id: bbsId, user_id: userId);
      _insertData.add(_imageModel.toJson()..remove('id'));
    }

    GlobalDao _imageDao = GlobalDao("image");
    return _imageDao.insertMulti(_insertData);
  }

  ///查找图片
  static Future<List<Blob>> getImages(int bbsId,int type) async{
    GlobalDao _imageDao = GlobalDao("image");
    List<Map<String,dynamic>> _list = await _imageDao.getList(column: ['file_data'],where: [Where("type_id",bbsId),Where("type",type)],order: "id DESC");
    List<Blob> _images = List.generate(_list.length, (index) => _list[index]['file_data']);
    return _images;
  }
}
