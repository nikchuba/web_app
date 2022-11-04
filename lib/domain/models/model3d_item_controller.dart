import 'package:flutter/material.dart';
import 'package:web_app/domain/models/model3d_item.dart';

class Model3DItemController extends ChangeNotifier {
  Model3DItemController(
    Model3DItem? item
  ) : 
  _offset = item?.offset ?? const Offset(0, 0),
  _color = item?.color,
  _imageSrc = item?.imageSrc
  ;

  Offset _offset;
  Color? _color;
  String? _imageSrc;

  Offset get offset => _offset;
  Color get color => _color ?? Colors.amber;
  String get imageSrc => _imageSrc ?? '';
  
  set offset(Offset value) {
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