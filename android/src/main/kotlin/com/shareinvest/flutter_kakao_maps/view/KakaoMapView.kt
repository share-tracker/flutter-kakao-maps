package com.shareinvest.flutter_kakao_maps.view

import android.app.Activity
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.util.Log
import android.view.View
import com.kakao.vectormap.KakaoMap
import com.kakao.vectormap.KakaoMapReadyCallback
import com.kakao.vectormap.LatLng
import com.kakao.vectormap.MapLifeCycleCallback
import com.kakao.vectormap.MapOverlay
import com.kakao.vectormap.MapType
import com.kakao.vectormap.MapView
import com.kakao.vectormap.MapViewInfo
import com.kakao.vectormap.animation.Interpolation
import com.kakao.vectormap.camera.CameraPosition
import com.kakao.vectormap.camera.CameraUpdateFactory
import com.kakao.vectormap.label.BadgeOptions
import com.kakao.vectormap.label.LabelOptions
import com.kakao.vectormap.label.LabelStyle
import com.kakao.vectormap.label.LabelStyles
import com.kakao.vectormap.label.LabelTransition
import com.kakao.vectormap.label.Transition
import com.kakao.vectormap.route.RouteLineOptions
import com.kakao.vectormap.route.RouteLineSegment
import com.kakao.vectormap.route.RouteLineStyle
import com.kakao.vectormap.route.RouteLineStyles
import com.kakao.vectormap.route.RouteLineStylesSet
import com.kakao.vectormap.route.animation.ProgressAnimation
import com.kakao.vectormap.route.animation.ProgressDirection
import com.kakao.vectormap.route.animation.ProgressType
import com.kakao.vectormap.shape.DotPoints
import com.kakao.vectormap.shape.PolygonOptions
import com.kakao.vectormap.shape.PolygonStyles
import com.kakao.vectormap.shape.PolygonStylesSet
import com.shareinvest.flutter_kakao_maps.FlutterKakaoMapsPlugin
import com.shareinvest.flutter_kakao_maps.enum.toMapGravity
import com.shareinvest.flutter_kakao_maps.model.KakaoMapOptions
import com.shareinvest.flutter_kakao_maps.model.toCameraAnimation
import com.shareinvest.flutter_kakao_maps.model.toCompassOptions
import com.shareinvest.flutter_kakao_maps.model.toKakaoMapPosition
import com.shareinvest.flutter_kakao_maps.model.toLabelLayerOptions
import com.shareinvest.flutter_kakao_maps.model.toLatLng
import com.shareinvest.flutter_kakao_maps.model.toPadding
import com.shareinvest.flutter_kakao_maps.model.toPoiOptions
import com.shareinvest.flutter_kakao_maps.model.toPointF
import com.shareinvest.flutter_kakao_maps.model.toRouteLineOptions
import com.shareinvest.flutter_kakao_maps.model.toScaleBarOptions
import com.shareinvest.flutter_kakao_maps.util.dp
import com.shareinvest.flutter_kakao_maps.util.px
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView
import org.json.JSONObject

