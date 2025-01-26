import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_kakao_map_api/flutter_kakao_maps.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:screenshot/screenshot.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();

  KakaoMapsSDK.instance.init(
    appKey: 'YOUR NATIVE API KEY',
    debug: kDebugMode,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MainView(),
    );
  }
}

class MainView extends StatefulWidget {
  const MainView({super.key});

  @override
  State<StatefulWidget> createState() => _ViewState();
}

class _ViewState extends State<MainView> {
  final screenshotController = ScreenshotController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('카카오 지도 예제'),
      ),
      body: GestureDetector(
        onTap: () {
          screenshotController
              .capture(
                  pixelRatio: MediaQuery.of(context).devicePixelRatio * 2,
                  delay: const Duration(milliseconds: 0x200))
              .then((capturedImage) async {
            setState(() => MemoryImage(capturedImage!));
          }).catchError((onError) {
            if (kDebugMode) {
              print(onError);
            }
          });
        },
        child: Screenshot(
          controller: screenshotController,
          child: const Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      MainItem(
                        "지도 종류",
                        targetView: MapTypeView(),
                      ),
                      MainItem(
                        "지도 오버레이",
                        targetView: MapOverlayView(),
                      ),
                      MainItem(
                        "지도 활성화",
                        targetView: MapEnabledView(),
                      ),
                      MainItem(
                        "지도 빌딩 스케일",
                        targetView: MapBuildingScaleView(),
                      ),
                      MainItem(
                        "지도 패딩",
                        targetView: MapPaddingView(),
                      ),
                      MainItem(
                        "지도 로고",
                        targetView: MapLogoView(),
                      ),
                      MainItem(
                        "지도 포이",
                        targetView: MapPoiView(),
                      ),
                      MainItem(
                        "지도 나침반",
                        targetView: MapCompassView(),
                      ),
                      MainItem(
                        "지도 축척",
                        targetView: MapScaleBarView(),
                      ),
                      MainItem(
                        "지도 이동",
                        targetView: MapMoveView(),
                      ),
                      MainItem(
                        "지도 레이어",
                        targetView: MapLayerView(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MainItem extends StatelessWidget {
  final String text;
  final Widget targetView;

  const MainItem(
    this.text, {
    super.key,
    required this.targetView,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => targetView));
        },
        child: Text(text),
      ),
    );
  }
}

class MapTypeView extends StatefulWidget {
  const MapTypeView({super.key});

  @override
  State<StatefulWidget> createState() => _MapTypeViewState();
}

class _MapTypeViewState extends State<MapTypeView> {
  late final KakaoMapController kakaoMapController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("지도 종류"),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.list),
        onPressed: () {
          showCupertinoModalPopup(
            context: context,
            builder: (context) => CupertinoActionSheet(
              actions: [
                CupertinoActionSheetAction(
                  onPressed: () async {
                    await kakaoMapController.setViewInfo(
                        viewInfoName: KakaoMapViewInfo.map);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text("MAP"),
                ),
                CupertinoActionSheetAction(
                  onPressed: () async {
                    await kakaoMapController.setViewInfo(
                        viewInfoName: KakaoMapViewInfo.skyview);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text("SKYVIEW"),
                ),
              ],
            ),
          );
        },
      ),
      body: KakaoMapView(
        options: const KakaoMapOptions(
          viewInfoName: KakaoMapViewInfo.map,
        ),
        onCameraMove: (cp) {
          if (kDebugMode) {
            print(cp);
          }
        },
        onMapReady: (controller) => kakaoMapController = controller,
      ),
    );
  }
}

class MapOverlayView extends StatefulWidget {
  const MapOverlayView({super.key});

  @override
  State<StatefulWidget> createState() => _MapOverlayViewState();
}

