import 'package:flutter/material.dart';
import 'package:three_dart/three3d/math/vector3.dart';
import 'package:web_app/domain/models/model3d_item.dart';
import 'package:web_app/presentation/widgets/number_input_field.dart';

class Object3DFormField extends StatefulWidget {
  const Object3DFormField({
    Key? key,
    required this.callback,
  }) : super(key: key);

  final Function(Model3DItem) callback;

  @override
  State<Object3DFormField> createState() => _Object3DFormFieldState();
}

class _Object3DFormFieldState extends State<Object3DFormField> with TickerProviderStateMixin {
  late AnimationController animationController;
  late TextEditingController widthController, heightController, lengthController;
  late Animation<double> animation;
  late ValueNotifier<bool> isOpen;

  final double width = 200;
  final double height = 350;

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..addListener(() => setState(() {}));
    animation = CurveTween(curve: Curves.decelerate).animate(animationController);
    widthController = TextEditingController(text: '700');
    heightController = TextEditingController(text: '700');
    lengthController = TextEditingController(text: '700');
    isOpen = ValueNotifier(false);
  }

  @override
  void dispose() {
    widthController.dispose();
    lengthController.dispose();
    heightController.dispose();
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ValueListenableBuilder(
                valueListenable: isOpen,
                builder: (context, isOpen, child) {
                  return TextButton(
                    onPressed: !isOpen ? _showOverlay : null,
                    style: TextButton.styleFrom(
                        backgroundColor: Colors.white,
                        fixedSize: const Size(120, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100))),
                    child: const Text('Новый объект'),
                  );
                },
              ),
              AnimatedScale(
                duration: Duration.zero,
                scale: animation.value,
                child: TextButton(
                  onPressed: _closeOverlay,
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.redAccent,
                    fixedSize: const Size(50, 50),
                    shape: const CircleBorder(),
                  ),
                  child: const Icon(Icons.close_rounded),
                ),
              ),
            ],
          ),
          AnimatedOpacity(
            duration: Duration.zero,
            opacity: animation.value,
            child: Container(
              clipBehavior: Clip.hardEdge,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 10,
                    spreadRadius: 0,
                  ),
                ],
              ),
              padding: EdgeInsets.all(MediaQuery.of(context).size.height * 0.02),
              width: width,
              height: height - 80,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  NumberInputField(
                    label: 'Ширина (мм)',
                    controller: widthController,
                  ),
                  NumberInputField(
                    label: 'Длина (мм)',
                    controller: lengthController,
                  ),
                  NumberInputField(
                    label: 'Высота (мм)',
                    controller: heightController,
                  ),
                  TextButton(
                    onPressed: () {
                      final model = Model3DItem(
                        position: Vector3(1.5, 8, 0),
                        width: double.parse(widthController.text),
                        length: double.parse(lengthController.text),
                        height: double.parse(heightController.text),
                      );
                      widget.callback(model);
                      _closeOverlay();
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.blue.shade50,
                      fixedSize: const Size(200, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                    ),
                    child: const Text('Добавить'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showOverlay() async {
    if (!animationController.isAnimating) {
      await animationController.forward();
      isOpen.value = true;
    }
  }

  void _closeOverlay() async {
    if (!animationController.isAnimating) {
      await animationController.reverse();
      isOpen.value = false;
    }
  }
}
