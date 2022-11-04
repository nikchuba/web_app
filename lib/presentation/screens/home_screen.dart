import 'dart:math';

import 'package:ditredi/ditredi.dart';
import 'package:vector_math/vector_math_64.dart' as math;
import 'package:flutter/material.dart';
import 'package:web_app/domain/models/model3d_item.dart';
import 'package:web_app/domain/models/model3d_item_controller.dart';
import 'package:web_app/presentation/widgets/cube_3d.dart' as my;
import 'package:web_app/presentation/widgets/truck_trailer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  // late Size screenSize;
  late Offset offset;
  late double zoom;
  late double sceneSize;
  late Model3DItemController cubeController;
  late Model3DItemController truckController;
  final GlobalKey<HomeScreenState> key = GlobalKey();

  @override
  void didChangeDependencies() {
    sceneSize = MediaQuery.of(context).size.width - 200;
    super.didChangeDependencies();
  }

  @override
  void initState() {
    cubeController = Model3DItemController(
      const Model3DItem(offset: Offset(0, 0)),
    );
    truckController = Model3DItemController(
      const Model3DItem(offset: Offset(300, 400)),
    );
    offset = const Offset(0, -1.2);
    zoom = 1;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black12,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanUpdate: (details) {
                print(offset);
                final dx = offset.dx + details.delta.dx / 500;
                final dy = offset.dy + details.delta.dy / 500;
                if (dy <= -1.5 || dy >= -0.2) return;
                setState(() => offset = Offset(dx, dy));
              },
              child: Transform(
                transformHitTests: true,
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
                      // CustomPaint(
                      //   painter: GridPainter(),
                      // ),
                      TruckTrailer(
                        controller: truckController,
                      ),
                      my.Cube3D(
                        controller: cubeController,
                        size: 5,
                        // offset: Offset(100, 0),
                      ),
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
