import 'package:flutter/material.dart';
import 'package:web_app/domain/models/model3d.dart';
import 'package:web_app/presentation/widgets/number_input_field.dart';
import 'package:web_app/presentation/widgets/selector.dart';

class Object3DFormField extends StatefulWidget {
  const Object3DFormField({
    Key? key,
    required this.callback,
  }) : super(key: key);

  final Function(Object3D) callback;

  @override
  State<Object3DFormField> createState() => _Object3DFormFieldState();
}

class _Object3DFormFieldState extends State<Object3DFormField>
    with TickerProviderStateMixin {
  late AnimationController animationController;
  late TextEditingController widthController,
      heightController,
      lengthController;
  late ValueNotifier<Model3DType> typeController;
  late Animation<double> animation;
  late ValueNotifier<bool> isClosed;

  final double width = 200, height = 400;

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..addListener(() => setState(() {}));
    animation = CurveTween(
      curve: Curves.decelerate,
    ).animate(animationController);
    widthController = TextEditingController(text: '700');
    heightController = TextEditingController(text: '700');
    lengthController = TextEditingController(text: '700');
    typeController = ValueNotifier(Model3DType.box);
    isClosed = ValueNotifier(true);
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
    return Container(
      constraints: BoxConstraints(
        maxHeight: height,
        maxWidth: width,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ValueListenableBuilder(
                valueListenable: isClosed,
                builder: (context, value, child) {
                  return TextButton(
                    onPressed: value ? showForm : null,
                    style: TextButton.styleFrom(
                        backgroundColor: Colors.white,
                        fixedSize: const Size(120, 50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100))),
                    child: const Text('Новый объект'),
                  );
                },
              ),
              AnimatedScale(
                duration: Duration.zero,
                scale: animation.value,
                child: TextButton(
                  onPressed: closeForm,
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
          const SizedBox(height: 20),
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
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  NumberInputField(
                    label: 'Ширина (мм)',
                    controller: widthController,
                  ),
                  ValueListenableBuilder(
                    valueListenable: typeController,
                    builder: (context, value, child) {
                      return value == Model3DType.box
                          ? NumberInputField(
                              label: 'Длина (мм)',
                              controller: lengthController,
                            )
                          : const SizedBox();
                    },
                  ),
                  NumberInputField(
                    label: 'Высота (мм)',
                    controller: heightController,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Selector(
                      items: const {
                        Model3DType.box: 'Коробка',
                        Model3DType.cylinder: 'Цилиндр',
                      },
                      controller: typeController,
                      closeController: isClosed,
                    ),
                  ),
                  TextButton(
                    onPressed: add,
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.blue.shade50,
                      fixedSize: const Size(200, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
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

  void add() {
    var type = typeController.value;
    var model = Model3D(
      position: Vector3(0, 8, 0),
      width: sizeToDouble(widthController.text),
      height: sizeToDouble(heightController.text),
      length: type == Model3DType.cylinder
          ? sizeToDouble(widthController.text)
          : sizeToDouble(lengthController.text),
      type: type,
      castShadow: true,
      receiveShadow: true,
      randomColor: true,
    );
    widget.callback(model.getObject3D());
    closeForm();
  }

  double sizeToDouble(String value) {
    return double.parse(value) / 1000;
  }

  void showForm() async {
    if (!animationController.isAnimating) {
      isClosed.value = false;
      await animationController.forward();
    }
  }

  void closeForm() async {
    if (!animationController.isAnimating) {
      isClosed.value = true;
      await animationController.reverse();
    }
  }
}
