import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gl/flutter_gl.dart';
import 'package:three_dart_jsm/three_dart_jsm.dart' as three_jsm;
import 'package:three_dart/three_dart.dart' as three;
import 'package:web_app/presentation/widgets/zoom_buttons.dart';

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
  late List<three.Object3D> boxes;
  late three.Object3D targetObject;
  late three.Object3D draggableProjection;

  late three.Texture groundTexture, containerTexture;

  late three.WebGLRenderTarget renderTarget;

  dynamic sourceTexture;

  bool loaded = false;

  int counter = 0;
  double fontHeight = 20, size = 70, hover = 30, curveSegments = 4, bevelThickness = 2, bevelSize = 1.5;

  final globalKey = GlobalKey<three_jsm.DomLikeListenableState>();
  late three_jsm.OrbitControls controls;
  late three.Raycaster raycaster;
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
      body: Builder(
        builder: (context) {
          initSize(context);
          return SingleChildScrollView(
            child: Stack(
              children: [
                three_jsm.DomLikeListenable(
                  key: globalKey,
                  builder: (_) => Container(
                    width: width,
                    height: height,
                    color: Colors.red,
                    child: Builder(
                      builder: (BuildContext context) {
                        if (kIsWeb) {
                          return three3dRender.isInitialized
                              ? HtmlElementView(viewType: three3dRender.textureId!.toString())
                              : const Center(child: CircularProgressIndicator());
                        } else {
                          return three3dRender.isInitialized
                              ? Texture(textureId: three3dRender.textureId!)
                              : Container(color: Colors.red);
                        }
                      },
                    ),
                  ),
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
                )
              ],
            ),
          );
        },
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
      ..rotateX(-three.Math.PI / 2);

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

    raycaster = three.Raycaster();

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
        );
    var truckContainer = [containerBottom, containerRight, containerLeft, containerFront, containerBack];

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
          width: 2,
          length: 2,
          height: 2,
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
          width: 2.5,
          length: 2.5,
          height: 1.5,
          position: three.Vector3(6, 0, 0),
          color: Colors.purple,
          castShadow: true,
        ),
        box4 = create3DObject(
          width: 2,
          length: 4.5,
          height: 2.5,
          position: three.Vector3(5, -4, 0),
          color: Colors.cyan,
          castShadow: true,
        );
    boxes = [box1, box2, box3, box4];

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
      ..addAll(boxes)
      ..addAll(lights);

    controls.domElement
      ..addEventListener(
        'pointerdown',
        (event) {
          final vector = pointToVector2(event);
          raycaster.setFromCamera(vector, camera);
          var intersects = raycaster.intersectObjects(boxes, true);
          if (intersects.isNotEmpty) {
            targetObject = intersects.first.object;
            controls
              ..enabled = false
              ..domElement.addEventListener('pointermove', dragObject);
          }
        },
      )
      ..addEventListener(
        'pointerup',
        (event) {
          controls
            ..domElement.removeEventListener('pointermove', dragObject)
            ..enabled = true;
        },
      );

    loaded = true;
    animate();
  }

  void dragObject(event) {
    final point = pointToVector2(event);
    raycaster.setFromCamera(point, camera);
    var intersects = raycaster.intersectObject(ground, false);
    if (intersects.isNotEmpty) {
      var point = intersects.first.point;
      draggableProjection = targetObject.clone()
        ..position.set(point.x, -point.z, targetObject.position.z)
        ..name = 'boundingbox';
      scene.add(draggableProjection..visible = false);
      if (!intersectObjMas(draggableProjection, [...boxes]..remove(targetObject))) {
        targetObject.position.set(point.x, -point.z);
      }
    }
  }

  bool intersectObjMas(three.Object3D target, List<three.Object3D> objects) {
    final box = three.Box3().setFromObject(target);
    for (var item in objects) {
      final anotherBox = three.Box3().setFromObject(item);
      if (box.intersectsBox(anotherBox)) {
        scene.remove(scene.getObjectByName('boundingbox')!);
        return true;
      }
    }
    return false;
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
      "map": texture
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

    // cube.position.x += 0.1;
    // cube.position.z += 0.05;
    // scene.rotation.z += 0.05;
    // camera..zoom += 0.01..updateProjectionMatrix();

    render();

    Future.delayed(const Duration(milliseconds: 15), () {
      animate();
    });
  }

  @override
  void dispose() {
    print(" dispose ............. ");

    disposed = true;
    three3dRender.dispose();

    super.dispose();
  }
}
