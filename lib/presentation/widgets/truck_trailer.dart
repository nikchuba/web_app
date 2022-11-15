import 'dart:math';

// import 'package:ditredi/ditredi.dart';
import 'package:flutter/material.dart';
import 'package:web_app/domain/models/model3d_item_controller.dart';

class TruckTrailer extends StatelessWidget {
  const TruckTrailer({
    super.key,
    required this.controller,
    Offset? offset,
    double width = 2,
    double height = 2.5,
    double length = 6,
  })  : 
        _width = width * 50,
        _height = height * 50,
        _length = length * 50;

  final Model3DItemController controller;
  final double _width;
  final double _height;
  final double _length;

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
          top: controller.offset.x,
          left: controller.offset.y,
          child: Stack(
            fit: StackFit.loose,
            clipBehavior: Clip.none,
            children: [
              Container(
                width: _width,
                height: _length,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/truck_trailer.jpg'),
                    fit: BoxFit.cover,
                  ),
                  border: border,
                ),
              ),
              Container(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..setRotationX(-pi / 2),
                width: _width,
                height: _height,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/truck_trailer.jpg'),
                    fit: BoxFit.cover,
                  ),
                  border: border,
                ),
              ),
              Container(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..setRotationX(-pi / 2)
                  ..translate(0, 0, _length),
                width: _width,
                height: _height,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/truck_trailer.jpg'),
                    fit: BoxFit.cover,
                  ),
                  border: border,
                ),
              ),
              Container(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..setRotationY(pi / 2),
                width: _height,
                height: _length,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/truck_trailer.jpg'),
                    fit: BoxFit.cover,
                  ),
                  border: border,
                ),
              ),
              Container(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..setRotationY(pi / 2)
                  ..translate(0, 0, _width),
                width: _height,
                height: _length,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/truck_trailer.jpg'),
                    fit: BoxFit.cover,
                  ),
                  border: border,
                ),
              ),
            ],
          ),
        );
      }
    );
  }
}