class _MapOverlayViewState extends State<MapOverlayView> {
  late final KakaoMapController kakaoMapController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("지도 오버레이"),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.list),
        onPressed: () {
          showCupertinoModalPopup(
            context: context,
            builder: (context) => CupertinoActionSheet(
              actions: [
                CupertinoActionSheetAction(
                  onPressed: () async {
                    await kakaoMapController.showOverlay(
                        overlay: KakaoMapOverlay.hybrid);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text("SHOW HYBRID"),
                ),
                CupertinoActionSheetAction(
                  onPressed: () async {
                    await kakaoMapController.hideOverlay(
                        overlay: KakaoMapOverlay.hybrid);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text("HIDE HYBRID"),
                ),
                CupertinoActionSheetAction(
                  onPressed: () async {
                    await kakaoMapController.showOverlay(
                        overlay: KakaoMapOverlay.roadViewLine);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text("SHOW ROADVIEWLINE"),
                ),
                CupertinoActionSheetAction(
                  onPressed: () async {
                    await kakaoMapController.hideOverlay(
                        overlay: KakaoMapOverlay.roadViewLine);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text("HIDE ROADVIEWLINE"),
                ),
                CupertinoActionSheetAction(
                  onPressed: () async {
                    await kakaoMapController.showOverlay(
                        overlay: KakaoMapOverlay.hillShading);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text("SHOW HILLSHADING"),
                ),
                CupertinoActionSheetAction(
                  onPressed: () async {
                    await kakaoMapController.hideOverlay(
                        overlay: KakaoMapOverlay.hillShading);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text("HIDE HILLSHADING"),
                ),
                CupertinoActionSheetAction(
                  onPressed: () async {
                    await kakaoMapController.showOverlay(
                        overlay: KakaoMapOverlay.bicycleRoad);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text("SHOW BICYCLEROAD"),
                ),
                CupertinoActionSheetAction(
                  onPressed: () async {
                    await kakaoMapController.hideOverlay(
                        overlay: KakaoMapOverlay.bicycleRoad);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text("HIDE BICYCLEROAD"),
                ),
              ],
            ),
          );
        },
      ),
      body: KakaoMapView(
        options: const KakaoMapOptions(
          overlay: null,
        ),
        onCameraMove: (cp) {
          if (kDebugMode) {
            print(cp);
          }
        },
        onMapReady: (controller) => kakaoMapController = controller,
      ),
    );
  }
}

class MapEnabledView extends StatefulWidget {
  const MapEnabledView({super.key});

  @override
  State<StatefulWidget> createState() => _MapEnabledViewState();
}

class _MapEnabledViewState extends State<MapEnabledView> {
  late final KakaoMapController kakaoMapController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("지도 활성화"),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.list),
        onPressed: () {
          showCupertinoModalPopup(
            context: context,
            builder: (context) => CupertinoActionSheet(
              actions: [
                CupertinoActionSheetAction(
                  onPressed: () async {
                    await kakaoMapController.setEnabled(enabled: true);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text("ENABLED"),
                ),
                CupertinoActionSheetAction(
                  onPressed: () async {
                    await kakaoMapController.setEnabled(enabled: false);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text("DISABLED"),
                ),
              ],
            ),
          );
        },
      ),
      body: KakaoMapView(
        options: const KakaoMapOptions(
          enabled: false,
        ),
        onCameraMove: (cp) {
          if (kDebugMode) {
            print(cp);
          }
        },
        onMapReady: (controller) => kakaoMapController = controller,
      ),
    );
  }
}

class MapBuildingScaleView extends StatefulWidget {
  const MapBuildingScaleView({super.key});

  @override
  State<StatefulWidget> createState() => _MapBuildingScaleViewState();
}

class _MapBuildingScaleViewState extends State<MapBuildingScaleView> {
  late final KakaoMapController kakaoMapController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("지도 빌딩 스케일"),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.list),
        onPressed: () {
          showCupertinoModalPopup(
            context: context,
            builder: (context) => CupertinoActionSheet(
              actions: [
                CupertinoActionSheetAction(
                  onPressed: () async {
                    await kakaoMapController.setBuildingScale(buildingScale: 1);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text("1"),
                ),
                CupertinoActionSheetAction(
                  onPressed: () async {
                    await kakaoMapController.setBuildingScale(buildingScale: 0);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text("0"),
                ),
              ],
            ),
          );
        },
      ),
      body: KakaoMapView(
        options: const KakaoMapOptions(
          buildingScale: 1,
        ),
        onCameraMove: (cp) {
          if (kDebugMode) {
            print(cp);
          }
        },
        onMapReady: (controller) => kakaoMapController = controller,
      ),
    );
  }
}

