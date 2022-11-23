import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gl/flutter_gl.dart';
import 'package:three_dart/three_dart.dart' as three;
import 'package:web_app/domain/models/3dmodels/ground_3d.dart';

import 'package:web_app/domain/models/3dmodels/model_3d.dart';
import 'package:web_app/domain/models/3dmodels/truck_container_3d.dart';
import 'package:web_app/presentation/widgets/zoom_buttons.dart';
import 'package:three_dart_jsm/three_dart_jsm.dart' as three_jsm;

import '../widgets/object3d_form_field.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final truckSize = three.Vector3(2.43, 12.19, 2.59);
  late FlutterGlPlugin three3dRender;
  three.WebGLRenderer? renderer;
  late three.Loader textureLoader, textLoader;

  late double width, height;

  Size? screenSize;

  late three.Scene scene;
  late three.Camera camera;

  double devicePixelRatio = 1.0;

  var amount = 4;

  bool verbose = true;
  bool disposed = false;

  late three.Object3D ground;
  late List<three.Object3D> draggableObjects,
      draggableMeshes,
      boundaryObjects,
      collisionObjects;
  late three.Object3D targetObject, targetMesh;

  late three.Texture groundTexture, containerTexture;

  late three.WebGLRenderTarget renderTarget;

  dynamic sourceTexture;

  ValueNotifier<bool> loaded = ValueNotifier(false);
  ValueNotifier<bool> outlineMode = ValueNotifier(false);

  int counter = 0;
  double fontHeight = 20,
      size = 70,
      hover = 30,
      curveSegments = 4,
      bevelThickness = 2,
      bevelSize = 1.5;

  final globalKey = GlobalKey<three_jsm.DomLikeListenableState>();
  late three_jsm.OrbitControls controls;
  late three.Raycaster raycasterObjects, raycasterRoofs;
  late three.Font textFont;

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    width = screenSize!.width;
    height = screenSize!.height;

    three3dRender = FlutterGlPlugin();

    Map<String, dynamic> options = {
      "antialias": true,
      "alpha": false,
      "width": width.toInt(),
      "height": height.toInt(),
      "dpr": devicePixelRatio,
    };

    // print("three3dRender.initialize _options: $options ");

    await three3dRender.initialize(options: options);
    textureLoader = three.TextureLoader(null);
    textLoader = three_jsm.TYPRLoader(null);

    groundTexture = await textureLoader.loadAsync('assets/grass2.jpg');
    containerTexture =
        await textureLoader.loadAsync('assets/truck_container.jpg');

    textFont = await loadFont();

    setState(() {});

    // Wait for web
    Future.delayed(Duration.zero, () async {
      await three3dRender.prepareContext();

      initScene();
    });
  }

  Future<void> initSize(BuildContext context) async {
    if (screenSize != null) {
      return;
    }

    final mqd = MediaQuery.of(context);

    screenSize = mqd.size;
    devicePixelRatio = mqd.devicePixelRatio;

    await initPlatformState();
  }

  void switchOutlineMode() => outlineMode.value = !outlineMode.value;

  void setOutline(bool value, three.Object3D object) {
    if (object.geometry?.type == 'TextGeometry' && object.type == 'Line') {
      return;
    }
    if (object.name == 'ground') {
      object.children[0].visible = !value;
      object.children[1].visible = value;
      return;
    }
    for (var child in object.children) {
      if (child.name.contains('outline')) {
        child.visible = value;
        continue;
      }
      child.visible = !value;
    }
  }

  @override
  void initState() {
    outlineMode.addListener(() {
      for (var object in scene.children) {
        setOutline(outlineMode.value, object);
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: three_jsm.DomLikeListenable(
          key: globalKey,
          builder: (_) {
            initSize(context);
            return Container(
              width: width,
              height: height,
              color: Colors.black,
              child: ValueListenableBuilder(
                valueListenable: loaded,
                builder: (context, value, child) {
                  return value
                      ? Stack(
                          children: [
                            kIsWeb
                                ? HtmlElementView(
                                    viewType:
                                        three3dRender.textureId!.toString(),
                                  )
                                : Texture(
                                    textureId: three3dRender.textureId!,
                                    filterQuality: FilterQuality.none,
                                  ),
                            Positioned(
                              top: 0,
                              bottom: 100,
                              right: 20,
                              child: Center(
                                child: ZoomButtons(
                                  zoomIn: () => controls
                                    ..dollyIn(0.9)
                                    ..update(),
                                  zoomOut: () => controls
                                    ..dollyIn(1.1)
                                    ..update(),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 20,
                              right: 20,
                              child: Center(
                                child: TextButton(
                                  style: TextButton.styleFrom(
                                    fixedSize: const Size(150, 50),
                                    backgroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                  ),
                                  onPressed: switchOutlineMode,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('Окружение'),
                                      const SizedBox(width: 10),
                                      ValueListenableBuilder(
                                        valueListenable: outlineMode,
                                        builder: (context, value, child) {
                                          return SizedBox(
                                            width: 30,
                                            child: Switch(
                                              focusColor: Colors.transparent,
                                              hoverColor: Colors.transparent,
                                              overlayColor:
                                                  const MaterialStatePropertyAll(
                                                      Colors.transparent),
                                              value: !value,
                                              onChanged: (_) =>
                                                  switchOutlineMode(),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 20,
                              left: 20,
                              child: Center(
                                child: Object3DFormField(
                                  callback: (object) {
                                    setOutline(outlineMode.value, object);
                                    draggableObjects.add(object);
                                    draggableMeshes.add(object.children[0]);
                                    boundaryObjects.add(object.children[0]);
                                    scene.add(object);
                                  },
                                ),
                              ),
                            ),
                          ],
                        )
                      : const Center(child: CircularProgressIndicator());
                },
              ),
            );
          },
        ),
      ),
    );
  }

  render() {
    final gl = three3dRender.gl;

    renderer!.render(scene, camera);

    gl.finish();

    if (!kIsWeb) {
      three3dRender.updateTexture(sourceTexture);
    }
  }

  dynamic initScene() async {
    initRenderer();
    initPage();
  }

  void initRenderer() {
    Map<String, dynamic> options = {
      "width": width,
      "height": height,
      "gl": three3dRender.gl,
      "antialias": true,
      "canvas": three3dRender.element,
      "alpha": true,
    };

    renderer = three.WebGLRenderer(options);
    renderer!.setPixelRatio(devicePixelRatio);
    renderer!.setSize(width, height, true);
    renderer!.shadowMap.enabled = true;
    renderer!.setClearColor(three.Color.fromHex(0xEEEEEE), 1.0);

    if (!kIsWeb) {
      var pars = three.WebGLRenderTargetOptions({"format": three.RGBAFormat});
      renderTarget = three.WebGLRenderTarget(
        (width * devicePixelRatio).toInt(),
        (height * devicePixelRatio).toInt(),
        pars,
      );
      renderTarget.samples = 4;
      renderer!.setRenderTarget(renderTarget);

      sourceTexture = renderer!.getRenderTargetGLTexture(renderTarget);
    }
  }

  void createGround() {
    const groundSize = 100.0;
    ground = Ground3D(
      width: groundSize,
      length: groundSize,
      texture: groundTexture,
      textureRepeatCount: 25,
    ).getObject3D();
    scene.add(ground);
  }

  void initPage() {
    final aspectRatio = width / height;

    scene = three.Scene()
      ..background = three.Color.setRGB255(200, 255, 255)
      ..rotateX(-pi / 2);

    camera = three.PerspectiveCamera(45, aspectRatio, 0.1, 1000)
      ..position.set(45, 30, 60)
      ..lookAt(scene.position);

    controls = three_jsm.OrbitControls(camera, globalKey)
      ..maxPolarAngle = pi / 2.2
      ..maxDistance = 60
      ..minDistance = 5
      ..enableZoom = true
      ..dollyIn(0.3)
      ..update();

    raycasterObjects = three.Raycaster();
    raycasterRoofs = three.Raycaster();

    createGround();

    var truckContainer = TruckContainer3D(
      width: 2.43,
      length: 12.19,
      height: 2.59,
      texture: containerTexture,
    );

    var textMaterial = three.LineBasicMaterial()
      ..color = three.Color.setRGB255(0, 0, 0);
    var linePointsLH = [
          three.Vector3(truckSize.x, -truckSize.y / 2, 0),
          three.Vector3(truckSize.x, truckSize.y / 2, 0),
          three.Vector3(truckSize.x, truckSize.y / 2, truckSize.z),
        ],
        linePointsW = [
          three.Vector3(
              -truckSize.x / 2, -truckSize.y / 2 - truckSize.x / 2, 0),
          three.Vector3(truckSize.x / 2, -truckSize.y / 2 - truckSize.x / 2, 0),
        ];
    var lineGeometryLH = three.BufferGeometry().setFromPoints(linePointsLH),
        lineGeometryW = three.BufferGeometry().setFromPoints(linePointsW);
    var lineLH = three.Line(
          lineGeometryLH,
          textMaterial,
        ),
        lineW = three.Line(
          lineGeometryW,
          textMaterial,
        );
    var lines = [lineLH, lineW];

    var textWidth = createText(
          '${truckSize.x * 1000}',
          three.Vector3(
              truckSize.x / 2, -truckSize.y / 2 - truckSize.x / 1.5, 0),
        ),
        textLength = createText(
          '${truckSize.y * 1000}',
          three.Vector3(truckSize.x * 1.2, -truckSize.y / 2, 0),
          three.Vector3(0, 0, pi / 2),
        ),
        textHeight = createText(
          '${truckSize.z * 1000}',
          three.Vector3(truckSize.x, truckSize.y / 2, truckSize.z),
          three.Vector3(pi / 2, pi / 4),
        ),
        textZeroLH = createText(
          '0',
          three.Vector3(truckSize.x * 1.2, truckSize.y / 2 - 0.2, 0),
          three.Vector3(0, 0, pi / 2),
        ),
        textZeroW = createText(
          '0',
          three.Vector3(
              -truckSize.x / 2 - 0.2, -truckSize.y / 2 - truckSize.x / 1.5, 0),
        );
    var texts = [textWidth, textLength, textHeight, textZeroLH, textZeroW];

    var box1 = Model3D(
          name: 'draggable-1',
          width: 0.2,
          length: 1,
          height: 1,
          position: three.Vector3(10, 0, 0),
          color: Colors.amber,
        ).getObject3D(),
        box2 = Model3D(
          name: 'draggable-2',
          width: 1.5,
          length: 1.5,
          height: 1.5,
          position: three.Vector3(9, 2, 0),
          color: Colors.redAccent,
        ).getObject3D(),
        box3 = Model3D(
          name: 'draggable-3',
          width: 1.1,
          length: 1.2,
          height: 1.5,
          position: three.Vector3(6, 0, 0),
          color: Colors.purple,
        ).getObject3D(),
        box4 = Model3D(
          name: 'draggable-4',
          width: 2,
          length: 1.5,
          height: 1.5,
          position: three.Vector3(5, -4, 0),
          color: Colors.cyan,
        ).getObject3D(),
        box5 = Model3D(
          name: 'draggable-5',
          width: 1.5,
          length: 1.5,
          height: 1.25,
          position: three.Vector3(5, 6, 0),
          color: Colors.blue.shade400,
        ).getObject3D(),
        box6 = Model3D(
          name: 'draggable-6',
          width: 0.5,
          length: 0.75,
          height: 0.5,
          position: three.Vector3(5, 10, 0),
          color: Colors.pink.shade200,
        ).getObject3D(),
        box7 = Model3D(
          name: 'draggable-7',
          width: 1,
          length: 1,
          height: 2,
          position: three.Vector3(5, 3, 0),
          color: Colors.tealAccent,
        ).getObject3D(),
        box8 = Model3D(
          name: 'draggable-8',
          width: 1,
          length: 1,
          height: 1,
          position: three.Vector3(7, 7, 0),
          color: Colors.brown.shade600,
        ).getObject3D(),
        box9 = Model3D(
          name: 'draggable-9',
          width: 1,
          length: 1,
          height: 4,
          position: three.Vector3(7, 4, 0),
          color: Colors.grey,
        ).getObject3D();
    draggableObjects = [box1, box2, box3, box4, box5, box6, box7, box8, box9];

    var light = three.SpotLight(three.Color(0xffa95c), 1.0)
          ..position.x = 100
          ..position.y = 100
          ..position.z = 100
          ..castShadow = true,
        ambientLight = three.AmbientLight(three.Color(0xffeeb1), 0.4),
        hemisphereLight = three.HemisphereLight(
            three.Color(0xffeeb1), three.Color(0x080820), 0.5);
    var lights = [light, ambientLight, hemisphereLight];
    scene
      ..add(truckContainer.getObject3D())
      ..addAll(lines)
      ..addAll(texts)
      ..addAll(draggableObjects)
      ..addAll(lights);

    three.Color? targetColor;

    draggableMeshes = draggableObjects.map((e) => e.children[0]).toList();
    boundaryObjects = [...draggableMeshes, ...truckContainer.sides];

    controls.domElement
      ..addEventListener(
        'pointerdown',
        (event) {
          final vector = pointToVector2(event);
          raycasterObjects.setFromCamera(vector, camera);
          var intersects =
              raycasterObjects.intersectObjects(draggableMeshes, true);
          if (intersects.isNotEmpty) {
            targetMesh = intersects[0].object;
            targetObject = draggableObjects
                .firstWhere((object) => object.children.contains(targetMesh));
            targetColor = targetMesh.material.color;
            for (var child in targetObject.children) {
              child.material?.color = three.Color(0x00ff00);
            }

            controls
              ..enabled = false
              ..domElement.addEventListener('pointermove', dragObject);
          }
        },
      )
      ..addEventListener(
        'pointerup',
        (event) {
          if (targetColor != null) {
            targetObject.children[0].material?.color = targetColor;
            targetObject.children[1].material?.color = three.Color(0x000000);
          }
          controls
            ..domElement.removeEventListener('pointermove', dragObject)
            ..enabled = true;
        },
      );

    loaded.value = true;
    animate();
  }

  void dragObject(event) {
    var point = pointToVector2(event);
    raycasterObjects = three.Raycaster()..setFromCamera(point, camera);
    var intersectingObjects =
        raycasterObjects.intersectObject(ground.children[0], false);
    if (intersectingObjects.isNotEmpty) {
      collisionObjects = ([...boundaryObjects]..remove(targetMesh));
      var pointOnGround = intersectingObjects[0].point;
      var dx = pointOnGround.x,
          dy = -pointOnGround.z,
          dz = targetObject.children[0].geometry?.parameters?['height'] / 2 +
              0.000001;
      raycasterRoofs.setFromCamera(point, camera);
      var intersectingRoofs = raycasterRoofs.intersectObjects(
        collisionObjects,
        true,
      );
      if (intersectingRoofs.isNotEmpty) {
        var isCylinder =
            intersectingRoofs[0].object.geometry?.type == 'CylinderGeometry';
        var indexSide =
            (intersectingRoofs[0].faceIndex / (isCylinder ? 100 : 2)).floor();
        if (indexSide == 2) {
          var target = intersectingRoofs[0].object;
          var object = draggableObjects
              .firstWhere((object) => object.children.contains(target));
          var pos = object.position;
          var uv = intersectingRoofs[0].uv;
          var uvX = !isCylinder ? uv.x : uv.y;
          var uvY = !isCylinder ? uv.y : uv.x;
          var params = target.geometry?.parameters;
          var coef = (isCylinder ? 2 : 1);
          var width = coef * params?[!isCylinder ? 'width' : 'radiusTop'],
              depth = coef * params?[!isCylinder ? 'depth' : 'radiusTop'],
              height = params?['height'];
          dx = pos.x - width * (0.5 - uvX);
          dy = pos.y - depth * (isCylinder ? -1 : 1) * (0.5 - uvY);
          dz += pos.z + 0.5 * height;
        }
      }

      var nextObject = targetObject.clone()
            ..position.set(dx, dy, dz)
            ..visible = false,
          nextObjectX = targetObject.clone()
            ..position.setX(dx)
            ..position.setZ(dz)
            ..visible = false,
          nextObjectY = targetObject.clone()
            ..position.setY(dy)
            ..position.setZ(dz)
            ..visible = false;

      scene.addAll([nextObject, nextObjectX, nextObjectY]);
      var pos = getNewPos(nextObject, nextObjectX, nextObjectY);
      scene.removeList([nextObject, nextObjectX, nextObjectY]);
      if (pos != null) {
        targetObject.position = pos;
      }
    }
  }

  three.Vector3? getNewPos(
    three.Object3D objectXY,
    three.Object3D objectX,
    three.Object3D objectY,
  ) {
    var intersects = List.generate(3, (_) => false);
    var boxXY = getBox3(objectXY),
        boxX = getBox3(objectX),
        boxY = getBox3(objectY);
    for (var key = 0; key < collisionObjects.length; key++) {
      var item = collisionObjects[key];
      var anotherBox = getBox3(item);
      if (anotherBox.intersectsBox(boxXY)) {
        intersects[0] = true;
        var intersectX = anotherBox.intersectsBox(boxX),
            intersectY = anotherBox.intersectsBox(boxY);
        if (intersectX && intersectY) {
          continue;
        }
        intersects[intersectX ? 1 : 2] = true;
      }
    }

    if (!intersects[0]) {
      return objectXY.position;
    }
    if (!intersects[1]) {
      return objectX.position;
    }
    if (!intersects[2]) {
      return objectY.position;
    }

    return null;
  }

  three.Box3 getBox3(three.Object3D object) {
    return three.Box3().setFromObject(object);
  }

  three.Vector2 pointToVector2(three_jsm.WebPointerEvent point) {
    return three.Vector2(
      -(width / 2 - point.clientX) * 2 / width,
      (height / 2 - point.clientY) * 2 / height,
    );
  }

  Future<three.Font> loadFont() async {
    var fontJson = await textLoader.loadAsync(
      "${kIsWeb ? '/' : ''}assets/fonts/Figerona-VF.ttf",
    );
    return three.TYPRFont(fontJson);
  }

  three.Object3D createText(
    String text,
    three.Vector3 position, [
    three.Vector3? rotation,
  ]) {
    var textGeo = three.TextGeometry(
      text,
      {"font": textFont, "size": 0.25, "height": 0.001},
    );

    var material = three.MeshBasicMaterial({"color": 0x000000});
    var textMesh = three.Mesh(textGeo, material)
      ..position.set(
        position.x,
        position.y,
        position.z,
      )
      ..rotation.set(
        rotation?.x ?? 0,
        rotation?.y ?? 0,
        rotation?.z ?? 0,
      );
    return textMesh;
  }

  animate() {
    if (!mounted || disposed) {
      return;
    }

    if (!loaded.value) {
      return;
    }

    render();

    Future.delayed(const Duration(milliseconds: 15), animate);
  }

  @override
  void dispose() {
    disposed = true;
    three3dRender.dispose();
    renderer?.dispose();

    super.dispose();
  }
}
