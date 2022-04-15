import Flutter
import UIKit
import EbsSDK

enum VerificationStatus : String {
    case success = "SUCCESS"
    case error = "ERROR"
    case canceled = "CANCELED"
    case ebsNotInstalled = "EBS_NOT_INSTALLED"
    case sdkIsNotConfigured = "SDK_NOT_IS_CONFIGURED"
}

struct VerificationResult {
    init(_ result: @escaping FlutterResult) {
        self.result = result
    }
    
    func reply(_ status: VerificationStatus,
               code: String? = nil,
               state: String? = nil,
               verifyToken: String? = nil,
               expired: String? = nil) {
        result([
            "status": status.rawValue,
            "esiaCode": code,
            "esiaState": state,
            "ebsToken": verifyToken,
            "ebsTokenExpired": expired
        ])
    }
    
    let result: FlutterResult
}

public class SwiftEbsBiometryPlugin: NSObject, FlutterPlugin {
    private var scheme: String?
    private var sdk =  EbsSDKClient.shared
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "ru.surfstudio/ebs_biometry", binaryMessenger: registrar.messenger())
        let instance = SwiftEbsBiometryPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        registrar.addApplicationDelegate(instance)
    }
    
    public func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        if (url.scheme == scheme) {
            sdk.process(openUrl: url, options: options)
            return true
        }
        
        return false
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "configureSdk":
            configureSdk(call, result)
            
        case "isEbsAppInstalled":
            result(isEbsAppInstalled())
            break
            
        case "requestInstallApp":
            requestInstallApp()
            result(nil)
            break
            
        case "requestEsiaVerification":
            requestEsiaVerification(call, result)
            break
            
        case "requestEbsVerification":
            requestEbsVerification(call, result)
            break
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func configureSdk(_ call: FlutterMethodCall, _ result: FlutterResult) {
        if let myArgs = call.arguments as? [String: Any],
           let appScheme = myArgs["appScheme"] as? String,
           let infoSystem = myArgs["infoSystem"] as? String,
           let appTitle = myArgs["appTitle"] as? String {
            guard let uiViewController = (UIApplication.shared.delegate?.window??.rootViewController) else {
                result(FlutterError(
                    code: "-1",
                    message: "error while configuration",
                    details: nil
                ))
                return
            }
            
            // Конфигурация EbsSDK
            sdk.set(
                scheme: appScheme,
                title: appTitle,
                infoSystem: infoSystem,
                presenting: uiViewController
            )
            scheme = appScheme
            result(true)
        } else {
            result(FlutterError(
                code: "-1",
                message: "Could not extract flutter arguments in method: (configureSdk)",
                details: nil
            ))
        }
    }
    
    private func isEbsAppInstalled() -> Bool {
        return sdk.ebsAppIsInstalled
    }
    
    private func requestInstallApp() {
        sdk.openEbsInAppStore()
    }
    
    private func requestEsiaVerification(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        if let myArgs = call.arguments as? [String: Any],
           let esiaVerificationUri = myArgs["esiaVerificationUri"] as? String {
            let verificationResult = VerificationResult(result)
            // Метод отправляет запрос на получение Esia токена
            sdk.requestEsiaSession(urlString: esiaVerificationUri) { requestResult in
                switch requestResult {
                case .success(let esiaResult):
                    verificationResult.reply(
                        VerificationStatus.success,
                        code: esiaResult.code,
                        state: esiaResult.state
                    )
                    break
                    
                case .failure:
                    verificationResult.reply(VerificationStatus.error)
                    break
                    
                case .ebsNotInstalled:
                    verificationResult.reply(VerificationStatus.ebsNotInstalled)
                    break
                    
                case .sdkIsNotConfigured:
                    result(FlutterError(
                        code: "not_initialized",
                        message: "ebs_biometry plugin must be initialized before request verification",
                        details: nil
                    ))
                    break
                    
                case .cancel:
                    verificationResult.reply(VerificationStatus.canceled)
                    break
                }
            }
        } else {
            result(FlutterError(code: "-1",
                                message: "Could not extract flutter arguments in method: (requestEsiaVerification)",
                                details: nil))
        }
    }
    
    private func requestEbsVerification(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        if let myArgs = call.arguments as? [String: Any],
           let sessionId = myArgs["ebsSessionId"] as? String {
            let verificationResult = VerificationResult(result)
            // Метод отправляет запрос на получение Esia токена
            sdk.requestAuthorization(sessionId: sessionId, completion: { requestResult in
                switch requestResult {
                    
                case .success(let ebsResult):
                    verificationResult.reply(
                        VerificationStatus.success,
                        verifyToken: ebsResult.verifyToken,
                        expired: ebsResult.expired
                    )
                    
                case .failure:
                    verificationResult.reply(VerificationStatus.error)
                    
                case .cancel:
                    verificationResult.reply(VerificationStatus.canceled)
                    
                }
            })
        } else {
            result(FlutterError(
                code: "-1",
                message: "Could not extract flutter arguments in method: (requestEsiaVerification)",
                details: nil
            ))
        }
    }
}