class MapPaddingView extends StatefulWidget {
  const MapPaddingView({super.key});

  @override
  State<StatefulWidget> createState() => _MapPaddingViewState();
}

class _MapPaddingViewState extends State<MapPaddingView> {
  late final KakaoMapController kakaoMapController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("지도 패딩"),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.list),
        onPressed: () {
          showCupertinoModalPopup(
            context: context,
            builder: (context) => CupertinoActionSheet(
              actions: [
                CupertinoActionSheetAction(
                  onPressed: () async {
                    final padding = await kakaoMapController.getPadding();

                    Fluttertoast.showToast(
                      msg: "Padding: $padding",
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.CENTER,
                      timeInSecForIosWeb: 1,
                      backgroundColor: Colors.black,
                      textColor: Colors.white,
                      fontSize: 16.0,
                    );

                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text("GetPadding"),
                ),
                CupertinoActionSheetAction(
                  onPressed: () async {
                    await kakaoMapController.setPadding(
                      padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).size.height / 2,
                          right: MediaQuery.of(context).size.width / 2),
                    );
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text("SetPadding"),
                ),
              ],
            ),
          );
        },
      ),
      body: KakaoMapView(
        options: const KakaoMapOptions(
          padding: EdgeInsets.zero,
        ),
        onCameraMove: (cp) {
          if (kDebugMode) {
            print(cp);
          }
        },
        onMapReady: (controller) => kakaoMapController = controller,
      ),
    );
  }
}

class MapLogoView extends StatefulWidget {
  const MapLogoView({super.key});

  @override
  State<StatefulWidget> createState() => _MapLogoViewState();
}

