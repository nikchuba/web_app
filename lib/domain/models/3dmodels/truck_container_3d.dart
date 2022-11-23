import 'dart:math';

import 'package:three_dart/three_dart.dart';
import 'package:web_app/domain/models/3dmodels/outline_3d.dart';

import 'model_3d.dart';

// ignore: must_be_immutable
class TruckContainer3D extends Model3D with Outline3D {
  TruckContainer3D({
    super.position,
    super.rotation,
    super.width,
    super.height,
    super.length,
    super.color,
    super.texture,
    super.textureRepeatCount,
  }) : super(name: 'truck');

  late Object3D truckBottom,
      truckRight,
      truckLeft,
      truckFront,
      truckBack,
      truckRoof;

  // List<Model3D> get _sideModels =>
  //     [truckBottom, truckRight, truckLeft, truckFront, truckBack, truckRoof];

  List<Object3D> get sides => [
        truckBottom,
        truckRight,
        truckLeft,
        truckFront,
        truckBack,
        truckRoof,
      ];

  @override
  Object3D getObject3D() {
    var posX = position.x, posY = position.y, posZ = position.z;
    var rotX = rotation.x, rotY = rotation.y, rotZ = rotation.z;
    var truck = Group()..name = name;

    var common = Model3D(texture: texture, type: Model3DType.plane);

    truckBottom = common
        .clone(
            name: 'truckBottom',
            width: length,
            height: 0.001,
            length: width,
            rotation: Vector3(0, 0, pi / 2))
        .getObject3D();
    truckFront = common
        .clone(
            name: 'truckFront',
            width: width,
            length: height,
            position: Vector3(0, length / 2, height / 2),
            rotation: Vector3(pi / 2, 0, 0))
        .getObject3D();
    truckRight = common
        .clone(
            name: 'truckRight',
            width: length,
            length: height,
            position: Vector3(width / 2, 0, height / 2),
            rotation: Vector3(pi / 2, -pi / 2, 0))
        .getObject3D();
    truckLeft = common
        .clone(
            name: 'truckLeft',
            width: length,
            length: height,
            position: Vector3(-width / 2, 0, height / 2),
            rotation: Vector3(pi / 2, pi / 2, 0))
        .getObject3D();
    truckBack = common
        .clone(
            name: 'truckBack',
            width: width,
            length: height,
            position: Vector3(0, -length / 2, height / 2),
            rotation: Vector3(pi / 2, pi, 0))
        .getObject3D();
    truckRoof = common
        .clone(
            name: 'truckRoof',
            width: length,
            length: width,
            position: Vector3(0, 0, height + 0.001 + 0.000001),
            rotation: Vector3(pi, 0, pi / 2))
        .getObject3D();

    for (var side in sides) {
      var outline = getOutline(side);
      truck.add(outline);
    }
    return truck
      ..addAll(sides)
      ..position = position
      ..rotation.x = rotation.x
      ..rotation.y = rotation.y
      ..rotation.z = rotation.z;
  }
}
