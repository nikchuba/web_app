import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

class Model3DItem extends Equatable {
  const Model3DItem({required this.offset, this.color, this.imageSrc});

  final Offset offset;
  final Color? color;
  final String? imageSrc;
  
  @override
  List<Object?> get props => [offset, color, imageSrc];
}