internal class KakaoMapView(
    private val activity: Activity,
    private val viewId: Int,
    private var options: KakaoMapOptions,
    private val viewMethodChannel: MethodChannel
) : PlatformView {
    private val mapViewContainer: MapView
    private var mapView: KakaoMap? = null

    private fun printLog(message: String) {
        FlutterKakaoMapsPlugin.logStreamHandler.sendMessage("KakaoMapView#${viewId}[${options.viewName}] $message")
    }

    private val viewMethodCallHandler = MethodChannel.MethodCallHandler { call, result ->
        when (call.method) {
            "dispose" -> dispose(result)

            "addRouteLine" -> addRouteLine(call.arguments as JSONObject, result)
            "moveRouteLine" -> moveRouteLine(call.arguments as JSONObject, result)
            "modifyRouteLine" -> modifyRouteLine(call.arguments as JSONObject, result)
            "removeAllRouteLine" -> removeAllRouteLine(result)

            "addShapePolygon" -> addShapePolygon(call.arguments as JSONObject, result)
            "removeAllShapePolygon" -> removeAllShapePolygon(result)

            "addLodLabel" -> addLodLabel(call.arguments as JSONObject, result)
            "removeLodLabel" -> removeLodLabel(call.arguments as JSONObject, result)
            "addLodLabels" -> addLodLabels(call.arguments as JSONObject, result)

            "addPoi" -> addPoi(call.arguments as JSONObject, result)
            "movePoi" -> movePoi(call.arguments as JSONObject, result)
            "removePoi" -> removePoi(call.arguments as JSONObject, result)

            "addRouteLineStyle" -> addRouteLineStyle(call.arguments as JSONObject, result)

            "addPoiIconStyle" -> addPoiIconStyle(call.arguments as JSONObject, result)
            "changePoiIconStyle" -> changePoiIconStyle(call.arguments as JSONObject, result)

            "addLabelLayer" -> addLabelLayer(call.arguments as JSONObject, result)
            "addLodLabelLayer" -> addLodLabelLayer(call.arguments as JSONObject, result)

            "moveCamera" -> moveCamera(call.arguments as JSONObject, result)
            "animateCamera" -> animateCamera(call.arguments as JSONObject, result)

            "moveCameraTransform" -> moveCameraTransform(call.arguments as JSONObject, result)
            "animateCameraTransform" -> animateCameraTransform(
                call.arguments as JSONObject, result
            )

            "getCameraPosition" -> getCameraPosition(result)

            "setViewInfo" -> setViewInfo(call.arguments as JSONObject, result)

            "showOverlay" -> showOverlay(call.arguments as JSONObject, result)
            "hideOverlay" -> hideOverlay(call.arguments as JSONObject, result)

            "setEnabled" -> setEnabled(call.arguments as JSONObject, result)

            "setBuildingScale" -> setBuildingScale(call.arguments as JSONObject, result)
            "getPadding" -> getPadding(result)
            "setPadding" -> setPadding(call.arguments as JSONObject, result)

            "setLogoPosition" -> setLogoPosition(call.arguments as JSONObject, result)

            "setPoiOptions" -> setPoiOptions(call.arguments as JSONObject, result)

            "setCompassOptions" -> setCompassOptions(call.arguments as JSONObject, result)

            "setScaleBarOptions" -> setScaleBarOptions(call.arguments as JSONObject, result)

            else -> result.notImplemented()
        }
    }

    private fun dispose(result: MethodChannel.Result) {
        printLog("stop")

        mapViewContainer.finish()

        viewMethodChannel.setMethodCallHandler(null)

        result.success(null)
    }

    private fun addRouteLine(arguments: JSONObject, result: MethodChannel.Result) {
        printLog("addRouteLine")

        val mapView = mapView ?: run {
            result.error("NOT_FOUND_MAPVIEW", "mapView is null", null)
            return
        }

        val routeLineManager = mapView.routeLineManager ?: run {
            result.error("NOT_FOUND_ROUTE_LINE_MANAGER", "routeLineManager is null", null)
            return
        }

        val routeLineStyles = arguments.getJSONArray("lineStyles").let { styles ->
            List(styles.length()) { index ->
                styles.getJSONObject(index).toRouteLineOptions()
            }
        }

        val stylesSet = routeLineManager.addStylesSet(
            RouteLineStylesSet.from(
                RouteLineStyles.from(routeLineStyles)
            )
        )

        val segment = RouteLineSegment.from(
            arguments.getJSONArray("points").let { points ->
                List(points.length()) { index ->
                    points.getJSONObject(index).toLatLng()
                }
            }).setStyles(stylesSet.getStyles(0))

        val layer = routeLineManager.layer.addRouteLine(
            RouteLineOptions.from(segment).setStylesSet(stylesSet)
        )

        if (layer == null || layer.lineId.isNullOrEmpty()) {
            result.success(null)

            return
        }

        val animation = ProgressAnimation.from(layer.lineId, 0x400).apply {
            interpolation = Interpolation.Linear
            progressType = ProgressType.ToShow
            progressDirection = ProgressDirection.StartFirst
            isHideAtStop = false
            isResetToInitialState = false
        }

        val animator = routeLineManager.addAnimator(animation)

        animator.addRouteLines(layer)
        animator.start { result.success(layer.lineId) }
    }

    private fun moveRouteLine(arguments: JSONObject, result: MethodChannel.Result) {
        printLog("moveRouteLine")

        val mapView = mapView ?: run {
            result.error("NOT_FOUND_MAPVIEW", "mapView is null", null)
            return
        }

        val routeLineManager = mapView.routeLineManager ?: run {
            result.error("NOT_FOUND_ROUTE_LINE_MANAGER", "routeLineManager is null", null)
            return
        }

        val routeLine = routeLineManager.layer.getRouteLine(arguments.getString("lineId"))

        routeLine.changeSegments(
            routeLine.segments.first().addPoints(arguments.getJSONObject("point").toLatLng())
        )

        result.success(routeLine.lineId)
    }

    private fun modifyRouteLine(arguments: JSONObject, result: MethodChannel.Result) {
        printLog("modifyRouteLine")

        val mapView = mapView ?: run {
            result.error("NOT_FOUND_MAPVIEW", "mapView is null", null)
            return
        }

        val routeLineManager = mapView.routeLineManager ?: run {
            result.error("NOT_FOUND_ROUTE_LINE_MANAGER", "routeLineManager is null", null)
            return
        }

        val routeLine = routeLineManager.layer.getRouteLine(arguments.getString("lineId"))

        val e = routeLine.segments.first()

        routeLine.changeSegments(
            e.setPoints(
                e.points.dropLast(1) + arguments.getJSONObject("point").toLatLng()
            )
        )

        result.success(routeLine.lineId)
    }

    private fun removeAllRouteLine(result: MethodChannel.Result) {
        printLog("removeAllRouteLine")

        val mapView = mapView ?: run {
            result.error("NOT_FOUND_MAPVIEW", "mapView is null", null)
            return
        }

        val routeLineManager = mapView.routeLineManager ?: run {
            result.error("NOT_FOUND_ROUTE_LINE_MANAGER", "routeLineManager is null", null)
            return
        }

        routeLineManager.layer.removeAll()

        result.success(null)
    }

    private fun addShapePolygon(arguments: JSONObject, result: MethodChannel.Result) {
        Log.d("addShapePolygon", "$arguments")

        val mapView = mapView ?: run {
            result.error("NOT_FOUND_MAPVIEW", "mapView is null", null)
            return
        }

        val shapeManager = mapView.shapeManager ?: run {
            result.error("NOT_FOUND_LABEL_MANAGER", "shapeManager is null", null)
            return
        }

        val shapeLayer = shapeManager.layer

        val circleOptions = PolygonOptions.from(
            DotPoints.fromCircle(
                arguments.getJSONObject("position").toLatLng(),
                arguments.getDouble("circleRadius").toFloat()
            )
        ).setStylesSet(PolygonStylesSet.from(PolygonStyles.from(arguments.getInt("circleColor"))))

        val polygonOptions = PolygonOptions.from(
            DotPoints.fromCircle(
                arguments.getJSONObject("position").toLatLng(),
                arguments.getDouble("polygonRadius").toFloat()
            ).setHoleCircle(arguments.getDouble("circleRadius").toFloat())
        ).setStylesSet(PolygonStylesSet.from(PolygonStyles.from(arguments.getInt("holeColor"))));

        val circle = shapeLayer.addPolygon(circleOptions)
        val polygon = shapeLayer.addPolygon(polygonOptions)

        result.success(JSONObject().apply {
            put("circleId", circle.id)
            put("polygonId", polygon.id)
        })
    }

    private fun removeAllShapePolygon(result: MethodChannel.Result) {
        printLog("removeAllShapePolygon")

        val mapView = mapView ?: run {
            result.error("NOT_FOUND_MAPVIEW", "mapView is null", null)
            return
        }

        val shapeManager = mapView.shapeManager ?: run {
            result.error("NOT_FOUND_LABEL_MANAGER", "shapeManager is null", null)
            return
        }

        val shapeLayer = shapeManager.layer

        shapeLayer.removeAll()

        result.success(null)
    }

    private fun addLodLabel(arguments: JSONObject, result: MethodChannel.Result) {
        Log.d("addLodLabel", "$arguments")

        val mapView = mapView ?: run {
            result.error("NOT_FOUND_MAPVIEW", "mapView is null", null)
            return
        }

        val labelManager = mapView.labelManager ?: run {
            result.error("NOT_FOUND_LABEL_MANAGER", "labelManager is null", null)
            return
        }

        val lodLabelLayer = labelManager.lodLayer

        val labelStyles = labelManager.getLabelStyles(arguments.getString("styleID")) ?: run {
            result.error("NOT_FOUND_LABEL_STYLES", "labelStyles is null", null)
            return
        }
        Log.d("lodLabelLayer", "$lodLabelLayer")

        val labelOptions = arguments.getJSONObject("position").let { position ->
            LabelOptions.from(
                position.getString("labelId"),
                position.toLatLng()
            ).apply {
                styles = labelStyles
                clickable = true
            }
        }
        Log.d("labelOptions", "$labelOptions")

        val label = lodLabelLayer?.addLodLabel(labelOptions) ?: run {
            result.error("FAILED_ADD", "failed add poi", null)
            return
        }

        result.success(label.labelId)
    }

    private fun removeLodLabel(arguments: JSONObject, result: MethodChannel.Result) {
        Log.d("removeLodLabel", "$arguments")

        val mapView = mapView ?: run {
            result.error("NOT_FOUND_MAPVIEW", "mapView is null", null)
            return
        }

        val labelManager = mapView.labelManager ?: run {
            result.error("NOT_FOUND_LABEL_MANAGER", "labelManager is null", null)
            return
        }

        val lodLabelLayer = labelManager.lodLayer

        val label = lodLabelLayer?.getLabel(arguments.getString("labelId"))

        lodLabelLayer?.remove(label)

        result.success(label?.labelId)
    }

    private fun addLodLabels(arguments: JSONObject, result: MethodChannel.Result) {
        Log.d("addLodLabels", "$arguments")

        val mapView = mapView ?: run {
            result.error("NOT_FOUND_MAPVIEW", "mapView is null", null)
            return
        }

        val labelManager = mapView.labelManager ?: run {
            result.error("NOT_FOUND_LABEL_MANAGER", "labelManager is null", null)
            return
        }

        val lodLabelLayer = labelManager.lodLayer

        val labelStyles = labelManager.getLabelStyles(arguments.getString("styleID")) ?: run {
            result.error("NOT_FOUND_LABEL_STYLES", "labelStyles is null", null)
            return
        }
        Log.d("lodLabelLayer", "$lodLabelLayer")

        val labelOptions = arguments.getJSONArray("positions").let { positions ->
            List(positions.length()) { index ->
                LabelOptions.from(
                    positions.getJSONObject(index).getString("labelId"),
                    positions.getJSONObject(index).toLatLng()
                ).apply {
                    styles = labelStyles
                    clickable = true
                }
            }
        }
        Log.d("labelOptions", "$labelOptions")

        val labels = lodLabelLayer?.addLodLabels(labelOptions) ?: run {
            result.error("FAILED_ADD", "failed add poi", null)
            return
        }

        result.success(labels.map { it.labelId })
    }

    private fun addPoi(arguments: JSONObject, result: MethodChannel.Result) {
        printLog("addPoi")

        val mapView = mapView ?: run {
            result.error("NOT_FOUND_MAPVIEW", "mapView is null", null)
            return
        }

        val labelManager = mapView.labelManager ?: run {
            result.error("NOT_FOUND_LABEL_MANAGER", "labelManager is null", null)
            return
        }

        val labelLayer = labelManager.getLayer(arguments.getString("layerID"))

        val labelStyles = labelManager.getLabelStyles(arguments.getString("styleID")) ?: run {
            result.error("NOT_FOUND_LABEL_STYLES", "labelStyles is null", null)
            return
        }

        val labelOptions = LabelOptions.from(arguments.getJSONObject("at").toLatLng()).apply {
            styles = labelStyles
        }

        val poi = labelLayer.addLabel(labelOptions) ?: run {
            result.error("FAILED_ADD", "failed add poi", null)
            return
        }

        result.success(poi.labelId)
    }

    private fun movePoi(arguments: JSONObject, result: MethodChannel.Result) {
        printLog("movePoi")

        val mapView = mapView ?: run {
            result.error("NOT_FOUND_MAPVIEW", "mapView is null", null)
            return
        }

        val labelManager = mapView.labelManager ?: run {
            result.error("NOT_FOUND_LABEL_MANAGER", "labelManager is null", null)
            return
        }

        val labelLayer = labelManager.getLayer(arguments.getString("layerID"))

        val poi = labelLayer.getLabel(arguments.getString("poiID"))

        poi.moveTo(arguments.getJSONObject("at").toLatLng(), arguments.getInt("milliseconds"))

        result.success(poi.labelId)
    }

    private fun removePoi(arguments: JSONObject, result: MethodChannel.Result) {
        printLog("removePoi")

        val mapView = mapView ?: run {
            result.error("NOT_FOUND_MAPVIEW", "mapView is null", null)
            return
        }

        val labelManager = mapView.labelManager ?: run {
            result.error("NOT_FOUND_LABEL_MANAGER", "labelManager is null", null)
            return
        }

        val labelLayer = labelManager.getLayer(arguments.getString("layerID"))

        labelLayer.remove(labelLayer.getLabel(arguments.getString("poiID")))

        result.success(null)
    }

    private fun addRouteLineStyle(arguments: JSONObject, result: MethodChannel.Result) {
        printLog("addRouteLineStyle")

        val mapView = mapView ?: run {
            result.error("NOT_FOUND_MAPVIEW", "mapView is null", null)
            return
        }

        val routeLineManager = mapView.routeLineManager ?: run {
            result.error("NOT_FOUND_ROUTE_LINE_MANAGER", "routeLineManager is null", null)
            return
        }

        val routeLineStyles = arguments.getJSONArray("lineStyles").let { styles ->
            List(styles.length()) { index ->
                styles.getJSONObject(index).toRouteLineOptions()
            }
        }

        val stylesSet = routeLineManager.addStylesSet(
            RouteLineStylesSet.from(
                arguments.getString("styleId"),
                RouteLineStyles.from(routeLineStyles)
            )
        )

        result.success(stylesSet.styleId)
    }

    private fun addPoiIconStyle(arguments: JSONObject, result: MethodChannel.Result) {
        printLog("addPoiIconStyle")

        val mapView = mapView ?: run {
            result.error("NOT_FOUND_MAPVIEW", "mapView is null", null)
            return
        }

        val labelManager = mapView.labelManager ?: run {
            result.error("NOT_FOUND_LABEL_MANAGER", "labelManager is null", null)
            return
        }

        val labelStyles = mutableListOf<LabelStyle>()

        val styleID = arguments.getString("styleID")
        val styles = arguments.getJSONArray("styles")

        for (styleIndex in 0 until styles.length()) {
            val style = styles.getJSONObject(styleIndex)

            val badgesJsonArray = style.getJSONArray("badges")

            val badges: MutableList<BadgeOptions> = mutableListOf()
            for (badgeIndex in 0 until badgesJsonArray.length()) {
                val badgeJsonObject = badgesJsonArray.getJSONObject(badgeIndex)

                val inputStream =
                    FlutterKakaoMapsPlugin.getAsset(badgeJsonObject.getString("image"))
                val bitmap = Bitmap.createScaledBitmap(
                    BitmapFactory.decodeStream(inputStream),
                    badgeJsonObject.getDouble("height").px.toInt(),
                    badgeJsonObject.getDouble("width").px.toInt(),
                    true
                )

                val badge = BadgeOptions.from(bitmap).apply {
                    id = badgeJsonObject.getString("badgeID")

                    val offset = badgeJsonObject.getJSONObject("offset").toLatLng()
                    setOffset(offset.longitude.toFloat(), offset.latitude.toFloat())

                    val zOrder = badgeJsonObject.getInt("zOrder")
                    setZOrder(zOrder)
                }

                badges.add(badge)
            }

            val inputStream = FlutterKakaoMapsPlugin.getAsset(style.getString("symbol"))
            val bitmap = Bitmap.createScaledBitmap(
                BitmapFactory.decodeStream(inputStream),
                style.getDouble("height").px.toInt(),
                style.getDouble("width").px.toInt(),
                true
            )

            val labelStyle = LabelStyle.from(bitmap).apply {
                anchorPoint = style.getJSONObject("anchorPoint").toPointF()
                zoomLevel = style.getInt("level")

                val transition = Transition.getEnum(style.getInt("transitionType"))

                iconTransition = LabelTransition.from(transition, transition)

                setBadges(*badges.toTypedArray())
            }

            labelStyles.add(labelStyle)
        }

        labelManager.addLabelStyles(
            LabelStyles.from(
                styleID, labelStyles
            )
        )

        result.success(null)
    }

    private fun changePoiIconStyle(arguments: JSONObject, result: MethodChannel.Result) {
        printLog("changePoiIconStyle")

        val mapView = mapView ?: run {
            result.error("NOT_FOUND_MAPVIEW", "mapView is null", null)
            return
        }

        val labelManager = mapView.labelManager ?: run {
            result.error("NOT_FOUND_LABEL_MANAGER", "labelManager is null", null)
            return
        }

        val labelLayer = labelManager.getLayer(arguments.getString("layerID"))

        val poi = labelLayer.getLabel(arguments.getString("poiID")) ?: run {
            result.error("NOT_FOUND_POI", "poi is null", null)
            return
        }

        poi.changeStyles(labelManager.getLabelStyles(arguments.getString("styleID")))

        result.success(null)
    }

    private fun addLabelLayer(arguments: JSONObject, result: MethodChannel.Result) {
        printLog("addLabelLayer")

        val mapView = mapView ?: run {
            result.error("NOT_FOUND_MAPVIEW", "mapView is null", null)
            return
        }

        val labelManager = mapView.labelManager ?: run {
            result.error("NOT_FOUND_LABEL_MANAGER", "labelManager is null", null)
            return
        }

        labelManager.addLayer(
            arguments.toLabelLayerOptions()
        ) ?: run {
            result.error("FAILED_ADD", "failed add labelLayer", null)
            return
        }

        result.success(null)
    }

    private fun addLodLabelLayer(arguments: JSONObject, result: MethodChannel.Result) {
        printLog("addLodLabelLayer")

        val mapView = mapView ?: run {
            result.error("NOT_FOUND_MAPVIEW", "mapView is null", null)
            return
        }

        val labelManager = mapView.labelManager ?: run {
            result.error("NOT_FOUND_LABEL_MANAGER", "labelManager is null", null)
            return
        }

        labelManager.addLodLayer(
            arguments.toLabelLayerOptions()
        ) ?: run {
            result.error("FAILED_ADD", "failed add labelLayer", null)
            return
        }

        result.success(null)
    }

    private fun moveCamera(arguments: JSONObject, result: MethodChannel.Result) {
        printLog("moveCamera")

        val mapView = mapView ?: run {
            result.error("NOT_FOUND_MAPVIEW", "mapView is null", null)
            return
        }

        val cameraPosition = mapView.cameraPosition!!
        var cameraTarget = cameraPosition.position
        var cameraZoomLevel = cameraPosition.zoomLevel
        val cameraHeight = cameraPosition.height
        var cameraRotation = cameraPosition.rotationAngle
        var cameraTilt = cameraPosition.tiltAngle

        if (!arguments.isNull("target")) {
            cameraTarget = arguments.getJSONObject("target").toLatLng()
        }

        if (!arguments.isNull("zoomLevel")) {
            cameraZoomLevel = arguments.getInt("zoomLevel")
        }

        if (!arguments.isNull("rotation")) {
            cameraRotation = arguments.getDouble("rotation")
        }

        if (!arguments.isNull("tilt")) {
            cameraTilt = arguments.getDouble("tilt")
        }

        val cameraUpdate = CameraUpdateFactory.newCameraPosition(
            CameraPosition.from(
                cameraTarget.latitude,
                cameraTarget.longitude,
                cameraZoomLevel,
                cameraTilt,
                cameraRotation,
                cameraHeight,
            ),
        )

        mapView.moveCamera(cameraUpdate)

        result.success(null)
    }

    private fun animateCamera(arguments: JSONObject, result: MethodChannel.Result) {
        printLog("animateCamera")

        val mapView = mapView ?: run {
            result.error("NOT_FOUND_MAPVIEW", "mapView is null", null)
            return
        }

        val cameraPosition = mapView.cameraPosition!!
        var cameraTarget = cameraPosition.position
        var cameraZoomLevel = cameraPosition.zoomLevel
        val cameraHeight = cameraPosition.height
        var cameraRotation = cameraPosition.rotationAngle
        var cameraTilt = cameraPosition.tiltAngle

        if (!arguments.isNull("target")) {
            cameraTarget = arguments.getJSONObject("target").toLatLng()
        }

        if (!arguments.isNull("zoomLevel")) {
            cameraZoomLevel = arguments.getInt("zoomLevel")
        }

        if (!arguments.isNull("rotation")) {
            cameraRotation = arguments.getDouble("rotation")
        }

        if (!arguments.isNull("tilt")) {
            cameraTilt = arguments.getDouble("tilt")
        }

        val cameraAnimationOptions =
            arguments.getJSONObject("cameraAnimationOptions").toCameraAnimation()

        val cameraUpdate = CameraUpdateFactory.newCameraPosition(
            CameraPosition.from(
                cameraTarget.latitude,
                cameraTarget.longitude,
                cameraZoomLevel,
                cameraTilt,
                cameraRotation,
                cameraHeight,
            ),
        )

        mapView.moveCamera(cameraUpdate, cameraAnimationOptions)

        result.success(null)
    }

    private fun moveCameraTransform(arguments: JSONObject, result: MethodChannel.Result) {
        printLog("moveCameraTransform")

        val mapView = mapView ?: run {
            result.error("NOT_FOUND_MAPVIEW", "mapView is null", null)
            return
        }

        val cameraPosition = mapView.cameraPosition!!
        val cameraTarget = cameraPosition.position
        val cameraZoomLevel = cameraPosition.zoomLevel
        val cameraHeight = cameraPosition.height
        val cameraRotation = cameraPosition.rotationAngle
        val cameraTilt = cameraPosition.tiltAngle

        val point = arguments.getJSONObject("point").toLatLng()
        val height = arguments.getDouble("height")
        val rotation = arguments.getDouble("rotation")
        val tilt = arguments.getDouble("tilt")

        val cameraUpdate = CameraUpdateFactory.newCameraPosition(
            CameraPosition.from(
                cameraTarget.latitude + point.latitude,
                cameraTarget.longitude + point.longitude,
                cameraZoomLevel,
                cameraTilt + tilt,
                cameraRotation + rotation,
                cameraHeight + height,
            ),
        )

        mapView.moveCamera(cameraUpdate)

        result.success(null)
    }

    private fun animateCameraTransform(arguments: JSONObject, result: MethodChannel.Result) {
        printLog("animateCameraTransform")

        val mapView = mapView ?: run {
            result.error("NOT_FOUND_MAPVIEW", "mapView is null", null)
            return
        }

        val cameraPosition = mapView.cameraPosition!!
        val cameraTarget = cameraPosition.position
        val cameraZoomLevel = cameraPosition.zoomLevel
        val cameraHeight = cameraPosition.height
        val cameraRotation = cameraPosition.rotationAngle
        val cameraTilt = cameraPosition.tiltAngle

        val point = arguments.getJSONObject("point").toLatLng()
        val height = arguments.getDouble("height")
        val rotation = arguments.getDouble("rotation")
        val tilt = arguments.getDouble("tilt")

        val cameraAnimationOptions =
            arguments.getJSONObject("cameraAnimationOptions").toCameraAnimation()

        val cameraUpdate = CameraUpdateFactory.newCameraPosition(
            CameraPosition.from(
                cameraTarget.latitude + point.latitude,
                cameraTarget.longitude + point.longitude,
                cameraZoomLevel,
                cameraTilt + tilt,
                cameraRotation + rotation,
                cameraHeight + height,
            ),
        )

        mapView.moveCamera(cameraUpdate, cameraAnimationOptions)

        result.success(null)
    }

    private fun getCameraPosition(result: MethodChannel.Result) {
        printLog("getCameraPosition")

        val mapView = mapView ?: run {
            result.error("NOT_FOUND_MAPVIEW", "mapView is null", null)
            return
        }

        mapView.cameraPosition?.let { cameraPosition ->
            result.success(
                JSONObject().apply {
                    put("height", cameraPosition.height)
                    put("rotationAngle", cameraPosition.rotationAngle)
                    put("tiltAngle", cameraPosition.tiltAngle)
                    put("zoomLevel", cameraPosition.zoomLevel)
                    put("position", JSONObject().apply {
                        put("latitude", cameraPosition.position?.latitude)
                        put("longitude", cameraPosition.position?.longitude)
                    })
                })
        }
    }

    private fun setViewInfo(arguments: JSONObject, result: MethodChannel.Result) {
        printLog("setViewInfo")

        val mapView = mapView ?: run {
            result.error("NOT_FOUND_MAPVIEW", "mapView is null", null)
            return
        }

        val appName = arguments.getString("appName")
        val viewInfoName = arguments.getString("viewInfoName")

        mapView.changeMapViewInfo(MapViewInfo.from(appName, viewInfoName))

        result.success(null)
    }

    private fun showOverlay(arguments: JSONObject, result: MethodChannel.Result) {
        printLog("showOverlay")

        val mapView = mapView ?: run {
            result.error("NOT_FOUND_MAPVIEW", "mapView is null", null)
            return
        }

        val overlay = MapOverlay.getEnum(arguments.getString("overlay"))

        mapView.showOverlay(overlay)

        result.success(null)
    }

    private fun hideOverlay(arguments: JSONObject, result: MethodChannel.Result) {
        printLog("hideOverlay")

        val mapView = mapView ?: run {
            result.error("NOT_FOUND_MAPVIEW", "mapView is null", null)
            return
        }

        val overlay = MapOverlay.getEnum(arguments.getString("overlay"))

        mapView.hideOverlay(overlay)

        result.success(null)
    }

    private fun setEnabled(arguments: JSONObject, result: MethodChannel.Result) {
        printLog("setEnabled")

        val mapView = mapView ?: run {
            result.error("NOT_FOUND_MAPVIEW", "mapView is null", null)
            return
        }

        val enabled = arguments.getBoolean("enabled")

        mapView.isVisible = enabled

        result.success(null)
    }

    private fun setBuildingScale(arguments: JSONObject, result: MethodChannel.Result) {
        printLog("setBuildingScale")

        val mapView = mapView ?: run {
            result.error("NOT_FOUND_MAPVIEW", "mapView is null", null)
            return
        }

        val buildingScale = arguments.getDouble("buildingScale").toFloat()

        mapView.buildingHeightScale = buildingScale

        result.success(null)
    }

    private fun getPadding(result: MethodChannel.Result) {
        printLog("getPadding")

        val mapView = mapView ?: run {
            result.error("NOT_FOUND_MAPVIEW", "mapView is null", null)
            return
        }

        val padding = mapView.padding

        val json = JSONObject().apply {
            put("left", padding.left.dp)
            put("top", padding.top.dp)
            put("bottom", padding.bottom.dp)
            put("right", padding.right.dp)
        }

        result.success(json)
    }

    private fun setPadding(arguments: JSONObject, result: MethodChannel.Result) {
        printLog("setPadding")

        val mapView = mapView ?: run {
            result.error("NOT_FOUND_MAPVIEW", "mapView is null", null)
            return
        }

        val padding = arguments.toPadding()

        mapView.setPadding(
            padding.left.px,
            padding.top.px,
            padding.right.px,
            padding.bottom.px,
        )

        result.success(null)
    }

    private fun setLogoPosition(arguments: JSONObject, result: MethodChannel.Result) {
        printLog("setLogoPosition")

        val mapView = mapView ?: run {
            result.error("NOT_FOUND_MAPVIEW", "mapView is null", null)
            return
        }

        val logo = mapView.logo ?: run {
            result.error("NOT_FOUND_LOGO", "logo is null", null)
            return
        }

        val logoPosition = arguments.toKakaoMapPosition()

        logo.setPosition(
            logoPosition.alignment.toMapGravity(),
            logoPosition.x.px,
            logoPosition.y.px,
        )

        result.success(null)
    }

    private fun setPoiOptions(arguments: JSONObject, result: MethodChannel.Result) {
        printLog("setPoiOptions")

        val mapView = mapView ?: run {
            result.error("NOT_FOUND_MAPVIEW", "mapView is null", null)
            return
        }

        val poiOptions = arguments.toPoiOptions()

        mapView.setPoiClickable(poiOptions.clickable)
        mapView.setPoiVisible(poiOptions.enabled)
        mapView.setPoiScale(poiOptions.scale)

        result.success(null)
    }

    private fun setCompassOptions(arguments: JSONObject, result: MethodChannel.Result) {
        printLog("setCompassOptions")

        val mapView = mapView ?: run {
            result.error("NOT_FOUND_MAPVIEW", "mapView is null", null)
            return
        }

        val compass = mapView.compass ?: run {
            result.error("NOT_FOUND_COMPASS", "compass is null", null)
            return
        }

        val compassOptions = arguments.toCompassOptions()

        if (compassOptions.enabled) {
            compass.show()
        } else {
            compass.hide()
        }
        compass.setPosition(
            compassOptions.position.alignment.toMapGravity(),
            compassOptions.position.x.px,
            compassOptions.position.y.px,
        )

        result.success(null)
    }

    private fun setScaleBarOptions(arguments: JSONObject, result: MethodChannel.Result) {
        printLog("setScaleBarOptions")

        val mapView = mapView ?: run {
            result.error("NOT_FOUND_MAPVIEW", "mapView is null", null)
            return
        }

        val scaleBar = mapView.scaleBar ?: run {
            result.error("NOT_FOUND_SCALE_BAR", "scaleBar is null", null)
            return
        }

        val scaleBarOptions = arguments.toScaleBarOptions()

        if (scaleBarOptions.enabled) {
            scaleBar.show()
        } else {
            scaleBar.hide()
        }
        scaleBar.setPosition(
            scaleBarOptions.position.alignment.toMapGravity(),
            scaleBarOptions.position.x.px,
            scaleBarOptions.position.y.px,
        )
        scaleBar.isAutoHide = scaleBarOptions.autoDisabled
        scaleBar.setFadeInOutTime(
            scaleBarOptions.fadeInOutOptions.fadeInTime,
            scaleBarOptions.fadeInOutOptions.fadeOutTime,
            scaleBarOptions.fadeInOutOptions.retentionTime
        )

        result.success(null)
    }

    init {
        viewMethodChannel.setMethodCallHandler(viewMethodCallHandler)

        mapViewContainer = MapView(activity)

        printLog("start")

        mapViewContainer.start(
            object : MapLifeCycleCallback() {
                override fun onMapResumed() {
                    printLog("onMapResumed")
                }

                override fun onMapPaused() {
                    printLog("onMapPaused")
                }

                override fun onMapDestroy() {
                    printLog("onMapDestroy")
                }

                override fun onMapError(error: Exception) {
                    printLog("onMapError: ${error.message}")
                }
            },
            object : KakaoMapReadyCallback() {
                override fun onMapReady(kakaoMap: KakaoMap) {
                    mapView = kakaoMap

                    val mapView = mapView ?: run {
                        return
                    }

                    // Overlay
                    if (options.overlay != null) {
                        mapView.showOverlay(options.overlay!!)
                    }

                    // Language
                    mapView.setPoiLanguage(options.language)

                    // BuildingScale
                    mapView.buildingHeightScale = options.buildingScale

                    // Padding
                    mapView.setPadding(
                        options.padding.left.px,
                        options.padding.top.px,
                        options.padding.right.px,
                        options.padding.bottom.px,
                    )
                    // LogoPosition
                    mapView.logo?.setPosition(
                        options.logoPosition.alignment.toMapGravity(),
                        options.logoPosition.x.px,
                        options.logoPosition.y.px,
                    )
                    // PoiOptions
                    mapView.setPoiClickable(options.poiOptions.clickable)
                    mapView.setPoiVisible(options.poiOptions.enabled)
                    mapView.setPoiScale(options.poiOptions.scale)

                    // CompassOptions
                    mapView.compass?.let { compass ->
                        if (options.compassOptions.enabled) {
                            compass.show()
                        } else {
                            compass.hide()
                        }
                        compass.setPosition(
                            options.compassOptions.position.alignment.toMapGravity(),
                            options.compassOptions.position.x.px,
                            options.compassOptions.position.y.px,
                        )
                    }
                    // ScaleBarOptions
                    mapView.scaleBar?.let { scaleBar ->
                        if (options.scaleBarOptions.enabled) {
                            scaleBar.show()
                        } else {
                            scaleBar.hide()
                        }
                        scaleBar.setPosition(
                            options.scaleBarOptions.position.alignment.toMapGravity(),
                            options.scaleBarOptions.position.x.px,
                            options.scaleBarOptions.position.y.px,
                        )
                        scaleBar.isAutoHide = options.scaleBarOptions.autoDisabled
                        scaleBar.setFadeInOutTime(
                            options.scaleBarOptions.fadeInOutOptions.fadeInTime,
                            options.scaleBarOptions.fadeInOutOptions.fadeOutTime,
                            options.scaleBarOptions.fadeInOutOptions.retentionTime
                        )
                    }

                    mapView.setOnCameraMoveEndListener { _, cameraPosition, gestureType ->
                        viewMethodChannel.invokeMethod("cameraPosition",
                            JSONObject().apply {
                                put("height", cameraPosition.height)
                                put("rotationAngle", cameraPosition.rotationAngle)
                                put("tiltAngle", cameraPosition.tiltAngle)
                                put("zoomLevel", cameraPosition.zoomLevel)
                                put("position", JSONObject().apply {
                                    put("latitude", cameraPosition.position?.latitude)
                                    put("longitude", cameraPosition.position?.longitude)
                                })
                                put("gestureType", gestureType)
                            })
                    }

                    mapView.setOnLodLabelClickListener { _, _, label ->
                        viewMethodChannel.invokeMethod("onLodLabelClicked", JSONObject().apply {
                            put("labelId", label.labelId)
                            put("latitude", label.position.latitude)
                            put("longitude", label.position.longitude)
                        })
                        false
                    }

                    mapView.cameraMaxLevel = 20
                    mapView.cameraMinLevel = 8

                    viewMethodChannel.invokeMethod("onMapReady", null)
                }

                override fun getViewName(): String {
                    return options.viewName
                }

                override fun getMapViewInfo(): MapViewInfo {
                    return MapViewInfo.from(options.appName, MapType.getEnum(options.viewInfoName))
                }

                override fun getPosition(): LatLng {
                    return options.defaultPosition
                }

                override fun getZoomLevel(): Int {
                    return options.defaultLevel
                }

                override fun isVisible(): Boolean {
                    return options.enabled
                }
            },
        )

    }

    override fun getView(): View {
        return mapViewContainer
    }

    override fun dispose() = Unit
}
