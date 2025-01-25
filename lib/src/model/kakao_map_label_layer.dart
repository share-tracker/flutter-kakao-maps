part of '../../flutter_kakao_maps.dart';

class KakaoMapLabelLayer {
  final String layerId;
  final KakaoMapPoint? point;
  final MethodChannel viewMethodChannel;
  final KakaoMapCompetitionType competitionType;
  final KakaoMapCompetitionUnit competitionUnit;
  final KakaoMapOrderType orderType;
  final int zOrder;

  const KakaoMapLabelLayer({
    required this.layerId,
    this.point,
    this.zOrder = 0,
    this.orderType = KakaoMapOrderType.rank,
    this.competitionUnit = KakaoMapCompetitionUnit.poi,
    this.competitionType = KakaoMapCompetitionType.none,
    required this.viewMethodChannel,
  });

  Future<KakaoMapRouteLine> addRouteLine(
    List<KakaoMapRouteLineStyle> styles,
    List<KakaoMapPoint> points,
  ) async {
    final id = await viewMethodChannel.invokeMethod('addRouteLine', {
      'lineStyles': styles.map((e) => e.toMap()).toList(),
      'points': points.map((e) => e.toMap()).toList(),
    });

    return KakaoMapRouteLine(layerId, id, viewMethodChannel);
  }

  Future removeAllRouteLine() async {
    await viewMethodChannel.invokeMethod('removeAllRouteLine', {});
  }

  Future<KakaoMapPoi> addLodLabel({
    required String styleId,
    required KakaoMapPoint position,
  }) async {
    final label = await viewMethodChannel.invokeMethod(
      "addLodLabel",
      {"layerID": layerId, "styleID": styleId, 'position': position.toMap()},
    );

    return KakaoMapPoi(layerId, label as String, viewMethodChannel);
  }

  Future removeLodLabel(String? labelId) async {
    if (labelId != null && labelId.isNotEmpty) {
      await viewMethodChannel.invokeMethod(
        'removeLodLabel',
        {"layerID": layerId, 'labelId': labelId},
      );
    }
  }

  Future<List<KakaoMapPoi>> addLodLabels({
    required String styleId,
    required List<KakaoMapPoint> positions,
  }) async {
    final list = positions.map((e) => e.toMap()).toList();

    final labels = await viewMethodChannel.invokeMethod(
      "addLodLabels",
      {"layerID": layerId, "styleID": styleId, 'positions': list},
    );

    return (labels as List)
        .map((e) => KakaoMapPoi(layerId, e as String, viewMethodChannel))
        .toList();
  }

  /// Poi 추가
  ///
  /// [styleID] style의 고유 ID
  /// [at] 생성 위치
  Future<KakaoMapPoi> addPoi({
    required String styleID,
    required KakaoMapPoint at,
  }) async {
    final poiID = await viewMethodChannel.invokeMethod(
      "addPoi",
      {
        "layerID": layerId,
        "styleID": styleID,
        "at": at.toMap(),
      },
    );

    return KakaoMapPoi(layerId, poiID, viewMethodChannel);
  }
}

extension KakaoMapLabelLayerExtension on KakaoMapLabelLayer {
  Map<String, dynamic> toMap() => {
        'layerId': layerId,
        'point': point?.toMap(),
        'zOrder': zOrder,
        'orderType': orderType.toInt(),
        'competitionUnit': competitionUnit.toInt(),
        'competitionType': competitionType.toInt()
      };
}
