import 'package:three_dart/three_dart.dart';

mixin Outline3D {
  Object3D getOutline(Object3D object) {
    final pos = object.position;
    final rot = object.rotation;
    var grid = EdgesGeometry(object.geometry!, 1);
    var edge = LineSegments(grid, LineBasicMaterial({'color': 0x000000}))
      ..visible = false;
    return edge
      ..name = '${object.name}-outline'
      ..rotation.x = rot.x
      ..rotation.y = rot.y
      ..rotation.z = rot.z
      ..position.x = pos.x
      ..position.y = pos.y
      ..position.z = pos.z;
  }
}
