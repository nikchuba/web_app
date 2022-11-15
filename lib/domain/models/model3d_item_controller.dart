import 'package:flutter/material.dart';
import 'package:three_dart/three3d/math/vector3.dart';
import 'package:web_app/domain/models/model3d_item.dart';

class Model3DItemController extends ChangeNotifier {
  Model3DItemController(
    Model3DItem? item
  ) : 
  _offset = item?.position ?? Vector3(),
  _color = item?.color,
  _imageSrc = item?.imageSrc
  ;

  Vector3 _offset;
  Color? _color;
  String? _imageSrc;

  Vector3 get offset => _offset;
  Color get color => _color ?? Colors.amber;
  String get imageSrc => _imageSrc ?? '';
  
  set offset(Vector3 value) {
    _offset = value;
    notifyListeners();
  }
  set color(Color value) {
    _color = value;
    notifyListeners();
  }
  set imageSrc(String value) {
    _imageSrc = value;
    notifyListeners();
  }
}