import 'dart:math';

import 'package:flutter/material.dart';

class Selector<T> extends StatefulWidget {
  const Selector({
    Key? key,
    required this.items,
    required this.controller,
    this.closeController,
  }) : super(key: key);

  final Map<T, String> items;
  final ValueNotifier<T> controller;
  final ValueNotifier<bool>? closeController;

  @override
  State<Selector<T>> createState() => _SelectorState<T>();
}

class _SelectorState<T> extends State<Selector<T>> with TickerProviderStateMixin {
  late Map<T, String> items;
  late ValueNotifier<T> controller;
  late AnimationController animationController;
  late Animation<double> animation;
  OverlayEntry? overlayEntry;
  late OverlayState overlayState;
  final GlobalKey globalKey = GlobalKey();
  bool isOpen = false;

  final padding = const EdgeInsets.symmetric(horizontal: 20);

  @override
  void initState() {
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    animation =
        CurveTween(curve: Curves.decelerate).animate(animationController);
    items = widget.items;
    controller = widget.controller;
    controller.value = items.keys.first;
    overlayState = Overlay.of(context)!;
    widget.closeController?.addListener(() {
      if (widget.closeController?.value == true &&
          overlayEntry?.mounted == true) {
        closeOverlay();
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    animationController.dispose();
    overlayState.dispose();
    overlayEntry?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextButton(
      key: globalKey,
      onPressed: !isOpen ? showOverlay : closeOverlay,
      style: TextButton.styleFrom(
        backgroundColor: Colors.blue.shade50,
        fixedSize: const Size(300, 50),
        padding: padding,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(100),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(items[controller.value]!),
          Transform.rotate(
            angle: pi * animation.value,
            child: const Icon(Icons.arrow_drop_down),
          ),
        ],
      ),
    );
  }

  void showOverlay() {
    initOverlay();
    animationController
      ..addListener(() {
        overlayState.setState(() => setState(() {}));
      })
      ..forward();
    overlayState.insert(overlayEntry!);
    isOpen = true;
  }

  void closeOverlay() {
    animationController.reverse().whenComplete(overlayEntry!.remove);
    isOpen = false;
  }

  void initOverlay() {
    final RenderBox renderBox =
        globalKey.currentContext!.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);
    overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          left: offset.dx,
          top: offset.dy + 50,
          child: Container(
            clipBehavior: Clip.hardEdge,
            width: renderBox.size.width,
            height: 100 * animation.value,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                var item = items.entries.elementAt(index);
                return TextButton(
                  onPressed: () {
                    closeOverlay();
                    controller.value = item.key;
                  },
                  style: TextButton.styleFrom(
                    padding: padding,
                    alignment: Alignment.centerLeft,
                    fixedSize: const Size(200, 50),
                  ),
                  child: Text(item.value),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
