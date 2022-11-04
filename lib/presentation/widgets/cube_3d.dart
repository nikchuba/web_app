import 'dart:math';

import 'package:flutter/material.dart';
import 'package:web_app/domain/models/model3d_item_controller.dart';

class Cube3D extends StatelessWidget {
  const Cube3D({
    super.key,
    required this.controller,
    double size = 2,
  }) : _size = size * 50;

  final Model3DItemController controller;
  final double _size;

  static const border = Border(
    top: BorderSide(),
    bottom: BorderSide(),
    left: BorderSide(),
    right: BorderSide(),
  );

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          return Positioned(
            top: controller.offset.dx.toDouble(),
            left: controller.offset.dy.toDouble(),
            width: _size,
            height: _size,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                controller.color = Colors.red;
              },
              child: Stack(
                fit: StackFit.loose,
                clipBehavior: Clip.hardEdge,
                children: [
                  Container(
                    width: _size,
                    height: _size,
                    decoration: BoxDecoration(
                      image: getImage(),
                      color: controller.color,
                      border: border,
                    ),
                  ),
                  Transform(
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..setRotationX(-pi / 2),
                    child: Container(
                      width: _size,
                      height: _size,
                      decoration: BoxDecoration(
                        image: getImage(),
                        color: controller.color,
                        border: border,
                      ),
                    ),
                  ),
                  Transform(
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..setRotationX(-pi / 2)
                      ..translate(0, 0, _size),
                    child: Container(
                      width: _size,
                      height: _size,
                      decoration: BoxDecoration(
                        image: getImage(),
                        color: controller.color,
                        border: border,
                      ),
                    ),
                  ),
                  Transform(
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..setRotationY(pi / 2),
                    child: Container(
                      width: _size,
                      height: _size,
                      decoration: BoxDecoration(
                        image: getImage(),
                        color: controller.color,
                        border: border,
                      ),
                    ),
                  ),
                  Transform(
                    transformHitTests: true,
                    // origin: Offset(200, 200),
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..setRotationY(pi / 2)
                      ..translate(0, 0, _size),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        controller.color = Colors.black;
                      },
                      child: Container(
                        width: _size,
                        height: _size,
                        decoration: BoxDecoration(
                          image: getImage(),
                          color: Colors.yellow,
                          border: border,
                        ),
                      ),
                    ),
                  ),
                  Transform(
                    transformHitTests: true,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..setRotationY(0)
                      ..translate(0, 0, -_size),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        controller.color = Colors.green;
                      },
                      child: Container(
                        width: _size,
                        height: _size,
                        decoration: BoxDecoration(
                          image: getImage(),
                          color: Colors.orange,
                          border: border,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }

  DecorationImage? getImage() {
    return controller.imageSrc != ''
        ? DecorationImage(
            image: AssetImage(controller.imageSrc),
            fit: BoxFit.cover,
          )
        : null;
  }
}
