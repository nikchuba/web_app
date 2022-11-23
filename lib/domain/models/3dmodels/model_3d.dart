import 'dart:ui';
import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:three_dart/three_dart.dart' as three;

import 'outline_3d.dart';

enum Model3DType { box, cylinder, plane }

// ignore: must_be_immutable
class Model3D extends Equatable with Outline3D {
  Model3D({
    this.name = '',
    three.Vector3? position,
    three.Vector3? rotation,
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
  })  : position = position ?? three.Vector3(),
        rotation = rotation ?? three.Vector3();

  String name;
  three.Vector3 position, rotation;
  double width, height, length;
  Model3DType type = Model3DType.box;
  Color color;
  bool castShadow, receiveShadow, randomColor;
  three.Texture? texture;
  double? textureRepeatCount;

  Model3D clone({
    String? name,
    three.Vector3? position,
    three.Vector3? rotation,
    double? width,
    double? height,
    double? length,
    Model3DType? type,
    bool? randomColor,
    Color? color,
    bool? castShadow,
    bool? receiveShadow,
    three.Texture? texture,
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

  three.Object3D getObject3D() {
    if (type != Model3DType.plane) {
      var group = three.Group();
      var mesh = three.Mesh(getGeometry(), getMaterial())
        ..name = name.isNotEmpty ? '$name-mesh' : 'mesh';
      var outline = getOutline(mesh);
      group.addAll([mesh, outline]);
      return group
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
    var mesh = three.Mesh(getGeometry(), getMaterial());
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

  three.BufferGeometry getGeometry() {
    switch (type) {
      case Model3DType.box:
        return three.BoxGeometry(width, height, length);
      case Model3DType.cylinder:
        return three.CylinderGeometry(width, length, height, 100);
      case Model3DType.plane:
        return three.PlaneGeometry(width, length);
      default:
        return three.BoxGeometry(width, height, length);
    }
  }

  three.Material getMaterial() {
    if (randomColor) _setRandomColor();
    if (texture != null && textureRepeatCount != null) {
      texture!
        ..wrapS = three.RepeatWrapping
        ..wrapT = three.RepeatWrapping
        ..repeat.set(textureRepeatCount!, textureRepeatCount!);
    }
    var params = {
      "color": three.Color.setRGB255(color.red, color.green, color.blue),
      if (texture != null) "map": texture,
    };

    switch (type) {
      case Model3DType.plane:
        return three.MeshBasicMaterial(params);
      default:
        return three.MeshStandardMaterial(params);
    }
  }

  void _setRandomColor() {
    color = Color.fromRGBO(_randomInt(), _randomInt(), _randomInt(), 1);
  }

  int _randomInt() {
    return (three.Math.random() * 255).toInt();
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
