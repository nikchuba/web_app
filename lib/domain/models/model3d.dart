import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:three_dart/three_dart.dart' hide Color;
import 'package:three_dart/three3d/math/color.dart' as three;
import 'dart:ui';

export 'package:three_dart/three3d/core/index.dart';
export 'package:three_dart/three3d/math/vector3.dart';

enum Model3DType { box, cylinder, plane }

// ignore: must_be_immutable
class Model3D extends Equatable {
  Model3D({
    this.name = '',
    Vector3? position,
    Vector3? rotation,
    this.width = 0,
    this.height = 0,
    this.length = 0,
    this.type = Model3DType.box,
    this.color = const Color.fromRGBO(200, 200, 200, 1),
    this.castShadow = false,
    this.receiveShadow = false,
    this.randomColor = false,
    this.texture,
    this.textureRepeatCount,
  })  : position = position ?? Vector3(),
        rotation = rotation ?? Vector3();

  String name;
  Vector3 position, rotation;
  double width, height, length;
  Model3DType type = Model3DType.box;
  Color color;
  bool castShadow, receiveShadow, randomColor;
  Texture? texture;
  double? textureRepeatCount;

  Model3D clone({
    String? name,
    Vector3? position,
    Vector3? rotation,
    double? width,
    double? height,
    double? length,
    Model3DType? type,
    bool? randomColor,
    Color? color,
    bool? castShadow,
    bool? receiveShadow,
    Texture? texture,
    double? textureRepeatCount,
  }) {
    return Model3D(
      name: name ?? this.name,
      position: position ?? this.position,
      rotation: rotation ?? this.rotation,
      width: width ?? this.width,
      height: height ?? this.height,
      length: length ?? this.length,
      type: type ?? this.type,
      color: color ?? this.color,
      castShadow: castShadow ?? this.castShadow,
      receiveShadow: receiveShadow ?? this.receiveShadow,
      randomColor: randomColor ?? this.randomColor,
      texture: texture ?? this.texture,
      textureRepeatCount: textureRepeatCount ?? this.textureRepeatCount,
    );
  }

  Object3D getObject3D() {
    var mesh = Mesh(getGeometry(), getMaterial());
    return mesh
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

  BufferGeometry getGeometry() {
    switch (type) {
      case Model3DType.box:
        return BoxGeometry(width, height, length);
      case Model3DType.cylinder:
        return CylinderGeometry(width, length, height, 100);
      case Model3DType.plane:
        return PlaneGeometry(width, length);
      default:
        return BoxGeometry(width, height, length);
    }
  }

  Material getMaterial() {
    if (randomColor) _setRandomColor();
    if (texture != null && textureRepeatCount != null) {
      texture!
        ..wrapS = RepeatWrapping
        ..wrapT = RepeatWrapping
        ..repeat.set(textureRepeatCount!, textureRepeatCount!);
    }
    var params = {
      "color": three.Color.setRGB255(color.red, color.green, color.blue),
      "transparent": true,
      if (texture != null) "map": texture,
      "polygonOffset": true,
      "polygonOffsetFactor": 1,
      "polygonOffsetUnits": 1,
    };

    switch (type) {
      case Model3DType.plane:
        return MeshBasicMaterial(params);
      default:
        return MeshStandardMaterial(params);
    }
  }

  void _setRandomColor() {
    color = Color.fromRGBO(_randomInt(), _randomInt(), _randomInt(), 1);
  }

  int _randomInt() {
    return (Math.random() * 255).toInt();
  }

  @override
  List<Object?> get props => [
        name,
        position,
        rotation,
        width,
        height,
        length,
        type,
        color,
        castShadow,
        receiveShadow,
        randomColor,
        texture,
        textureRepeatCount,
      ];
}
