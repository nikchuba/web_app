import 'dart:math';

import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // late Size screenSize;
  late Offset offset;
  late double zoom;
  late double sceneSize;

  @override
  void didChangeDependencies() {
    sceneSize = MediaQuery.of(context).size.width - 200;
    super.didChangeDependencies();
  }

  @override
  void initState() {
    offset = const Offset(0, -1.2);
    zoom = 1;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black12,
      body: Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanUpdate: (details) {
              final dx = offset.dx + details.delta.dx / 500;
              final dy = offset.dy + details.delta.dy / 500;
              if (dy <= -1.5 || dy >= -0.2) return;
              setState(() => offset = Offset(dx, dy));
            },
            child: Center(
              child: Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..scale(zoom, zoom, zoom)
                  ..rotateX(offset.dy)
                  ..rotateZ(-offset.dx),
                origin: Offset(sceneSize / 2, sceneSize / 2),
                child: Container(
                  // clipBehavior: Clip.hardEdge,
                  width: sceneSize,
                  height: sceneSize,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    // shape: BoxShape.circle,
                    // image: DecorationImage(image: AssetImage('assets/truck_trailer.jpg')),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CustomPaint(
                        painter: GridPainter(),
                      ),
                      Trailer(),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 20,
            top: MediaQuery.of(context).size.height / 2 - 50,
            bottom: MediaQuery.of(context).size.height / 2 - 50,
            child: IntrinsicHeight(
              child: ZoomButtons(
                zoomIn: () => setState(() => zoom += 0.1),
                zoomOut: () => setState(() => zoom -= 0.1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Trailer extends StatelessWidget {
  const Trailer({
    super.key,
    double width = 2,
    double height = 2.5,
    double length = 6,
  })  : _width = width * 50,
        _height = height * 50,
        _length = length * 50;

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
    return Positioned(
      top: 200,
      left: 200,
      width: _width,
      height: _length,
      child: Stack(
        children: [
          Container(
            width: _width,
            height: _length,
            decoration: const BoxDecoration(
              color: Colors.amber,
              border: border,
            ),
          ),
          Positioned(
            top: 0,
            child: Container(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..setRotationX(-pi / 2),
              width: _width,
              height: _height,
              decoration: const BoxDecoration(
                color: Colors.amber,
                border: border,
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            child: Container(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..setRotationX(-pi / 2),
              width: _width,
              height: _height,
              decoration: const BoxDecoration(
                color: Colors.amber,
                border: border,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ZoomButtons extends StatelessWidget {
  final VoidCallback? zoomIn, zoomOut;
  const ZoomButtons({
    Key? key,
    this.zoomIn,
    this.zoomOut,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.hardEdge,
      width: 50,
      height: 100,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(100)),
      child: Column(
        children: [
          Expanded(
            child: TextButton(
              onPressed: zoomIn,
              child: const Icon(Icons.add),
            ),
          ),
          Expanded(
            child: TextButton(
              onPressed: zoomOut,
              child: const Icon(Icons.remove),
            ),
          ),
        ],
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  final double lineWidth;
  final double cellSize;
  GridPainter({
    this.lineWidth = 1,
    this.cellSize = 20,
  });

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = lineWidth;

    Path path = Path();
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.lineTo(0, 0);
    for (double i = 1; i < size.height / cellSize; i++) {
      final height = i * cellSize;
      if (i % 2 == 0) {
        path
          ..moveTo(size.width, height)
          ..lineTo(0, height);
      }
      path
        ..moveTo(0, height)
        ..lineTo(size.width, height);
    }
    for (double i = 1; i < size.width / cellSize; i++) {
      final width = i * cellSize;
      if (i % 2 == 0) {
        path
          ..moveTo(width, 0)
          ..lineTo(width, size.height);
      }
      path
        ..moveTo(width, size.height)
        ..lineTo(width, 0);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