class _MapLogoViewState extends State<MapLogoView> {
  late final KakaoMapController kakaoMapController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("지도 로고"),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.list),
        onPressed: () {
          showCupertinoModalPopup(
            context: context,
            builder: (context) => CupertinoActionSheet(
              actions: [
                CupertinoActionSheetAction(
                  onPressed: () async {
                    await kakaoMapController.setLogoPosition(
                        logoPosition: const KakaoMapPosition(
                            alignment: KakaoMapAlignment.topLeft, x: 0, y: 0));
                    await kakaoMapController.refresh();
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text("TopLeft"),
                ),
                CupertinoActionSheetAction(
                  onPressed: () async {
                    await kakaoMapController.setLogoPosition(
                        logoPosition: const KakaoMapPosition(
                            alignment: KakaoMapAlignment.topCenter,
                            x: 0,
                            y: 0));
                    await kakaoMapController.refresh();
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text("TopCenter"),
                ),
                CupertinoActionSheetAction(
                  onPressed: () async {
                    await kakaoMapController.setLogoPosition(
                        logoPosition: const KakaoMapPosition(
                            alignment: KakaoMapAlignment.topRight, x: 0, y: 0));
                    await kakaoMapController.refresh();
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text("TopRight"),
                ),
                CupertinoActionSheetAction(
                  onPressed: () async {
                    await kakaoMapController.setLogoPosition(
                        logoPosition: const KakaoMapPosition(
                            alignment: KakaoMapAlignment.centerLeft,
                            x: 0,
                            y: 0));
                    await kakaoMapController.refresh();
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text("CenterLeft"),
                ),
                CupertinoActionSheetAction(
                  onPressed: () async {
                    await kakaoMapController.setLogoPosition(
                        logoPosition: const KakaoMapPosition(
                            alignment: KakaoMapAlignment.center, x: 0, y: 0));
                    await kakaoMapController.refresh();
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text("Center"),
                ),
                CupertinoActionSheetAction(
                  onPressed: () async {
                    await kakaoMapController.setLogoPosition(
                        logoPosition: const KakaoMapPosition(
                            alignment: KakaoMapAlignment.centerRight,
                            x: 0,
                            y: 0));
                    await kakaoMapController.refresh();
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text("CenterRight"),
                ),
                CupertinoActionSheetAction(
                  onPressed: () async {
                    await kakaoMapController.setLogoPosition(
                        logoPosition: const KakaoMapPosition(
                            alignment: KakaoMapAlignment.bottomLeft,
                            x: 0,
                            y: 0));
                    await kakaoMapController.refresh();
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text("BottomLeft"),
                ),
                CupertinoActionSheetAction(
                  onPressed: () async {
                    await kakaoMapController.setLogoPosition(
                        logoPosition: const KakaoMapPosition(
                            alignment: KakaoMapAlignment.bottomCenter,
                            x: 0,
                            y: 0));
                    await kakaoMapController.refresh();
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text("BottomCenter"),
                ),
                CupertinoActionSheetAction(
                  onPressed: () async {
                    await kakaoMapController.setLogoPosition(
                        logoPosition: const KakaoMapPosition(
                            alignment: KakaoMapAlignment.bottomRight,
                            x: 0,
                            y: 0));
                    await kakaoMapController.refresh();
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text("BottomRight"),
                ),
              ],
            ),
          );
        },
      ),
      body: KakaoMapView(
        options: const KakaoMapOptions(
          logoPosition: KakaoMapPosition(
            alignment: KakaoMapAlignment.bottomRight,
            x: 0,
            y: 0,
          ),
        ),
        onCameraMove: (cp) {
          if (kDebugMode) {
            print(cp);
          }
        },
        onMapReady: (controller) => kakaoMapController = controller,
      ),
    );
  }
}

class MapPoiView extends StatefulWidget {
  const MapPoiView({super.key});

  @override
  State<StatefulWidget> createState() => _MapPoiViewState();
}

class _MapPoiViewState extends State<MapPoiView> {
  late final KakaoMapController kakaoMapController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("지도 포이"),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.list),
        onPressed: () {
          showCupertinoModalPopup(
            context: context,
            builder: (context) => CupertinoActionSheet(
              actions: [
                CupertinoActionSheetAction(
                  onPressed: () async {
                    await kakaoMapController.setPoiOptions(
                        poiOptions: const KakaoMapPoiOptions());
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text("ENABLED"),
                ),
                CupertinoActionSheetAction(
                  onPressed: () async {
                    await kakaoMapController.setPoiOptions(
                        poiOptions: const KakaoMapPoiOptions(enabled: false));
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text("DISABLED"),
                ),
                CupertinoActionSheetAction(
                  onPressed: () async {
                    await kakaoMapController.setPoiOptions(
                        poiOptions: const KakaoMapPoiOptions(
                            scale: KakaoMapPoiScale.small));
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text("SMALL"),
                ),
                CupertinoActionSheetAction(
                  onPressed: () async {
                    await kakaoMapController.setPoiOptions(
                        poiOptions: const KakaoMapPoiOptions(
                            scale: KakaoMapPoiScale.regular));
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text("REGULAR"),
                ),
                CupertinoActionSheetAction(
                  onPressed: () async {
                    await kakaoMapController.setPoiOptions(
                        poiOptions: const KakaoMapPoiOptions(
                            scale: KakaoMapPoiScale.large));
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text("LARGE"),
                ),
                CupertinoActionSheetAction(
                  onPressed: () async {
                    await kakaoMapController.setPoiOptions(
                        poiOptions: const KakaoMapPoiOptions(
                            scale: KakaoMapPoiScale.xLarge));
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text("XLARGE"),
                ),
              ],
            ),
          );
        },
      ),
      body: KakaoMapView(
        options: const KakaoMapOptions(
          poiOptions: KakaoMapPoiOptions(
            clickable: true,
            enabled: true,
            scale: KakaoMapPoiScale.regular,
          ),
        ),
        onCameraMove: (cp) {
          if (kDebugMode) {
            print(cp);
          }
        },
        onMapReady: (controller) => kakaoMapController = controller,
      ),
    );
  }
}

class MapCompassView extends StatefulWidget {
  const MapCompassView({super.key});

  @override
  State<StatefulWidget> createState() => _MapCompassViewState();
}

class _MapCompassViewState extends State<MapCompassView> {
  late final KakaoMapController kakaoMapController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("지도 나침반"),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.list),
        onPressed: () {
          showCupertinoModalPopup(
            context: context,
            builder: (context) => CupertinoActionSheet(
              actions: [
                CupertinoActionSheetAction(
                  onPressed: () async {
                    await kakaoMapController.setCompassOptions(
                      compassOptions: const CompassOptions(
                        enabled: true,
                        position: KakaoMapPosition(
                          alignment: KakaoMapAlignment.center,
                          x: 0,
                          y: 0,
                        ),
                      ),
                    );
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text("ENABLED"),
                ),
                CupertinoActionSheetAction(
                  onPressed: () async {
                    await kakaoMapController.setCompassOptions(
                      compassOptions: const CompassOptions(
                        enabled: false,
                        position: KakaoMapPosition(
                          alignment: KakaoMapAlignment.center,
                          x: 0,
                          y: 0,
                        ),
                      ),
                    );
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text("DISABLED"),
                ),
              ],
            ),
          );
        },
      ),
      body: KakaoMapView(
        options: const KakaoMapOptions(
          compassOptions: CompassOptions(
            enabled: false,
            position: KakaoMapPosition(
              alignment: KakaoMapAlignment.center,
              x: 0,
              y: 0,
            ),
          ),
        ),
        onCameraMove: (cp) {
          if (kDebugMode) {
            print(cp);
          }
        },
        onMapReady: (controller) => kakaoMapController = controller,
      ),
    );
  }
}

class MapMoveView extends StatefulWidget {
  const MapMoveView({super.key});

  @override
  State<StatefulWidget> createState() => _MapMoveViewState();
}

class _MapMoveViewState extends State<MapMoveView> {
  late final KakaoMapController kakaoMapController;

  Future _onPressed() async {
    final cp = await kakaoMapController.getCameraPosition();

    if (kDebugMode) {
      print('camera position:: $cp');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("지도 이동"),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.list),
        onPressed: () {
          showCupertinoModalPopup(
            context: context,
            builder: (context) => CupertinoActionSheet(
              actions: [
                CupertinoActionSheetAction(
                  onPressed: () async {
                    await kakaoMapController.moveCamera(
                      target: const KakaoMapPoint(
                          longitude: 126.972591728, latitude: 37.552987017),
                    );
                    // await kakaoMapController.animateCamera(
                    //   target: const KakaoMapPoint(longitude: 126.972591728, latitude: 37.552987017),
                    // );
                    _onPressed();
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text("서울역 이동"),
                ),
                CupertinoActionSheetAction(
                  onPressed: () async {
                    await kakaoMapController.moveCamera(
                      target: const KakaoMapPoint(
                          longitude: 129.041418419, latitude: 35.115078556),
                    );
                    // await kakaoMapController.animateCamera(
                    //   target: const KakaoMapPoint(longitude: 129.041418419, latitude: 35.115078556),
                    // );
                    _onPressed();
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text("부산역 이동"),
                ),
                CupertinoActionSheetAction(
                  onPressed: () async {
                    await kakaoMapController.moveCameraTransform(
                      point:
                          const KakaoMapPoint(longitude: 0, latitude: 0.000898),
                    );
                    // await kakaoMapController.animateCameraTransform(
                    //   point: const KakaoMapPoint(longitude: 0, latitude: 0.000898),
                    // );
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text("상단 이동"),
                ),
                CupertinoActionSheetAction(
                  onPressed: () async {
                    await kakaoMapController.moveCameraTransform(
                      point: const KakaoMapPoint(
                          longitude: 0, latitude: -0.000898),
                    );
                    // await kakaoMapController.animateCameraTransform(
                    //   point: const KakaoMapPoint(longitude: 0, latitude: -0.000898),
                    // );
                    _onPressed();
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text("하단 이동"),
                ),
                CupertinoActionSheetAction(
                  onPressed: () async {
                    await kakaoMapController.moveCameraTransform(
                      point: const KakaoMapPoint(
                          longitude: -0.000898, latitude: 0),
                    );
                    // await kakaoMapController.animateCameraTransform(
                    //   point: const KakaoMapPoint(longitude: -0.000898, latitude: 0),
                    // );
                    _onPressed();
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text("왼쪽 이동"),
                ),
                CupertinoActionSheetAction(
                  onPressed: () async {
                    await kakaoMapController.moveCameraTransform(
                      point:
                          const KakaoMapPoint(longitude: 0.000898, latitude: 0),
                    );
                    // await kakaoMapController.animateCameraTransform(
                    //   point: const KakaoMapPoint(longitude: 0.000898, latitude: 0),
                    // );
                    _onPressed();
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text("오른쪽 이동"),
                ),
              ],
            ),
          );
        },
      ),
      body: KakaoMapView(
        options: const KakaoMapOptions(
          overlay: KakaoMapOverlay.hillShading,
          scaleBarOptions: ScaleBarOptions(
            position: KakaoMapPosition(
              alignment: KakaoMapAlignment.bottomRight,
              x: 4,
              y: 4,
            ),
            autoDisabled: false,
          ),
          logoPosition: KakaoMapPosition(
            alignment: KakaoMapAlignment.bottomLeft,
            x: 4,
            y: 4,
          ),
        ),
        onCameraMove: (cp) {},
        onMapReady: (controller) => kakaoMapController = controller,
      ),
    );
  }
}

class MapScaleBarView extends StatefulWidget {
  const MapScaleBarView({super.key});

  @override
  State<StatefulWidget> createState() => _MapScaleBarViewState();
}

class _MapScaleBarViewState extends State<MapScaleBarView> {
  late final KakaoMapController kakaoMapController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("지도 축척"),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.list),
        onPressed: () {
          showCupertinoModalPopup(
            context: context,
            builder: (context) => CupertinoActionSheet(
              actions: [
                CupertinoActionSheetAction(
                  onPressed: () async {
                    await kakaoMapController.setScaleBarOptions(
                      scaleBarOptions: const ScaleBarOptions(
                        enabled: true,
                        position: KakaoMapPosition(
                          alignment: KakaoMapAlignment.center,
                          x: 0,
                          y: 0,
                        ),
                      ),
                    );
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text("ENABLED"),
                ),
                CupertinoActionSheetAction(
                  onPressed: () async {
                    await kakaoMapController.setScaleBarOptions(
                      scaleBarOptions: const ScaleBarOptions(
                        enabled: false,
                        position: KakaoMapPosition(
                          alignment: KakaoMapAlignment.center,
                          x: 0,
                          y: 0,
                        ),
                      ),
                    );
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text("DISABLED"),
                ),
              ],
            ),
          );
        },
      ),
      body: KakaoMapView(
        options: const KakaoMapOptions(
          scaleBarOptions: ScaleBarOptions(
            enabled: false,
            position: KakaoMapPosition(
              alignment: KakaoMapAlignment.center,
              x: 0,
              y: 0,
            ),
            autoDisabled: true,
            fadeInOutOptions: FadeInOutOptions(
              fadeInTime: 300,
              fadeOutTime: 300,
              retentionTime: 3000,
            ),
          ),
        ),
        onCameraMove: (cp) {
          if (kDebugMode) {
            print(cp);
          }
        },
        onMapReady: (controller) => kakaoMapController = controller,
      ),
    );
  }
}

class MapLayerView extends StatefulWidget {
  const MapLayerView({super.key});

  @override
  State<StatefulWidget> createState() => _MapLayerViewState();
}

class _MapLayerViewState extends State<MapLayerView> {
  late final KakaoMapController kakaoMapController;
  late final KakaoMapLabelLayer labelLayer;
  late final KakaoMapLabelLayer lodLabelLayer;
  late final KakaoMapPoi poi;

  Image? _image;

  final screenshotController = ScreenshotController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("지도 레이어"),
      ),
      floatingActionButton: FloatingActionButton(
        child: _image ?? const Icon(Icons.list),
        onPressed: () {
          showCupertinoModalPopup(
            context: context,
            builder: (context) => CupertinoActionSheet(
              actions: [
                CupertinoActionSheetAction(
                  onPressed: () async {
                    screenshotController
                        .capture(
                            pixelRatio: MediaQuery.of(context).devicePixelRatio,
                            delay: const Duration(milliseconds: 0x200))
                        .then((capturedImage) async {
                      setState(() {
                        _image = Image.memory(capturedImage!);
                      });
                    }).catchError((onError) {
                      if (kDebugMode) {
                        print(onError);
                      }
                    });
                    await poi.changePoiIconStyle(
                      styleID: "style1",
                    );
                    if (context.mounted) Navigator.pop(context);

                    kakaoMapController.addPolygon(const KakaoMapPolygon(
                      point: KakaoMapPoint(
                        longitude: 127.108678,
                        latitude: 37.402001,
                      ),
                    ));
                  },
                  child: const Text("STYLE1"),
                ),
                CupertinoActionSheetAction(
                  onPressed: () async {
                    await poi.changePoiIconStyle(
                      styleID: "style2",
                    );
                    if (context.mounted) Navigator.pop(context);

                    await lodLabelLayer.addLodLabel(
                      styleId: 'style2',
                      position: const KakaoMapPoint(
                        labelId: 'point',
                        longitude: 127.709778,
                        latitude: 37.303101,
                      ),
                    );

                    await labelLayer.removeAllRouteLine();
                  },
                  child: const Text("STYLE2"),
                ),
                CupertinoActionSheetAction(
                  onPressed: () async {
                    const point = KakaoMapPoint(
                      longitude: 127.708678,
                      latitude: 37.102001,
                    );
                    final routeLine = await labelLayer.addRouteLine(
                      [const KakaoMapRouteLineStyle()],
                      [
                        const KakaoMapPoint(
                          longitude: 127.108678,
                          latitude: 37.402001,
                        ),
                        point
                      ],
                    );
                    await poi.movePoi(at: point, poiId: poi.id);

                    if (context.mounted) Navigator.pop(context);

                    await routeLine.moveRouteLine(const KakaoMapPoint(
                      longitude: 127.709778,
                      latitude: 37.303101,
                    ));

                    await routeLine.moveRouteLine(const KakaoMapPoint(
                      longitude: 127.739778,
                      latitude: 37.333101,
                    ));

                    await Future.delayed(const Duration(seconds: 5));

                    await routeLine.modifyRouteLine(const KakaoMapPoint(
                      longitude: 127.108678,
                      latitude: 37.402001,
                    ));

                    await kakaoMapController.removeAllShapePolygon();
                  },
                  child: const Text("Move"),
                ),
              ],
            ),
          );
        },
      ),
      body: Screenshot(
        controller: screenshotController,
        child: KakaoMapView(
          options: const KakaoMapOptions(),
          onCameraMove: (cp) {
            if (kDebugMode) {
              print(cp);
            }
          },
          onLodLabelClicked: (label) async {
            if (kDebugMode) {
              print(await lodLabelLayer.removeLodLabel(label.labelId));
            }
          },
          onMapReady: (controller) async {
            labelLayer = await controller.addLabelLayer(layerID: "labelLayer1");
            lodLabelLayer =
                await controller.addLodLabelLayer(layerID: "lodlabelLayer1");

            await controller.addPoiIconStyle(
              styleID: "style1",
              styles: [
                const KakaoMapPoiIconStyle(
                  symbol: "assets/pin.png",
                  height: 10,
                  width: 10,
                  anchorPoint: KakaoMapPoint(longitude: 0.5, latitude: 1),
                ),
              ],
            );

            await controller.addPoiIconStyle(
              styleID: "style2",
              styles: [
                const KakaoMapPoiIconStyle(
                  symbol: "assets/buttons/btn_warning_location.png",
                  height: 18,
                  width: 18,
                  anchorPoint: KakaoMapPoint(longitude: 0.5, latitude: 1),
                ),
              ],
            );

            poi = await labelLayer.addPoi(
              styleID: "style1",
              at: const KakaoMapPoint(
                longitude: 127.108678,
                latitude: 37.402001,
              ),
            );

            if (kDebugMode) {
              print(await lodLabelLayer.addLodLabels(
                styleId: 'style2',
                positions: [
                  const KakaoMapPoint(
                      labelId: "1", longitude: 127.108178, latitude: 37.405001),
                  const KakaoMapPoint(
                      labelId: "2", longitude: 127.108278, latitude: 37.404001),
                  const KakaoMapPoint(
                      labelId: "3", longitude: 127.108378, latitude: 37.403001),
                  const KakaoMapPoint(
                      labelId: "4", longitude: 127.108478, latitude: 37.402091),
                  const KakaoMapPoint(
                      labelId: "5", longitude: 127.108578, latitude: 37.402081),
                  const KakaoMapPoint(
                      labelId: "6", longitude: 127.108678, latitude: 37.402071),
                  const KakaoMapPoint(
                      labelId: "7", longitude: 127.108778, latitude: 37.402061),
                  const KakaoMapPoint(
                      labelId: "8", longitude: 127.108878, latitude: 37.402051),
                  const KakaoMapPoint(
                      labelId: "9", longitude: 127.108978, latitude: 37.402041),
                  const KakaoMapPoint(
                      labelId: "10",
                      longitude: 127.108618,
                      latitude: 37.402031),
                  const KakaoMapPoint(
                      labelId: "11",
                      longitude: 127.108628,
                      latitude: 37.402021),
                  const KakaoMapPoint(
                      labelId: "12",
                      longitude: 127.108638,
                      latitude: 37.402011),
                  const KakaoMapPoint(
                      labelId: "13",
                      longitude: 127.108648,
                      latitude: 37.402901),
                  const KakaoMapPoint(
                      labelId: "14",
                      longitude: 127.108658,
                      latitude: 37.402801),
                  const KakaoMapPoint(
                      labelId: "15",
                      longitude: 127.108668,
                      latitude: 37.402701),
                  const KakaoMapPoint(
                      labelId: "16",
                      longitude: 127.108678,
                      latitude: 37.402601),
                  const KakaoMapPoint(
                      labelId: "17",
                      longitude: 127.108688,
                      latitude: 37.402501),
                  const KakaoMapPoint(
                      labelId: "18",
                      longitude: 127.108698,
                      latitude: 37.402401),
                  const KakaoMapPoint(
                      labelId: "19",
                      longitude: 127.108679,
                      latitude: 37.402301),
                  const KakaoMapPoint(
                      labelId: "20",
                      longitude: 127.108671,
                      latitude: 37.402201),
                  const KakaoMapPoint(
                      labelId: "21",
                      longitude: 127.108672,
                      latitude: 37.402101),
                ],
              ));
            }
            kakaoMapController = controller;
          },
        ),
      ),
    );
  }
}
