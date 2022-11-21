import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gl/flutter_gl.dart';
import 'package:three_dart/three3d/textures/texture.dart' as three;
import 'package:three_dart/three_dart.dart' hide Texture;
import 'package:three_dart_jsm/three_dart_jsm.dart' hide TextGeometry;
import 'package:web_app/domain/models/model3d.dart';
import 'package:web_app/presentation/widgets/zoom_buttons.dart';

import '../widgets/object3d_form_field.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final truckSize = Vector3(2.43, 12.19, 2.59);
  late FlutterGlPlugin three3dRender;
  WebGLRenderer? renderer;
  late Loader textureLoader, textLoader;

  late double width, height;

  Size? screenSize;

  late Scene scene;
  late Camera camera;

  double devicePixelRatio = 1.0;

  var amount = 4;

  bool verbose = true;
  bool disposed = false;

  late Object3D ground;
  late List<Object3D> draggableObjects, boundaryObjects, collisionObjects;
  late Object3D targetObject;

  late three.Texture groundTexture, containerTexture;

  late WebGLRenderTarget renderTarget;

  dynamic sourceTexture;

  ValueNotifier<bool> loaded = ValueNotifier(false);

  int counter = 0;
  double fontHeight = 20,
      size = 70,
      hover = 30,
      curveSegments = 4,
      bevelThickness = 2,
      bevelSize = 1.5;

  final globalKey = GlobalKey<DomLikeListenableState>();
  late OrbitControls controls;
  late Raycaster raycasterObjects, raycasterRoofs;
  late Font textFont;

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
    textureLoader = TextureLoader(null);
    textLoader = TYPRLoader(null);

    groundTexture = await textureLoader.loadAsync('assets/grass2.jpg');
    containerTexture =
        await textureLoader.loadAsync('assets/truck_container.jpg');

    textFont = await loadFont();

    // print("three3dRender.initialize three3dRender: ${three3dRender.textureId} ");

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: DomLikeListenable(
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
                              bottom: 0,
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
                              left: 20,
                              child: Center(
                                child: Object3DFormField(
                                  callback: (object) {
                                    draggableObjects.add(object);
                                    boundaryObjects.add(object);
                                    scene.add(object);
                                  },
                                ),
                              ),
                            )
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

    renderer = WebGLRenderer(options);
    renderer!.setPixelRatio(devicePixelRatio);
    renderer!.setSize(width, height, true);
    renderer!.shadowMap.enabled = true;
    renderer!.setClearColor(Color.fromHex(0xEEEEEE), 1.0);

    if (!kIsWeb) {
      var pars = WebGLRenderTargetOptions({"format": RGBAFormat});
      renderTarget = WebGLRenderTarget(
        (width * devicePixelRatio).toInt(),
        (height * devicePixelRatio).toInt(),
        pars,
      );
      renderTarget.samples = 4;
      renderer!.setRenderTarget(renderTarget);

      sourceTexture = renderer!.getRenderTargetGLTexture(renderTarget);
    }
  }

  void initPage() {
    final aspectRatio = width / height;

    scene = Scene()
      ..background = Color.setRGB255(200, 255, 255)
      ..rotateX(-pi / 2);

    camera = PerspectiveCamera(45, aspectRatio, 0.1, 1000)
      ..position.set(45, 30, 60)
      ..lookAt(scene.position);

    controls = OrbitControls(camera, globalKey)
      ..maxPolarAngle = pi / 2.2
      ..maxDistance = 60
      ..minDistance = 5
      ..enableZoom = true
      ..dollyIn(0.3)
      ..update();

    raycasterObjects = Raycaster();
    raycasterRoofs = Raycaster();

    ground = Model3D(
      type: Model3DType.plane,
      width: 100,
      length: 100,
      texture: groundTexture,
      textureRepeatCount: 25,
    ).getObject3D();

    var truckModel =
        Model3D(texture: containerTexture, type: Model3DType.plane);

    var truckBottom = truckModel.clone(
            name: 'truckBottom',
            width: truckSize.y,
            length: truckSize.x,
            height: 0.01,
            rotation: Vector3(0, 0, pi / 2)),
        truckFront = truckModel.clone(
            width: truckSize.x,
            length: truckSize.z,
            position: Vector3(0, truckSize.y / 2, truckSize.z / 2),
            rotation: Vector3(pi / 2, 0, 0)),
        truckRight = truckModel.clone(
            width: truckSize.y,
            length: truckSize.z,
            position: Vector3(truckSize.x / 2, 0, truckSize.z / 2),
            rotation: Vector3(pi / 2, -pi / 2, 0)),
        truckLeft = truckModel.clone(
            width: truckSize.y,
            length: truckSize.z,
            position: Vector3(-truckSize.x / 2, 0, truckSize.z / 2),
            rotation: Vector3(pi / 2, pi / 2, 0)),
        truckBack = truckModel.clone(
            width: truckSize.x,
            length: truckSize.z,
            position: Vector3(0, -truckSize.y / 2, truckSize.z / 2),
            rotation: Vector3(pi / 2, pi, 0)),
        truckRoof = truckModel.clone(
            width: truckSize.y,
            length: truckSize.x,
            position: Vector3(0, 0, truckSize.z + 0.000001),
            rotation: Vector3(pi, 0, pi / 2));
    var truckContainer = [
      truckBottom.getObject3D(),
      truckRight.getObject3D(),
      truckLeft.getObject3D(),
      truckFront.getObject3D(),
      truckBack.getObject3D(),
      truckRoof.getObject3D(),
    ];

    var textMaterial = LineBasicMaterial()..color = Color.setRGB255(0, 0, 0);
    var linePointsLH = [
          Vector3(truckSize.x, -truckSize.y / 2, 0),
          Vector3(truckSize.x, truckSize.y / 2, 0),
          Vector3(truckSize.x, truckSize.y / 2, truckSize.z),
        ],
        linePointsW = [
          Vector3(-truckSize.x / 2, -truckSize.y / 2 - truckSize.x / 2, 0),
          Vector3(truckSize.x / 2, -truckSize.y / 2 - truckSize.x / 2, 0),
        ];
    var lineGeometryLH = BufferGeometry().setFromPoints(linePointsLH),
        lineGeometryW = BufferGeometry().setFromPoints(linePointsW);
    var lineLH = Line(
          lineGeometryLH,
          textMaterial,
        ),
        lineW = Line(
          lineGeometryW,
          textMaterial,
        );
    var lines = [lineLH, lineW];

    var textWidth = createText(
          '${truckSize.x * 1000}',
          Vector3(truckSize.x / 2, -truckSize.y / 2 - truckSize.x / 1.5, 0),
        ),
        textLength = createText(
          '${truckSize.y * 1000}',
          Vector3(truckSize.x * 1.2, -truckSize.y / 2, 0),
          Vector3(0, 0, pi / 2),
        ),
        textHeight = createText(
          '${truckSize.z * 1000}',
          Vector3(truckSize.x, truckSize.y / 2, truckSize.z),
          Vector3(pi / 2, pi / 4),
        ),
        textZeroLH = createText(
          '0',
          Vector3(truckSize.x * 1.2, truckSize.y / 2 - 0.2, 0),
          Vector3(0, 0, pi / 2),
        ),
        textZeroW = createText(
          '0',
          Vector3(
              -truckSize.x / 2 - 0.2, -truckSize.y / 2 - truckSize.x / 1.5, 0),
        );
    var texts = [textWidth, textLength, textHeight, textZeroLH, textZeroW];

    var box1 = Model3D(
          width: 0.2,
          length: 1,
          height: 1,
          position: Vector3(10, 0, 0),
          color: Colors.amber,
        ).getObject3D(),
        box2 = Model3D(
          width: 1.5,
          length: 1.5,
          height: 1.5,
          position: Vector3(9, 2, 0),
          color: Colors.redAccent,
        ).getObject3D(),
        box3 = Model3D(
          width: 1.1,
          length: 1.2,
          height: 1.5,
          position: Vector3(6, 0, 0),
          color: Colors.purple,
        ).getObject3D(),
        box4 = Model3D(
          width: 2,
          length: 1.5,
          height: 1.5,
          position: Vector3(5, -4, 0),
          color: Colors.cyan,
        ).getObject3D(),
        box5 = Model3D(
          width: 1.5,
          length: 1.5,
          height: 1.25,
          position: Vector3(5, 6, 0),
          color: Colors.blue.shade400,
        ).getObject3D(),
        box6 = Model3D(
          width: 0.5,
          length: 0.75,
          height: 0.5,
          position: Vector3(5, 10, 0),
          color: Colors.pink.shade200,
        ).getObject3D(),
        box7 = Model3D(
          width: 1,
          length: 1,
          height: 2,
          position: Vector3(5, 3, 0),
          color: Colors.tealAccent,
        ).getObject3D(),
        box8 = Model3D(
          width: 1,
          length: 1,
          height: 1,
          position: Vector3(7, 7, 0),
          color: Colors.brown.shade600,
        ).getObject3D(),
        box9 = Model3D(
          width: 1,
          length: 1,
          height: 4,
          position: Vector3(7, 4, 0),
          color: Colors.grey,
        ).getObject3D();
    draggableObjects = [box1, box2, box3, box4, box5, box6, box7, box8, box9];

    var light = SpotLight(Color(0xffa95c), 1.0)
          ..position.x = 100
          ..position.y = 100
          ..position.z = 100
          ..castShadow = true,
        ambientLight = AmbientLight(Color(0xffeeb1), 0.4),
        hemisphereLight =
            HemisphereLight(Color(0xffeeb1), Color(0x080820), 0.5);
    var lights = [light, ambientLight, hemisphereLight];

    scene
      ..add(ground)
      ..addAll(truckContainer)
      ..addAll(lines)
      ..addAll(texts)
      ..addAll(draggableObjects)
      ..addAll(lights);

    boundaryObjects = [...draggableObjects, ...truckContainer]
      ..removeWhere((e) => e.name == 'truckBottom');

    Color? targetColor;

    controls.domElement
      ..addEventListener(
        'pointerdown',
        (event) {
          final vector = pointToVector2(event);
          raycasterObjects.setFromCamera(vector, camera);
          var intersects =
              raycasterObjects.intersectObjects(draggableObjects, true);
          if (intersects.isNotEmpty) {
            targetObject = intersects.first.object;
            targetColor = targetObject.material.color;
            targetObject.material
              ..color = Color(0X00aaffaa)
              ..transparent = true
              ..opacity = 0.8;

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
            targetObject.material
              ..opacity = 1
              ..color = targetColor;
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
    raycasterObjects = Raycaster()..setFromCamera(point, camera);
    var intersectingObjects = raycasterObjects.intersectObject(ground, false);
    if (intersectingObjects.isNotEmpty) {
      collisionObjects = [...boundaryObjects]..remove(targetObject);
      var pointOnGround = intersectingObjects[0].point;
      var dx = pointOnGround.x,
          dy = -pointOnGround.z,
          dz = targetObject.geometry?.parameters?['height'] / 2 + 0.000001;
      raycasterRoofs.setFromCamera(point, camera);
      var intersectingRoofs = raycasterRoofs.intersectObjects(
        collisionObjects,
        true,
      );
      if (intersectingRoofs.isNotEmpty) {
        var isCylinder =
            intersectingRoofs[0].object.geometry?.type == 'CylinderGeometry';
        var indexSide = Math.floor(
          intersectingRoofs[0].faceIndex / (isCylinder ? 100 : 2),
        );
        if (indexSide == 2) {
          var object = intersectingRoofs[0].object;
          var pos = object.position;
          var uv = intersectingRoofs[0].uv;
          var uvX = !isCylinder ? uv.x : uv.y;
          var uvY = !isCylinder ? uv.y : uv.x;
          var params = object.geometry?.parameters;
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

  Vector3? getNewPos(
    Object3D objectXY,
    Object3D objectX,
    Object3D objectY,
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

  Box3 getBox3(Object3D object) {
    return Box3().setFromObject(object);
  }

  Vector2 pointToVector2(WebPointerEvent point) {
    return Vector2(
      -(width / 2 - point.clientX) * 2 / width,
      (height / 2 - point.clientY) * 2 / height,
    );
  }

  Future<Font> loadFont() async {
    var fontJson = await textLoader.loadAsync(
      "${kIsWeb ? '/' : ''}assets/fonts/Figerona-VF.ttf",
    );
    return TYPRFont(fontJson);
  }

  Object3D createText(
    String text,
    Vector3 position, [
    Vector3? rotation,
  ]) {
    var textGeo = TextGeometry(
      text,
      {"font": textFont, "size": 0.25, "height": 0.001},
    );

    var material = MeshBasicMaterial({"color": 0x000000});
    var textMesh = Mesh(textGeo, material)
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
