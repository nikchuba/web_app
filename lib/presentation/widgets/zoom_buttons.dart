import 'package:flutter/material.dart';

class ZoomButtons extends StatelessWidget {
  final VoidCallback zoomIn, zoomOut;
  final Size size;
  const ZoomButtons({
    Key? key,
    this.size = const Size(50, 100),
    required this.zoomIn,
    required this.zoomOut,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.hardEdge,
      width: size.width,
      height: size.height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size.width),
      ),
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
