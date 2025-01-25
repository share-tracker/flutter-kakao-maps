@preconcurrency import Flutter
import KakaoMapsSDK

@MainActor
class KakaoMapView: NSObject, @preconcurrency FlutterPlatformView, @preconcurrency MapControllerDelegate, KakaoMapEventDelegate {
    private let mapViewContainer: KMViewContainer
    private let mapController: KMController
    private var mapView: KakaoMap?

    private var options: KakaoMapOptions
    private let viewMethodChannel: FlutterMethodChannel

    private let viewId: Int64

    private var auth: Bool

    private func printLog(_ message: String) {
        FlutterKakaoMapsPlugin.logStreamHandler.sendMessage("KakaoMapView#\(viewId)[\(options.viewName)] \(message)")
    }

    private func viewMethodCallHandler(call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "dispose": dispose(result: result)
        case "addRouteLine": addRouteLine(arguments: call.arguments as! NSDictionary, result: result)
        case "moveRouteLine": moveRouteLine(arguments: call.arguments as! NSDictionary, result: result)
        case "modifyRouteLine": modifyRouteLine(arguments: call.arguments as! NSDictionary, result: result)
        case "removeAllRouteLine": removeAllRouteLine(arguments: call.arguments as! NSDictionary, result: result)
        case "addShapePolygon": addShapePolygon(arguments: call.arguments as! NSDictionary, result: result)
        case "removeAllShapePolygon": removeAllShapePolygon(arguments: call.arguments as! NSDictionary, result: result)
        case "addLodLabel": addLodLabel(arguments: call.arguments as! NSDictionary, result: result)
        case "removeLodLabel": removeLodLabel(arguments: call.arguments as! NSDictionary, result: result)
        case "addLodLabels": addLodLabels(arguments: call.arguments as! NSDictionary, result: result)
        case "addPoi": addPoi(arguments: call.arguments as! NSDictionary, result: result)
        case "movePoi": movePoi(arguments: call.arguments as! NSDictionary, result: result)
        case "removePoi": removePoi(arguments: call.arguments as! NSDictionary, result: result)
        case "addRouteLineStyle": addRouteLineStyle(arguments: call.arguments as! NSDictionary, result: result)
        case "addPoiIconStyle": addPoiIconStyle(arguments: call.arguments as! NSDictionary, result: result)
        case "changePoiIconStyle": changePoiIconStyle(arguments: call.arguments as! NSDictionary, result: result)
        case "addLabelLayer": addLabelLayer(arguments: call.arguments as! NSDictionary, result: result)
        case "addLodLabelLayer": addLodLabelLayer(arguments: call.arguments as! NSDictionary, result: result)
        case "moveCamera": moveCamera(arguments: call.arguments as! NSDictionary, result: result)
        case "animateCamera": animateCamera(arguments: call.arguments as! NSDictionary, result: result)
        case "moveCameraTransform": moveCameraTransform(arguments: call.arguments as! NSDictionary, result: result)
        case "animateCameraTransform": animateCameraTransform(arguments: call.arguments as! NSDictionary, result: result)
        case "getCameraPosition": getCameraPosition(result: result)
        case "setViewInfo": setViewInfo(arguments: call.arguments as! NSDictionary, result: result)
        case "showOverlay": showOverlay(arguments: call.arguments as! NSDictionary, result: result)
        case "hideOverlay": hideOverlay(arguments: call.arguments as! NSDictionary, result: result)
        case "setEnabled": setEnabled(arguments: call.arguments as! NSDictionary, result: result)
        case "setBuildingScale": setBuildingScale(arguments: call.arguments as! NSDictionary, result: result)
        case "getPadding": getPadding(result: result)
        case "setPadding": setPadding(arguments: call.arguments as! NSDictionary, result: result)
        case "setLogoPosition": setLogoPosition(arguments: call.arguments as! NSDictionary, result: result)
        case "setPoiOptions": setPoiOptions(arguments: call.arguments as! NSDictionary, result: result)
        case "setCompassOptions": setCompassOptions(arguments: call.arguments as! NSDictionary, result: result)
        case "setScaleBarOptions": setScaleBarOptions(arguments: call.arguments as! NSDictionary, result: result)
        case "refresh": refresh(result: result)
        default: result(FlutterMethodNotImplemented)
        }
    }

    func dispose(result: @escaping (Any?) -> Void) {
        printLog("stopEngine")

        mapController.pauseEngine()

        viewMethodChannel.setMethodCallHandler(nil)

        result(nil)
    }

    func addRouteLine(arguments: NSDictionary, result: @escaping (Any?) -> Void) {
        printLog("addRouteLine")

        guard let mapView = mapView else {
            result(FlutterError(code: "NOT_FOUND_MAPVIEW", message: "mapView is nil", details: nil))
            return
        }

        let layerID = arguments["layerId"] as? String ?? "routeLine"
        let styleID = arguments["styleId"] as? String ?? "routeStyle"
        let styleIndex = arguments["styleIndex"] as? Int ?? 0
        let zOrder = arguments["zOrder"] as? Int ?? 0

        let manager = mapView.getRouteManager()

        guard let layer = manager.addRouteLayer(layerID: layerID, zOrder: zOrder) else {
            result(FlutterError(code: "NOT_FOUND_ROUTE_LAYER", message: "routeLayer is nil", details: nil))
            return
        }

        let styleSet = RouteStyleSet(styleID: styleID)

        if let stylesArray = arguments["lineStyles"] as? [NSDictionary] {
            let routeLineStyles = stylesArray.map { $0.toRouteLineOptions() }

            styleSet.addStyle(RouteStyle(styles: routeLineStyles))
        }

        var route: Route?

        manager.addRouteStyleSet(styleSet)

        if let pointArray = arguments["points"] as? [NSDictionary] {
            let points = pointArray.map { $0.toMapPoint() }

            let routeSegment = RouteSegment(points: points, styleIndex: UInt(styleIndex))
            let routeOptions = RouteOptions(styleID: styleID, zOrder: 0)

            routeOptions.segments = [routeSegment]

            route = layer.addRoute(option: routeOptions)

            if route == nil {
                result(nil)

                return
            }
            route!.userObject = routeSegment
        }

        let fillEffect = ProgressAnimationEffect(direction: .forward, type: .fillFromStart)

        fillEffect.interpolation = AnimationInterpolation(duration: 1000, method: .linear)

        _ = manager.addRouteAnimator(animatorID: "routeAnimator", effect: fillEffect)

        guard let animator = manager.getRouteAnimator(animatorID: "routeAnimator") else {
            result(FlutterError(code: "NOT_ROUTE_ANIMATOR", message: "routeAnimator is nil", details: nil))
            return
        }

        guard let bgRoutes = manager.getRouteLayer(layerID: layer.layerID)?.getRoute(routeID: route?.routeID ?? "route") else {
            result(FlutterError(code: "NOT_ROUTE", message: "route is nil", details: nil))
            return
        }

        animator.addRoute(bgRoutes)
        animator.start()

        result(route?.routeID)
    }

    func moveRouteLine(arguments: NSDictionary, result: @escaping (Any?) -> Void) {
        printLog("moveRouteLine")

        guard let mapView = mapView else {
            result(FlutterError(code: "NOT_FOUND_MAPVIEW", message: "mapView is nil", details: nil))
            return
        }

        let layerID = arguments["layerId"] as? String ?? "routeLine"
        let lineId = arguments["lineId"] as? String ?? "routeId"
        let styleID = arguments["styleId"] as? String ?? "routeStyle"
        let point = (arguments["point"] as! NSDictionary).toMapPoint()

        let routeManager = mapView.getRouteManager()

        guard let routeLine = routeManager.getRouteLayer(layerID: layerID) else {
            result(FlutterError(code: "NOT_FOUND_ROUTE_LAYER", message: "route layer is nil", details: nil))
            return
        }

        guard let route = routeLine.getRoute(routeID: lineId) else {
            result(FlutterError(code: "NOT_FOUND_ROUTE", message: "route is nil", details: nil))
            return
        }

        guard let routeSegment = route.userObject as? RouteSegment else {
            result(FlutterError(code: "NOT_FOUND_ROUTE_SEGMENT", message: "route segment is nil", details: nil))
            return
        }

        var mapPoints: [MapPoint] = Array(routeSegment.points)

        mapPoints.append(point)

        let rs = RouteSegment(points: mapPoints, styleIndex: routeSegment.styleIndex)

        route.changeStyleAndData(styleID: styleID, segments: [rs])

        route.userObject = rs

        result(route.routeID)
    }

    func modifyRouteLine(arguments: NSDictionary, result: @escaping (Any?) -> Void) {
        printLog("modifyRouteLine")

        guard let mapView = mapView else {
            result(FlutterError(code: "NOT_FOUND_MAPVIEW", message: "mapView is nil", details: nil))
            return
        }

        let layerID = arguments["layerId"] as? String ?? "routeLine"
        let lineId = arguments["lineId"] as? String ?? "routeId"
        let styleID = arguments["styleId"] as? String ?? "routeStyle"
        let point = (arguments["point"] as! NSDictionary).toMapPoint()

        let routeManager = mapView.getRouteManager()

        guard let routeLine = routeManager.getRouteLayer(layerID: layerID) else {
            result(FlutterError(code: "NOT_FOUND_ROUTE_LAYER", message: "route layer is nil", details: nil))
            return
        }

        guard let route = routeLine.getRoute(routeID: lineId) else {
            result(FlutterError(code: "NOT_FOUND_ROUTE", message: "route is nil", details: nil))
            return
        }

        guard let routeSegment = route.userObject as? RouteSegment else {
            result(FlutterError(code: "NOT_FOUND_ROUTE_SEGMENT", message: "route segment is nil", details: nil))
            return
        }

        var mapPoints: [MapPoint] = Array(routeSegment.points.dropLast(1))

        mapPoints.append(point)

        let rs = RouteSegment(points: mapPoints, styleIndex: routeSegment.styleIndex)

        route.changeStyleAndData(styleID: styleID, segments: [rs])

        route.userObject = rs

        result(route.routeID)
    }

    func removeAllRouteLine(arguments: NSDictionary, result: @escaping (Any?) -> Void) {
        printLog("removeAllRouteLine")

        guard let mapView = mapView else {
            result(FlutterError(code: "NOT_FOUND_MAPVIEW", message: "mapView is nil", details: nil))
            return
        }
        let layerID = arguments["layerId"] as? String ?? "routeLine"

        let routeManager = mapView.getRouteManager()

        guard let routeLine = routeManager.getRouteLayer(layerID: layerID) else {
            result(FlutterError(code: "NOT_FOUND_ROUTE_LAYER", message: "route layer is nil", details: nil))
            return
        }

        routeLine.clearAllRoutes()

        result(nil)
    }

    func addShapePolygon(arguments: NSDictionary, result: @escaping (Any?) -> Void) {
        printLog("addShapePolygon")

        guard let mapView = mapView else {
            result(FlutterError(code: "NOT_FOUND_MAPVIEW", message: "mapView is nil", details: nil))
            return
        }

        let shapeManager = mapView.getShapeManager()

        let layerID = arguments["layerID"] as? String ?? "shapeLayer"
        let point = (arguments["position"] as! NSDictionary).toMapPoint()
        let circleRadius = arguments["circleRadius"] as! Double
        let circleColor = arguments["circleColor"] as! Int
        let polygonRadius = arguments["polygonRadius"] as! Double
        let holeColor = arguments["holeColor"] as! Int

        guard let shapeLayer = shapeManager.addShapeLayer(layerID: layerID, zOrder: 13795, passType: .overlay) else {
            result(FlutterError(code: "NOT_FOUND_SHAPE_LAYER", message: "shape layer is nil", details: nil))
            return
        }

        let circlePerStyle = PerLevelPolygonStyle(color: UIColor(hex: circleColor), level: 0)
        let holePerStyle = PerLevelPolygonStyle(color: UIColor(hex: holeColor), level: 0)

        let circleStyle = PolygonStyle(styles: [circlePerStyle])
        let holeStyle = PolygonStyle(styles: [holePerStyle])
        let styleSet = PolygonStyleSet(styleSetID: "ShapeStyle", styles: [circleStyle, holeStyle])

        shapeManager.addPolygonStyleSet(styleSet)

        let options = PolygonShapeOptions(styleID: "ShapeStyle", zOrder: 0x10)

        let circle = Primitives.getCirclePoints(radius: circleRadius, numPoints: 120, cw: true)
        let hole = Primitives.getCirclePoints(radius: polygonRadius, numPoints: 360, cw: true)

        let circlePolygon = Polygon(exteriorRing: circle, hole: nil, styleIndex: 0)
        let holePolygon = Polygon(exteriorRing: hole, hole: circle, styleIndex: 1)

        options.basePosition = point

        options.polygons.append(circlePolygon)
        options.polygons.append(holePolygon)

        let polygonShape = shapeLayer.addPolygonShape(options)

        polygonShape?.show()

        result(polygonShape?.layerID)
    }

    func removeAllShapePolygon(arguments: NSDictionary, result: @escaping (Any?) -> Void) {
        printLog("removeAllShapePolygon")

        guard let mapView = mapView else {
            result(FlutterError(code: "NOT_FOUND_MAPVIEW", message: "mapView is nil", details: nil))
            return
        }
        let layerID = arguments["layerID"] as? String ?? "shapeLayer"

        let shapeManager = mapView.getShapeManager()

        guard let shapeLayer = shapeManager.addShapeLayer(layerID: layerID, zOrder: 13795, passType: .overlay) else {
            result(FlutterError(code: "NOT_FOUND_SHAPE_LAYER", message: "shape layer is nil", details: nil))
            return
        }
        shapeLayer.clearAllShapes()

        result(nil)
    }

    func addLodLabel(arguments: NSDictionary, result: @escaping (Any?) -> Void) {
        printLog("addLodLabel")

        guard let mapView = mapView else {
            result(FlutterError(code: "NOT_FOUND_MAPVIEW", message: "mapView is nil", details: nil))
            return
        }

        let labelManager = mapView.getLabelManager()

        let position = arguments["position"] as! NSDictionary
        let layerID = arguments["layerID"] as? String ?? "warningLayer"
        let styleID = arguments["styleID"] as! String
        let poiID = position["labelId"] as! String

        guard let lodLabelLayer = labelManager.getLodLabelLayer(layerID: layerID) else {
            result(FlutterError(code: "NOT_FOUND_LOD_LABEL_LAYER", message: "lod label layer is nil", details: nil))
            return
        }
        let option = PoiOptions(styleID: styleID, poiID: poiID)

        option.clickable = true

        guard let poi = lodLabelLayer.addLodPoi(option: option, at: position.toMapPoint()) else {
            result(FlutterError(code: "FAILED_ADD", message: "failed add poi", details: nil))
            return
        }
        poi.show()

        result(poi.itemID)
    }

    func removeLodLabel(arguments: NSDictionary, result: @escaping (Any?) -> Void) {
        printLog("removeLodLabel")

        guard let mapView = mapView else {
            result(FlutterError(code: "NOT_FOUND_MAPVIEW", message: "mapView is nil", details: nil))
            return
        }
        let layerID = arguments["layerID"] as? String ?? "warningLayer"
        let poiID = arguments["labelId"] as! String

        let labelManager = mapView.getLabelManager()

        guard let lodLabelLayer = labelManager.getLodLabelLayer(layerID: layerID) else {
            result(FlutterError(code: "NOT_FOUND_LOD_LABEL_LAYER", message: "lod label layer is nil", details: nil))
            return
        }

        lodLabelLayer.removeLodPoi(poiID: poiID)

        result(poiID)
    }

    func addLodLabels(arguments: NSDictionary, result: @escaping (Any?) -> Void) {
        printLog("addLodLabels")

        guard let mapView = mapView else {
            result(FlutterError(code: "NOT_FOUND_MAPVIEW", message: "mapView is nil", details: nil))
            return
        }

        let labelManager = mapView.getLabelManager()

        let layerID = arguments["layerID"] as? String ?? "warningLayer"
        let styleID = arguments["styleID"] as! String
        let positions = arguments["positions"] as! [NSDictionary]

        guard let lodLabelLayer = labelManager.getLodLabelLayer(layerID: layerID) else {
            result(FlutterError(code: "NOT_FOUND_LOD_LABEL_LAYER", message: "lod label layer is nil", details: nil))
            return
        }

        var options: [PoiOptions] = []
        var points: [MapPoint] = []

        for position in positions {
            let poiID = position["labelId"] as! String
            let option = PoiOptions(styleID: styleID, poiID: poiID)

            option.clickable = true

            options.append(option)
            points.append(position.toMapPoint())
        }
        let pois = lodLabelLayer.addLodPois(options: options, at: points)

        lodLabelLayer.showAllLodPois()

        result(pois?.map { $0.itemID })
    }

    func addPoi(arguments: NSDictionary, result: @escaping (Any?) -> Void) {
        printLog("addPoi")

        let layerID = arguments["layerID"] as! String
        let styleID = arguments["styleID"] as! String

        guard let mapView = mapView else {
            result(FlutterError(code: "NOT_FOUND_MAPVIEW", message: "mapView is nil", details: nil))
            return
        }

        let labelManager = mapView.getLabelManager()

        guard let labelLayer = labelManager.getLabelLayer(layerID: layerID) else {
            result(FlutterError(code: "NOT_FOUND_LABEL_LAYER", message: "labelLayer is nil", details: nil))
            return
        }

        guard let poi = labelLayer.addPoi(option: PoiOptions(styleID: styleID), at: (arguments["at"] as! NSDictionary).toMapPoint()) else {
            result(FlutterError(code: "FAILED_ADD", message: "failed add poi", details: nil))
            return
        }

        poi.show()

        result(poi.itemID)
    }

    func movePoi(arguments: NSDictionary, result: @escaping (Any?) -> Void) {
        printLog("movePoi")

        guard let mapView = mapView else {
            result(FlutterError(code: "NOT_FOUND_MAPVIEW", message: "mapView is nil", details: nil))
            return
        }
        let poiID = arguments["poiID"] as! String
        let layerID = arguments["layerID"] as! String
        let point = (arguments["at"] as! NSDictionary).toMapPoint()
        let duration = arguments["milliseconds"] as! Int

        let labelManager = mapView.getLabelManager()

        guard let labelLayer = labelManager.getLabelLayer(layerID: layerID) else {
            result(FlutterError(code: "NOT_FOUND_LABEL_LAYER", message: "labelLayer is nil", details: nil))
            return
        }

        guard let poi = labelLayer.getPoi(poiID: poiID) else {
            result(FlutterError(code: "NOT_FOUND_POI", message: "poi is nil", details: nil))
            return
        }

        poi.moveAt(point, duration: UInt(duration))

        result(poi.itemID)
    }

    func removePoi(arguments: NSDictionary, result: @escaping (Any?) -> Void) {
        printLog("removePoi")

        let layerID = arguments["layerID"] as! String
        let poiID = arguments["poiID"] as! String

        guard let mapView = mapView else {
            result(FlutterError(code: "NOT_FOUND_MAPVIEW", message: "mapView is nil", details: nil))
            return
        }

        let labelManager = mapView.getLabelManager()

        guard let labelLayer = labelManager.getLabelLayer(layerID: layerID) else {
            result(FlutterError(code: "NOT_FOUND_LABEL_LAYER", message: "labelLayer is nil", details: nil))
            return
        }

        labelLayer.removePoi(poiID: poiID)

        result(nil)
    }

    func addRouteLineStyle(arguments _: NSDictionary, result: @escaping (Any?) -> Void) {
        printLog("addRouteLineStyle")

        result(nil)
    }

    func addPoiIconStyle(arguments: NSDictionary, result: @escaping (Any?) -> Void) {
        printLog("addPoiIconStyle")

        let styleID = arguments["styleID"] as! String
        let styles = (arguments["styles"] as! [NSDictionary])

        guard let mapView = mapView else {
            result(FlutterError(code: "NOT_FOUND_MAPVIEW", message: "mapView is nil", details: nil))
            return
        }

        let labelManager = mapView.getLabelManager()

        let poiStyles = styles.map { style in
            let badges = (style["badges"] as! [NSDictionary]).map { badge in
                let badgeID = style["badgeID"] as! String

                let imageNamed = badge["image"] as! String
                let imagePath = FlutterKakaoMapsPlugin.getAssetPath(named: imageNamed)

                let height = badge["height"] as! Double
                let width = badge["width"] as! Double
                let size = CGSize(width: width * 1.5, height: height * 1.5)

                let image = UIImage(contentsOfFile: imagePath)?.resized(to: size)

                let offset = (badge["offset"] as! NSDictionary).toCGPoint()
                let zOrder = badge["zOrder"] as! Int

                return PoiBadge(badgeID: badgeID, image: image, offset: offset, zOrder: zOrder)
            }

            let symbolNamed = style["symbol"] as! String
            let symbolPath = FlutterKakaoMapsPlugin.getAssetPath(named: symbolNamed)

            let height = style["height"] as! Double
            let width = style["width"] as! Double
            let size = CGSize(width: width * 1.5, height: height * 1.5)

            let symbol = UIImage(contentsOfFile: symbolPath)?.resized(to: size)

            let anchorPoint = (style["anchorPoint"] as! NSDictionary).toCGPoint()
            let level = style["level"] as! Int

            let transitionType = TransitionType(rawValue: style["transitionType"] as! Int)!

            let transition = PoiTransition(entrance: transitionType, exit: transitionType)

            return PerLevelPoiStyle(iconStyle: PoiIconStyle(symbol: symbol, anchorPoint: anchorPoint, transition: transition, badges: badges), level: level)
        }

        let poiStyle = PoiStyle(styleID: styleID, styles: poiStyles)

        labelManager.addPoiStyle(poiStyle)

        result(nil)
    }

    func changePoiIconStyle(arguments: NSDictionary, result: @escaping (Any?) -> Void) {
        printLog("changePoiIconStyle")

        let layerID = arguments["layerID"] as! String
        let poiID = arguments["poiID"] as! String
        let styleID = arguments["styleID"] as! String

        guard let mapView = mapView else {
            result(FlutterError(code: "NOT_FOUND_MAPVIEW", message: "mapView is nil", details: nil))
            return
        }

        let labelManager = mapView.getLabelManager()

        guard let labelLayer = labelManager.getLabelLayer(layerID: layerID) else {
            result(FlutterError(code: "NOT_FOUND_LABEL_LAYER", message: "labelLayer is nil", details: nil))
            return
        }

        guard let poi = labelLayer.getPoi(poiID: poiID) else {
            result(FlutterError(code: "NOT_FOUND_POI", message: "poi is nil", details: nil))
            return
        }

        poi.changeStyle(styleID: styleID)

        result(nil)
    }

    func addLabelLayer(arguments: NSDictionary, result: @escaping (Any?) -> Void) {
        printLog("addLabelLayer")

        guard let mapView = mapView else {
            result(FlutterError(code: "NOT_FOUND_MAPVIEW", message: "mapView is nil", details: nil))
            return
        }

        let labelManager = mapView.getLabelManager()

        guard let labelLayer = labelManager.addLabelLayer(option: arguments.toLabelLayerOptions()) else {
            result(FlutterError(code: "FAILED_ADD", message: "failed add labelLayer", details: nil))
            return
        }

        result(nil)
    }

    func addLodLabelLayer(arguments: NSDictionary, result: @escaping (Any?) -> Void) {
        printLog("addLodLabelLayer")

        guard let mapView = mapView else {
            result(FlutterError(code: "NOT_FOUND_MAPVIEW", message: "mapView is nil", details: nil))
            return
        }

        let labelManager = mapView.getLabelManager()

        guard let labelLayer = labelManager.addLodLabelLayer(option: arguments.toLodLabelLayerOptions()) else {
            result(FlutterError(code: "FAILED_ADD", message: "failed add lodLabelLayer", details: nil))
            return
        }

        result(nil)
    }

    func moveCamera(arguments: NSDictionary, result: @escaping (Any?) -> Void) {
        printLog("moveCamera")

        guard let mapView = mapView else {
            result(FlutterError(code: "NOT_FOUND_MAPVIEW", message: "mapView is nil", details: nil))
            return
        }

        let cameraPosition = CameraUpdate.make(mapView: mapView).cameraPosition!
        var cameraTarget = cameraPosition.targetPoint
        var cameraZoomLevel = mapView.zoomLevel
        var cameraRotation = cameraPosition.rotation
        var cameraTilt = cameraPosition.tilt

        let target = arguments["target"] as? NSDictionary
        if let target = target {
            cameraTarget = target.toMapPoint()
        }

        let zoomLevel = arguments["zoomLevel"] as? Int
        if let zoomLevel = zoomLevel {
            cameraZoomLevel = zoomLevel
        }

        let rotation = arguments["rotation"] as? Double
        if let rotation = rotation {
            cameraRotation = rotation
        }

        let tilt = arguments["tilt"] as? Double
        if let tilt = tilt {
            cameraTilt = tilt
        }

        let cameraUpdate = CameraUpdate.make(target: cameraTarget, zoomLevel: cameraZoomLevel, rotation: cameraRotation, tilt: cameraTilt, mapView: mapView)

        mapView.moveCamera(cameraUpdate)

        result(nil)
    }

    func animateCamera(arguments: NSDictionary, result: @escaping (Any?) -> Void) {
        printLog("animateCamera")

        guard let mapView = mapView else {
            result(FlutterError(code: "NOT_FOUND_MAPVIEW", message: "mapView is nil", details: nil))
            return
        }

        let cameraPosition = CameraUpdate.make(mapView: mapView).cameraPosition!
        var cameraTarget = cameraPosition.targetPoint
        var cameraZoomLevel = mapView.zoomLevel
        var cameraRotation = cameraPosition.rotation
        var cameraTilt = cameraPosition.tilt

        let target = arguments["target"] as? NSDictionary
        if let target = target {
            cameraTarget = target.toMapPoint()
        }

        let zoomLevel = arguments["zoomLevel"] as? Int
        if let zoomLevel = zoomLevel {
            cameraZoomLevel = zoomLevel
        }

        let rotation = arguments["rotation"] as? Double
        if let rotation = rotation {
            cameraRotation = rotation
        }

        let tilt = arguments["tilt"] as? Double
        if let tilt = tilt {
            cameraTilt = tilt
        }

        let cameraAnimationOptions = (arguments["cameraAnimationOptions"] as! NSDictionary).toCameraAnimationOptions()

        let cameraUpdate = CameraUpdate.make(target: cameraTarget, zoomLevel: cameraZoomLevel, rotation: cameraRotation, tilt: cameraTilt, mapView: mapView)

        mapView.animateCamera(cameraUpdate: cameraUpdate, options: cameraAnimationOptions)

        result(nil)
    }

    func moveCameraTransform(arguments: NSDictionary, result: @escaping (Any?) -> Void) {
        printLog("moveCameraTransform")

        guard let mapView = mapView else {
            result(FlutterError(code: "NOT_FOUND_MAPVIEW", message: "mapView is nil", details: nil))
            return
        }

        let point = (arguments["point"] as! NSDictionary).toCameraTransformDelta()
        let height = arguments["height"] as! Double
        let rotation = arguments["rotation"] as! Double
        let tilt = arguments["tilt"] as! Double

        let cameraUpdate = CameraUpdate.make(transform: CameraTransform(deltaPos: point, deltaHeight: height, deltaRotation: rotation, deltaTilt: tilt))

        mapView.moveCamera(cameraUpdate)

        result(nil)
    }

    func animateCameraTransform(arguments: NSDictionary, result: @escaping (Any?) -> Void) {
        printLog("animateCameraTransform")

        guard let mapView = mapView else {
            result(FlutterError(code: "NOT_FOUND_MAPVIEW", message: "mapView is nil", details: nil))
            return
        }

        let point = (arguments["point"] as! NSDictionary).toCameraTransformDelta()
        let height = arguments["height"] as! Double
        let rotation = arguments["rotation"] as! Double
        let tilt = arguments["tilt"] as! Double
        let cameraAnimationOptions = (arguments["cameraAnimationOptions"] as! NSDictionary).toCameraAnimationOptions()

        let cameraUpdate = CameraUpdate.make(transform: CameraTransform(deltaPos: point, deltaHeight: height, deltaRotation: rotation, deltaTilt: tilt))

        mapView.animateCamera(cameraUpdate: cameraUpdate, options: cameraAnimationOptions)

        result(nil)
    }

    func getCameraPosition(result: @escaping (Any?) -> Void) {
        printLog("getCameraPosition")

        result(nil)
    }

    func setViewInfo(arguments: NSDictionary, result: @escaping (Any?) -> Void) {
        printLog("setViewInfo")

        guard let mapView = mapView else {
            result(FlutterError(code: "NOT_FOUND_MAPVIEW", message: "mapView is nil", details: nil))
            return
        }

        let appName = arguments["appName"] as! String
        let viewInfoName = arguments["viewInfoName"] as! String

        mapView.changeViewInfo(appName: appName, viewInfoName: viewInfoName)

        result(nil)
    }

    func showOverlay(arguments: NSDictionary, result: @escaping (Any?) -> Void) {
        printLog("showOverlay")

        guard let mapView = mapView else {
            result(FlutterError(code: "NOT_FOUND_MAPVIEW", message: "mapView is nil", details: nil))
            return
        }

        let overlay = arguments["overlay"] as! String

        mapView.showOverlay(overlay)

        result(nil)
    }

    func hideOverlay(arguments: NSDictionary, result: @escaping (Any?) -> Void) {
        printLog("hideOverlay")

        guard let mapView = mapView else {
            result(FlutterError(code: "NOT_FOUND_MAPVIEW", message: "mapView is nil", details: nil))
            return
        }

        let overlay = arguments["overlay"] as! String

        mapView.hideOverlay(overlay)

        result(nil)
    }

    func setEnabled(arguments: NSDictionary, result: @escaping (Any?) -> Void) {
        printLog("setEnabled")

        guard let mapView = mapView else {
            result(FlutterError(code: "NOT_FOUND_MAPVIEW", message: "mapView is nil", details: nil))
            return
        }

        let enabled = arguments["enabled"] as! Bool

        mapView.isEnabled = enabled

        result(nil)
    }

    func setBuildingScale(arguments: NSDictionary, result: @escaping (Any?) -> Void) {
        printLog("setBuildingScale")

        guard let mapView = mapView else {
            result(FlutterError(code: "NOT_FOUND_MAPVIEW", message: "mapView is nil", details: nil))
            return
        }

        let buildingScale = Float(arguments["buildingScale"] as! Double)

        mapView.buildingScale = buildingScale

        result(nil)
    }

    func getPadding(result: @escaping (Any?) -> Void) {
        printLog("getPadding")

        guard let mapView = mapView else {
            result(FlutterError(code: "NOT_FOUND_MAPVIEW", message: "mapView is nil", details: nil))
            return
        }

        let margins = mapView.margins

        result(["left": margins.left, "top": margins.top, "right": margins.right, "bottom": margins.bottom])
    }

    func setPadding(arguments: NSDictionary, result: @escaping (Any?) -> Void) {
        printLog("setPadding")

        guard let mapView = mapView else {
            result(FlutterError(code: "NOT_FOUND_MAPVIEW", message: "mapView is nil", details: nil))
            return
        }

        let padding = arguments.toUIEdgeInsets()

        mapView.setMargins(padding)

        result(nil)
    }

    func setLogoPosition(arguments: NSDictionary, result: @escaping (Any?) -> Void) {
        printLog("setLogoPosition")

        guard let mapView = mapView else {
            result(FlutterError(code: "NOT_FOUND_MAPVIEW", message: "mapView is nil", details: nil))
            return
        }

        let logoPosition = arguments.toKakaoMapPosition()

        mapView.setLogoPosition(origin: logoPosition.alignment.toGuiAlignment(), position: CGPoint(x: logoPosition.x, y: logoPosition.y))

        result(nil)
    }

    func setPoiOptions(arguments: NSDictionary, result: @escaping (Any?) -> Void) {
        printLog("setPoiOptions")

        guard let mapView = mapView else {
            result(FlutterError(code: "NOT_FOUND_MAPVIEW", message: "mapView is nil", details: nil))
            return
        }

        let poiOptions = arguments.toKakaoMapPoiOptions()

        mapView.poiClickable = poiOptions.clickable
        mapView.setPoiEnabled(poiOptions.enabled)
        mapView.poiScale = poiOptions.scale

        result(nil)
    }

    func setCompassOptions(arguments: NSDictionary, result: @escaping (Any?) -> Void) {
        printLog("setCompassOptions")

        guard let mapView = mapView else {
            result(FlutterError(code: "NOT_FOUND_MAPVIEW", message: "mapView is nil", details: nil))
            return
        }

        let compassOptions = arguments.toCompassOptions()

        if compassOptions.enabled {
            mapView.showCompass()
        } else {
            mapView.hideCompass()
        }
        mapView.setCompassPosition(origin: compassOptions.position.alignment.toGuiAlignment(), position: CGPoint(x: compassOptions.position.x, y: compassOptions.position.y))

        result(nil)
    }

    func setScaleBarOptions(arguments: NSDictionary, result: @escaping (Any?) -> Void) {
        printLog("setScaleBarOptions")

        guard let mapView = mapView else {
            result(FlutterError(code: "NOT_FOUND_MAPVIEW", message: "mapView is nil", details: nil))
            return
        }

        let scaleBarOptions = arguments.toScaleBarOptions()

        if scaleBarOptions.enabled {
            mapView.showScaleBar()
        } else {
            mapView.hideScaleBar()
        }
        mapView.setScaleBarPosition(origin: scaleBarOptions.position.alignment.toGuiAlignment(), position: CGPoint(x: scaleBarOptions.position.x, y: scaleBarOptions.position.y))
        mapView.setScaleBarAutoDisappear(scaleBarOptions.autoDisabled)
        mapView.setScaleBarFadeInOutOption(scaleBarOptions.fadeInOutOptions)

        result(nil)
    }

    func refresh(result: @escaping (Any?) -> Void) {
        printLog("refresh")

        guard let mapView = mapView else {
            result(FlutterError(code: "NOT_FOUND_MAPVIEW", message: "mapView is nil", details: nil))
            return
        }

        mapView.refresh()

        result(nil)
    }

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        options: KakaoMapOptions,
        viewMethodChannel: FlutterMethodChannel
    ) {
        auth = false
        self.viewId = viewId
        self.options = options
        self.viewMethodChannel = viewMethodChannel

        mapViewContainer = KMViewContainer(frame: frame)
        mapController = KMController(viewContainer: mapViewContainer)

        if mapViewContainer.proMotionDisplay == true {
            mapController.proMotionSupport = true
        }

        super.init()

        viewMethodChannel.setMethodCallHandler(viewMethodCallHandler)

        mapController.delegate = self

        printLog("init")
    }

    nonisolated func authenticationSucceeded() {
        Task { @MainActor in
            printLog("auth success")

            if auth == false {
                auth = true
                self.mapController.activateEngine()
            }
        }
    }

    nonisolated func authenticationFailed(_ errorCode: Int, desc: String) {
        Task { @MainActor in
            printLog("auth error code: \(errorCode)")
            printLog("auth desc: \(desc)")

            auth = false

            switch errorCode {
            case 499:
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.printLog("auth retry")

                    self.mapController.prepareEngine()
                }
            default:
                break
            }
        }
    }

    func addViews() {
        let mapViewInfo = MapviewInfo(viewName: options.viewName, appName: options.appName, viewInfoName: options.viewInfoName, defaultPosition: options.defaultPosition, defaultLevel: options.defaultLevel, enabled: options.enabled)

        mapController.addView(mapViewInfo)
    }

    nonisolated func addViewSucceeded(_: String, viewInfoName _: String) {
        Task { @MainActor in
            mapView = mapController.getView(options.viewName) as? KakaoMap

            if let mapView = self.mapView {
                // Overlay
                if options.overlay != nil {
                    mapView.showOverlay(options.overlay!)
                }
                // Language
                mapView.setLanguage(options.language)
                // BuildingScale
                mapView.buildingScale = options.buildingScale
                // Padding
                mapView.setMargins(options.padding)
                // LogoPosition
                mapView.setLogoPosition(origin: options.logoPosition.alignment.toGuiAlignment(), position: CGPoint(x: options.logoPosition.x, y: options.logoPosition.y))
                // PoiOptions
                mapView.poiClickable = options.poiOptions.clickable
                mapView.setPoiEnabled(options.poiOptions.enabled)
                mapView.poiScale = options.poiOptions.scale
                // CompassOptions
                if options.compassOptions.enabled {
                    mapView.showCompass()
                } else {
                    mapView.hideCompass()
                }
                mapView.setCompassPosition(origin: options.compassOptions.position.alignment.toGuiAlignment(), position: CGPoint(x: options.compassOptions.position.x, y: options.compassOptions.position.y))
                // ScaleBarOptions
                if options.scaleBarOptions.enabled {
                    mapView.showScaleBar()
                } else {
                    mapView.hideScaleBar()
                }
                mapView.setScaleBarPosition(origin: options.scaleBarOptions.position.alignment.toGuiAlignment(), position: CGPoint(x: options.scaleBarOptions.position.x, y: options.scaleBarOptions.position.y))
                mapView.setScaleBarAutoDisappear(options.scaleBarOptions.autoDisabled)
                mapView.setScaleBarFadeInOutOption(options.scaleBarOptions.fadeInOutOptions)

                mapView.cameraMaxLevel = 20
                mapView.cameraMinLevel = 8

                mapView.eventDelegate = self

                viewMethodChannel.invokeMethod("onMapReady", arguments: nil)
            }
        }
    }

    func view() -> UIView {
        printLog("initEngine")
        mapController.prepareEngine()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if self.auth {
                self.printLog("startEngine")
                self.mapController.activateEngine()
            } else {
                self.printLog("authenticate")
                self.mapController.prepareEngine()
            }
        }

        return mapViewContainer
    }

    nonisolated func cameraDidStopped(kakaoMap: KakaoMap, by: MoveBy) {
        let cameraPosition = kakaoMap.getPosition(CGPoint(x: 0, y: 0))
        let cameraPositionData: [String: Any] = [
            "height": kakaoMap.cameraHeight,
            "rotationAngle": kakaoMap.rotationAngle,
            "tiltAngle": kakaoMap.tiltAngle,
            "zoomLevel": kakaoMap.zoomLevel,
            "position": [
                "latitude": cameraPosition.wgsCoord.latitude,
                "longitude": cameraPosition.wgsCoord.longitude,
            ],
            "gestureType": by.rawValue,
        ]

        DispatchQueue.main.async {
            self.viewMethodChannel.invokeMethod("cameraPosition", arguments: cameraPositionData)
        }
    }

    nonisolated func poiDidTapped(kakaoMap _: KakaoMap, layerID _: String, poiID: String, position: MapPoint) {
        let onTap: [String: Any] = [
            "labelId": poiID,
            "latitude": position.wgsCoord.latitude,
            "longitude": position.wgsCoord.longitude,
        ]
        viewMethodChannel.invokeMethod("onLodLabelClicked", arguments: onTap)
    }
}
