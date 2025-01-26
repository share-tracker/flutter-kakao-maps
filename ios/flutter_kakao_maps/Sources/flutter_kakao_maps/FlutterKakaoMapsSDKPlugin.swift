@preconcurrency import Flutter
import KakaoMapsSDK

@MainActor
public class FlutterKakaoMapsPlugin: NSObject, FlutterPlugin {
    private static var registrar: FlutterPluginRegistrar!
    
    private static let BASE_ID = "com.shareinvest.flutter_kakao_maps"
    
    private static let LOG_EVENT_CHANNEL_NAME = "\(BASE_ID)/log"
    
    private static let INIT_METHOD_CHANNEL_NAME = "\(BASE_ID)/init"
    
    private static let KAKAO_MAP_VIEW_VIEW_ID = "\(BASE_ID)/kakao_map_view"
    
    internal static func createViewMethodChannelName(id: Int64) -> String {
        "\(KAKAO_MAP_VIEW_VIEW_ID)#\(id)"
    }
    
    internal static let logStreamHandler = LogStreamHandler()
    
    internal static func getAssetPath(named: String) -> String {
        let key = registrar.lookupKey(forAsset: named)
        let mainBundle = Bundle.main

        guard let path = mainBundle.path(forResource: key, ofType: nil) else {
            fatalError("Asset with name \(named) not found.")
        }        
        return path
    }
    
    private static func printLog(_ message: String) {
        FlutterKakaoMapsPlugin.logStreamHandler.sendMessage("KakaoMapsSDK \(message)")
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        self.registrar = registrar
        
        let logEventChannel = FlutterEventChannel(name: LOG_EVENT_CHANNEL_NAME, binaryMessenger: registrar.messenger())
        logEventChannel.setStreamHandler(logStreamHandler)
        
        let initMethodChannel = FlutterMethodChannel(name: INIT_METHOD_CHANNEL_NAME, binaryMessenger: registrar.messenger(), codec: FlutterJSONMethodCodec.sharedInstance())
        
        initMethodChannel.setMethodCallHandler { call, result in
            switch call.method {
            case "init":
                printLog("init")
                
                let arguments = call.arguments as! NSDictionary
                let appKey = arguments["appKey"] as! String
                
                SDKInitializer.InitSDK(appKey: appKey)
                
                result(nil)
            default: result(FlutterMethodNotImplemented)
            }
        }
        
        let kakaoMapViewFactory = KakaoMapViewFactory(messenger: registrar.messenger())
        registrar.register(kakaoMapViewFactory, withId: KAKAO_MAP_VIEW_VIEW_ID)
    }
}
