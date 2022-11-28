import 'dart:math';
import 'package:flutter/material.dart';
import 'number_input_field.dart';

class ContextMenu {
  ContextMenu._();
  static ContextMenu instance = ContextMenu._();

  factory ContextMenu.init(BuildContext context) {
    _menu = Overlay.of(context);
    return instance;
  }

  static OverlayState? _menu;
  OverlayEntry? _content;
  bool get _mounted => _content?.mounted == true;

  void showObjectInfo({
    Point<double> origin = const Point(0, 210),
    required Map<String, TextEditingController> items,
    void Function(List<String>)? callback,
  }) {
    if (_menu != null) {
      close();
      _content = _getContent(origin, items, callback);
      _menu!.insert(_content!);
    }
  }

  void close() {
    if (_mounted) {
      _content?.remove();
    }
  }

  OverlayEntry _getContent(
    Point<double> origin,
    Map<String, TextEditingController> items,
    void Function(List<String>)? callback,
  ) {
    final labels = items.keys.toList();
    final controllers = items.values.toList();

    return OverlayEntry(
      builder: (context) {
        return Positioned(
          left: origin.x,
          top: origin.y - 210,
          child: Material(
            type: MaterialType.transparency,
            child: Column(
              children: [
                Container(
                  width: 160,
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: 100,
                        height: 160,
                        child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            itemCount: labels.length,
                            itemBuilder: (context, index) {
                              return NumberInputField(
                                label: labels[index],
                                controller: controllers[index],
                              );
                            }),
                      ),
                      TextButton(
                        onPressed: () {
                          close();
                          callback
                              ?.call([...controllers.map((e) => e.value.text)]);
                        },
                        style: TextButton.styleFrom(
                            backgroundColor: Colors.blue.shade100,
                            fixedSize: const Size(100, 50),
                            shape: const RoundedRectangleBorder()),
                        child: const Text('Применить'),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
