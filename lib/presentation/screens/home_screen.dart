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
  late three.TextureLoader loader;

  late double width;
  late double height;

  Size? screenSize;

  late three.Scene scene;
  late three.Camera camera;
  late three.Object3D container;

  double devicePixelRatio = 1.0;

  var amount = 4;

  bool verbose = true;
  bool disposed = false;

  late three.Object3D object;

  // late three.Texture texture;

  late three.WebGLRenderTarget renderTarget;

  dynamic sourceTexture;

  bool loaded = false;

  int counter = 0;
  double fontHeight = 20, size = 70, hover = 30, curveSegments = 4, bevelThickness = 2, bevelSize = 1.5;

  final GlobalKey<three_jsm.DomLikeListenableState> globalKey = GlobalKey<three_jsm.DomLikeListenableState>();
  late three_jsm.OrbitControls controls;

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
    loader = three.TextureLoader(null);

    // print("three3dRender.initialize three3dRender: ${three3dRender.textureId} ");

    setState(() {});

    // Wait for web
    Future.delayed(const Duration(milliseconds: 200), () async {
      await three3dRender.prepareContext();

      initScene();
    });
  }

  initSize(BuildContext context) {
    if (screenSize != null) {
      return;
    }

    final mqd = MediaQuery.of(context);

    screenSize = mqd.size;
    devicePixelRatio = mqd.devicePixelRatio;

    initPlatformState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(
        builder: (BuildContext context) {
          initSize(context);
          return SingleChildScrollView(child: _build(context));
        },
      ),
    );
  }

  Widget _build(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            three_jsm.DomLikeListenable(
              key: globalKey,
              builder: (context) => Container(
                width: width,
                height: height,
                color: Colors.grey.shade100,
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
      ],
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

  initRenderer() {
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

  void initScene() async {
    initRenderer();
    initPage();
  }

  void initPage() async {
    final aspectRatio = width / height;

    camera = three.PerspectiveCamera(45, aspectRatio, 0.1, 1000);

    scene = three.Scene();
    scene.background = three.Color.setRGB255(255, 255, 255);
    scene.rotateX(-three.Math.PI / 2);
    camera
      ..position.set(45, 30, 60)
      ..lookAt(scene.position);

    controls = three_jsm.OrbitControls(camera, globalKey)
      ..maxPolarAngle = three.Math.PI / 2.2
      ..maxDistance = 60
      ..minDistance = 5
      ..enableZoom = true
      ..dollyIn(0.3)
      ..update();

    final ground = await create3DObject(
      width: 100,
      length: 100,
      asset: 'assets/grass.png',
      textureRepeat: true,
      countRepeat: 25,
    );
    final box1 = await create3DObject(
      width: 2,
      length: 2,
      height: 2,
      position: three.Vector3(10, 0, 0),
      color: Colors.amber,
      castShadow: true,
    );
    final box2 = await create3DObject(
      width: 1.5,
      length: 1.5,
      height: 1.5,
      position: three.Vector3(9, 2, 0),
      color: Colors.redAccent,
      castShadow: true,
    );
    var containerBottom = await create3DObject(
      width: truckSize.y,
      length: truckSize.x,
      height: 0.01,
      rotation: three.Vector3(0, 0, pi / 2),
      asset: 'assets/truck_container.jpg',
    );
    var containerFront = await create3DObject(
      width: truckSize.x,
      length: truckSize.z,
      position: three.Vector3(0, truckSize.y / 2, truckSize.z / 2),
      rotation: three.Vector3(pi / 2, 0, 0),
      asset: 'assets/truck_container.jpg',
    );
    var containerRight = await create3DObject(
      width: truckSize.y,
      length: truckSize.z,
      position: three.Vector3(truckSize.x / 2, 0, truckSize.z / 2),
      rotation: three.Vector3(pi / 2, -pi / 2, 0),
      asset: 'assets/truck_container.jpg',
    );
    var containerLeft = await create3DObject(
      width: truckSize.y,
      length: truckSize.z,
      position: three.Vector3(-truckSize.x / 2, 0, truckSize.z / 2),
      rotation: three.Vector3(pi / 2, pi / 2, 0),
      asset: 'assets/truck_container.jpg',
    );
    var containerBack = await create3DObject(
      width: truckSize.x,
      length: truckSize.z,
      position: three.Vector3(0, -truckSize.y / 2, truckSize.z / 2),
      rotation: three.Vector3(pi / 2, pi, 0),
      asset: 'assets/truck_container.jpg',
    );

    scene.addAll([containerBottom, containerRight, containerLeft, containerFront, containerBack]);

    var pointsLH = [
      three.Vector3(truckSize.x, -truckSize.y / 2, 0),
      three.Vector3(truckSize.x, truckSize.y / 2, 0),
      three.Vector3(truckSize.x, truckSize.y / 2, truckSize.z),
    ];
    var pointsW = [
      three.Vector3(-truckSize.x / 2, -truckSize.y / 2 - truckSize.x / 2, 0),
      three.Vector3(truckSize.x / 2, -truckSize.y / 2 - truckSize.x / 2, 0),
    ];
    var geometryLH = three.BufferGeometry().setFromPoints(pointsLH);
    var arrowLH = three.Line(
      geometryLH,
      three.LineBasicMaterial()..color = three.Color.setRGB255(0, 0, 0),
    );
    var geometryW = three.BufferGeometry().setFromPoints(pointsW);
    var arrowW = three.Line(
      geometryW,
      three.LineBasicMaterial()..color = three.Color.setRGB255(0, 0, 0),
    );
    var textWidth = await createText(
      '${truckSize.x * 1000}',
      three.Vector3(truckSize.x / 2, -truckSize.y / 2 - truckSize.x / 1.5, 0),
    );
    var textLength = await createText(
      '${truckSize.y * 1000}',
      three.Vector3(truckSize.x * 1.2, -truckSize.y / 2, 0),
      three.Vector3(0, 0, pi / 2),
    );
    var textHeight = await createText(
      '${truckSize.z * 1000}',
      three.Vector3(truckSize.x, truckSize.y / 2, truckSize.z),
      three.Vector3(pi / 2, pi / 4),
    );
    var textZeroLH = await createText(
      '0',
      three.Vector3(truckSize.x * 1.2, truckSize.y / 2 - 0.2, 0),
      three.Vector3(0, 0, pi / 2),
    );
    var textZeroW = await createText(
      '0',
      three.Vector3(-truckSize.x / 2 - 0.2, -truckSize.y / 2 - truckSize.x / 1.5, 0),
    );

    scene.addAll([textWidth, textLength, textHeight, textZeroLH, textZeroW]);
    scene.addAll([ground, box1, box2, arrowLH, arrowW]);

    var light = three.PointLight(three.Color.setRGB255(255, 255, 255), 1)
      ..position.z = 30
      ..position.x = 30
      ..position.y = 30
      ..castShadow = true;

    scene.addAll([light, three.AmbientLight(three.Color(0xffffff), 0.3)]);

    // var raycaster = three.Raycaster();
    // renderer?.domElement.addEventListener(
    //   'mousedown',
    //   (event) {
    //     final vector = three.Vector2(
    //       -(width / 2 - event.offset.x) * 2 / width,
    //       (height / 2 - event.offset.y) * 2 / height,
    //     );
    //     raycaster.setFromCamera(vector, camera);
    //     var intersects = raycaster.intersectObject(ground, false);
    //     if (intersects.isNotEmpty) {
    //       // cube
    //       //   ..rotateX(pi / 4)
    //       //   ..rotateY(pi / 4);
    //       counter += 1;
    //       print(intersects.length);
    //       print(intersects[0].object.id);
    //       setState(() {});
    //     }
    //     // print('Z: ${vector.z}');
    //   },
    //   true,
    // );

    loaded = true;
    animate();
  }

  Future<three.Font> loadFont() async {
    var loader = three_jsm.TYPRLoader(null);
    var fontJson = await loader.loadAsync("${kIsWeb ? '/' : ''}assets/fonts/Figerona-VF.ttf");
    return three.TYPRFont(fontJson);
  }

  Future<three.Object3D> createText(String text, three.Vector3 position, [three.Vector3? rotation]) async {
    var font = await loadFont();
    var textGeo = three.TextGeometry(
      text,
      {"font": font, "size": 0.25, "height": 0.001},
    );

    var material = three.MeshBasicMaterial({"color": 0x000000});

    var textMesh = three.Mesh(textGeo, material);

    textMesh.position
      ..x = position.x
      ..y = position.y
      ..z = position.z;
    textMesh.rotation
      ..x = rotation?.x ?? 0
      ..y = rotation?.y ?? 0
      ..z = rotation?.z ?? 0;
    return textMesh;
  }

  Future<three.Object3D> create3DObject({
    required double width,
    required double length,
    three.Vector3? position,
    three.Vector3? rotation,
    double? height,
    Color? color,
    String? asset,
    bool textureRepeat = false,
    int? countRepeat,
    bool castShadow = false,
  }) async {
    final texture = asset != null ? (await loader.loadAsync(asset)) : null;
    if (asset != null && textureRepeat == true) {
      texture!
        ..wrapS = three.RepeatWrapping
        ..wrapT = three.RepeatWrapping
        ..repeat.set((countRepeat ?? 10).toDouble(), (countRepeat ?? 10).toDouble());
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
      ..position.z = (position?.z ?? 0) + ((height ?? 0) / 2);
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
