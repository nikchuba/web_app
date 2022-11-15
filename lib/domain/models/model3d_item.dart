import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:three_dart/three3d/math/vector3.dart';

class Model3DItem extends Equatable {
  const Model3DItem({
    required this.position,
    required this.width,
    required this.length,
    this.height = 0,
    this.color,
    this.imageSrc,
  });

  final Vector3 position;
  final double width, length, height;
  final Color? color;
  final String? imageSrc;

  @override
  List<Object?> get props => [position, color, imageSrc];
}
