import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gl/flutter_gl.dart';
import 'package:three_dart_jsm/three_dart_jsm.dart' as three_jsm;
import 'package:three_dart/three_dart.dart' as three;
import 'package:web_app/presentation/widgets/zoom_buttons.dart';

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
  late List<three.Object3D> draggableObjects, boundaryObjects, collisionObjects;
  late three.Object3D targetObject;

  late three.Texture groundTexture, containerTexture;

  late three.WebGLRenderTarget renderTarget;

  dynamic sourceTexture;

  bool loaded = false;

  int counter = 0;
  double fontHeight = 20, size = 70, hover = 30, curveSegments = 4, bevelThickness = 2, bevelSize = 1.5;

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

    groundTexture = await textureLoader.loadAsync('assets/grass.png');
    containerTexture = await textureLoader.loadAsync('assets/truck_container.jpg');

    textFont = await loadFont();

    // print("three3dRender.initialize three3dRender: ${three3dRender.textureId} ");

    setState(() {});

    // Wait for web
    Future.delayed(const Duration(milliseconds: 200), () async {
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
        child: FutureBuilder(
          future: initSize(context),
          builder: (context, snap) {
            return Stack(
              children: [
                three_jsm.DomLikeListenable(
                  key: globalKey,
                  builder: (_) => Container(
                    width: width,
                    height: height,
                    color: Colors.black,
                    child: Builder(
                      builder: (BuildContext context) {
                        return three3dRender.isInitialized
                            ? kIsWeb
                                ? HtmlElementView(viewType: three3dRender.textureId!.toString())
                                : Texture(textureId: three3dRender.textureId!)
                            : const Center(child: CircularProgressIndicator());
                      },
                    ),
                  ),
                ),
                if (three3dRender.isInitialized)
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
                if (three3dRender.isInitialized)
                  Positioned(
                    top: 20,
                    left: 20,
                    child: Center(
                      child: Object3DFormField(
                        callback: (model) {
                          final object = create3DObject(
                            width: model.width / 1000,
                            length: model.length / 1000,
                            height: model.height / 1000,
                            position: model.position,
                            color: Color.fromRGBO(
                              (three.Math.random() * 255).toInt(),
                              (three.Math.random() * 255).toInt(),
                              (three.Math.random() * 255).toInt(),
                              1,
                            ),
                            castShadow: true,
                          );

                          draggableObjects.add(object);
                          boundaryObjects.add(object);

                          scene.add(object);
                        },
                      ),
                    ),
                  )
              ],
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

  void initScene() async {
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

    // print('initRenderer  dpr: $dpr _options: $options');

    renderer = three.WebGLRenderer(options);
    renderer!.setPixelRatio(devicePixelRatio);
    renderer!.setSize(width, height, true);
    renderer!.shadowMap.enabled = true;
    renderer!.setClearColor(three.Color.fromHex(0xEEEEEE), 1.0);

    if (!kIsWeb) {
      var pars = three.WebGLRenderTargetOptions({"format": three.RGBAFormat});
      renderTarget =
          three.WebGLRenderTarget((width * devicePixelRatio).toInt(), (height * devicePixelRatio).toInt(), pars);
      renderTarget.samples = 4;
      renderer!.setRenderTarget(renderTarget);

      sourceTexture = renderer!.getRenderTargetGLTexture(renderTarget);
    }
  }

  void initPage() {
    final aspectRatio = width / height;

    scene = three.Scene()
      ..background = three.Color.setRGB255(255, 255, 255)
      ..rotateX(-pi / 2);

    camera = three.PerspectiveCamera(45, aspectRatio, 0.1, 1000)
      ..position.set(45, 30, 60)
      ..lookAt(scene.position);

    controls = three_jsm.OrbitControls(camera, globalKey)
      ..maxPolarAngle = three.Math.PI / 2.2
      ..maxDistance = 60
      ..minDistance = 5
      ..enableZoom = true
      ..dollyIn(0.3)
      ..update();

    raycasterObjects = three.Raycaster();
    raycasterRoofs = three.Raycaster();

    ground = create3DObject(
      width: 100,
      length: 100,
      texture: groundTexture,
      textureRepeat: true,
      countRepeat: 25,
    );

    var containerBottom = create3DObject(
          width: truckSize.y,
          length: truckSize.x,
          height: 0.01,
          rotation: three.Vector3(0, 0, pi / 2),
          texture: containerTexture,
        ),
        containerFront = create3DObject(
          width: truckSize.x,
          length: truckSize.z,
          position: three.Vector3(0, truckSize.y / 2, truckSize.z / 2),
          rotation: three.Vector3(pi / 2, 0, 0),
          texture: containerTexture,
        ),
        containerRight = create3DObject(
          width: truckSize.y,
          length: truckSize.z,
          position: three.Vector3(truckSize.x / 2, 0, truckSize.z / 2),
          rotation: three.Vector3(pi / 2, -pi / 2, 0),
          texture: containerTexture,
        ),
        containerLeft = create3DObject(
          width: truckSize.y,
          length: truckSize.z,
          position: three.Vector3(-truckSize.x / 2, 0, truckSize.z / 2),
          rotation: three.Vector3(pi / 2, pi / 2, 0),
          texture: containerTexture,
        ),
        containerBack = create3DObject(
          width: truckSize.x,
          length: truckSize.z,
          position: three.Vector3(0, -truckSize.y / 2, truckSize.z / 2),
          rotation: three.Vector3(pi / 2, pi, 0),
          texture: containerTexture,
        ),
        containerRoof = create3DObject(
          width: truckSize.y,
          length: truckSize.x,
          position: three.Vector3(0, 0, truckSize.z + 0.000001),
          rotation: three.Vector3(pi, 0, pi / 2),
          texture: containerTexture,
        );
    var truckContainer = [containerBottom, containerRight, containerLeft, containerFront, containerBack, containerRoof];

    var textMaterial = three.LineBasicMaterial()..color = three.Color.setRGB255(0, 0, 0);
    var linePointsLH = [
          three.Vector3(truckSize.x, -truckSize.y / 2, 0),
          three.Vector3(truckSize.x, truckSize.y / 2, 0),
          three.Vector3(truckSize.x, truckSize.y / 2, truckSize.z),
        ],
        linePointsW = [
          three.Vector3(-truckSize.x / 2, -truckSize.y / 2 - truckSize.x / 2, 0),
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
          three.Vector3(truckSize.x / 2, -truckSize.y / 2 - truckSize.x / 1.5, 0),
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
          three.Vector3(-truckSize.x / 2 - 0.2, -truckSize.y / 2 - truckSize.x / 1.5, 0),
        );
    var texts = [textWidth, textLength, textHeight, textZeroLH, textZeroW];

    var box1 = create3DObject(
          width: 0.2,
          length: 1,
          height: 1,
          position: three.Vector3(10, 0, 0),
          color: Colors.amber,
          castShadow: true,
        ),
        box2 = create3DObject(
          width: 1.5,
          length: 1.5,
          height: 1.5,
          position: three.Vector3(9, 2, 0),
          color: Colors.redAccent,
          castShadow: true,
        ),
        box3 = create3DObject(
          width: 1.1,
          length: 1.2,
          height: 1.5,
          position: three.Vector3(6, 0, 0),
          color: Colors.purple,
          castShadow: true,
        ),
        box4 = create3DObject(
          width: 2,
          length: 1.5,
          height: 1.5,
          position: three.Vector3(5, -4, 0),
          color: Colors.cyan,
          castShadow: true,
        ),
        box5 = create3DObject(
          width: 1.5,
          length: 1.5,
          height: 1.25,
          position: three.Vector3(5, 6, 0),
          color: Colors.blue.shade400,
          castShadow: true,
        ),
        box6 = create3DObject(
          width: 0.5,
          length: 0.75,
          height: 0.5,
          position: three.Vector3(5, 10, 0),
          color: Colors.pink.shade200,
          castShadow: true,
        ),
        box7 = create3DObject(
          width: 1,
          length: 1,
          height: 2,
          position: three.Vector3(5, 3, 0),
          color: Colors.tealAccent,
          castShadow: true,
        ),
        box8 = create3DObject(
          width: 1,
          length: 1,
          height: 1,
          position: three.Vector3(7, 7, 0),
          color: Colors.brown.shade600,
          castShadow: true,
        );
    draggableObjects = [box1, box2, box3, box4, box5, box6, box7, box8];

    var light = three.PointLight(three.Color.setRGB255(255, 255, 255), 1)
          ..position.z = 30
          ..position.x = 10
          ..position.y = 30
          ..castShadow = true,
        ambientLight = three.AmbientLight(three.Color(0xffffff), 0.5);
    var lights = [light, ambientLight];

    scene
      ..add(ground)
      ..addAll(truckContainer)
      ..addAll(lines)
      ..addAll(texts)
      ..addAll(draggableObjects)
      ..addAll(lights);

    boundaryObjects = [...draggableObjects, ...truckContainer]..remove(containerBottom);

    three.Color? targetColor;

    controls.domElement
      ..addEventListener(
        'pointerdown',
        (event) {
          final vector = pointToVector2(event);
          raycasterObjects.setFromCamera(vector, camera);
          var intersects = raycasterObjects.intersectObjects(draggableObjects, true);
          if (intersects.isNotEmpty) {
            targetObject = intersects.first.object;
            targetColor = targetObject.material.color;
            targetObject.material.color = three.Color(0X00aaffaa);
            controls
              ..enabled = false
              ..domElement.addEventListener('pointermove', dragObject);
          }
        },
      )
      ..addEventListener(
        'pointerup',
        (event) {
          if (targetColor != null) targetObject.material.color = targetColor;
          controls
            ..domElement.removeEventListener('pointermove', dragObject)
            ..enabled = true;
        },
      );

    loaded = true;
    animate();
  }

  void dragObject(event) {
    var point = pointToVector2(event);
    raycasterObjects = three.Raycaster()..setFromCamera(point, camera);
    var intersectingObjects = raycasterObjects.intersectObject(ground, false);
    if (intersectingObjects.isNotEmpty) {
      collisionObjects = [...boundaryObjects]..remove(targetObject);
      var pointOnGround = intersectingObjects[0].point;
      var dx = pointOnGround.x, dy = -pointOnGround.z, dz = targetObject.geometry?.parameters?['depth'] / 2 + 0.000001;
      raycasterRoofs.setFromCamera(point, camera);
      var intersectingRoofs = raycasterRoofs.intersectObjects(
        collisionObjects,
        true,
      );
      if (intersectingRoofs.isNotEmpty) {
        var indexSide = three.Math.floor(intersectingRoofs[0].faceIndex / 2);
        if (indexSide == 4) {
          var object = intersectingRoofs.first.object;
          var objectParams = object.geometry?.parameters;
          var uv = intersectingRoofs[0].uv;
          dx = object.position.x - objectParams?['width'] / 2 + objectParams?['width'] * uv.x;
          dy = object.position.y - objectParams?['height'] / 2 + objectParams?['height'] * uv.y;
          dz += object.position.z + objectParams?['depth'] / 2;
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
    var objects = collisionObjects;
    var intersects = List.generate(3, (_) => false);
    var boxXY = getBox3(objectXY), boxX = getBox3(objectX), boxY = getBox3(objectY);
    for (var key = 0; key < objects.length; key++) {
      var item = objects[key];
      var anotherBox = getBox3(item);
      if (anotherBox.intersectsBox(boxXY)) {
        intersects[0] = true;
        bool intersectX = anotherBox.intersectsBox(boxX), intersectY = anotherBox.intersectsBox(boxY);
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
    var fontJson = await textLoader.loadAsync("${kIsWeb ? '/' : ''}assets/fonts/Figerona-VF.ttf");
    return three.TYPRFont(fontJson);
  }

  three.Object3D createText(String text, three.Vector3 position, [three.Vector3? rotation]) {
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

  three.Object3D create3DObject({
    required double width,
    required double length,
    three.Vector3? position,
    three.Vector3? rotation,
    double? height,
    Color? color,
    three.Texture? texture,
    bool textureRepeat = false,
    double countRepeat = 10,
    bool castShadow = false,
  }) {
    if (texture != null && textureRepeat == true) {
      texture
        ..wrapS = three.RepeatWrapping
        ..wrapT = three.RepeatWrapping
        ..repeat.set(countRepeat, countRepeat);
    }
    final params = {
      "color": three.Color.setRGB255(
        color?.red ?? 255,
        color?.green ?? 255,
        color?.blue ?? 255,
      ),
      if (texture != null) "map": texture
    };

    final three.BufferGeometry geometry =
        height == null ? three.PlaneGeometry(width, length) : three.BoxGeometry(width, length, height);
    return three.Mesh(
      geometry,
      castShadow ? three.MeshPhongMaterial(params) : three.MeshBasicMaterial(params),
    )
      ..rotation.x = rotation?.x ?? 0
      ..rotation.y = rotation?.y ?? 0
      ..rotation.z = rotation?.z ?? 0
      ..position.x = position?.x ?? 0
      ..position.y = position?.y ?? 0
      ..position.z = (position?.z ?? 0) + ((height ?? 0) / 2)
      ..autoUpdate;
  }

  animate() {
    if (!mounted || disposed) {
      return;
    }

    if (!loaded) {
      return;
    }

    render();

    Future.delayed(const Duration(milliseconds: 15), () {
      animate();
    });
  }

  @override
  void dispose() {
    disposed = true;
    three3dRender.dispose();

    super.dispose();
  }
}
