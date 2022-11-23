import 'dart:math';
import 'model_3d.dart';
import 'package:three_dart/three_dart.dart';

// ignore: must_be_immutable
class Ground3D extends Model3D {
  Ground3D({
    super.width = 10,
    super.length = 10,
    super.texture,
    super.textureRepeatCount,
  }) : super(
          name: 'ground',
          type: Model3DType.plane,
        );
  @override
  Object3D getObject3D() {
    var ground = Group();
    var mesh = Mesh(getGeometry(), getMaterial());
    var grid = GridHelper(width, width ~/ 2, 0xcccccc, 0xcccccc)
      ..rotation.x = pi / 2
      ..visible = false;
    ground.addAll([mesh, grid]);
    return ground
      ..name = name
      ..receiveShadow = receiveShadow
      ..castShadow = castShadow
      ..rotation.x =
          type == Model3DType.plane ? rotation.x : rotation.x + pi / 2
      ..rotation.y = rotation.y
      ..rotation.z = rotation.z
      ..position.x = position.x
      ..position.y = position.y
      ..position.z = position.z + height / 2;
  }
}
