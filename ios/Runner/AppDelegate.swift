import Flutter
import UIKit
import FirebaseCore
import Photos

@main
@objc class AppDelegate: FlutterAppDelegate {
  
  private var methodChannel: FlutterMethodChannel?
  private var pendingLink: String?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller = window?.rootViewController as! FlutterViewController
    
    // ─── Save Image Channel ───────────────────────────────────────────────────
    let channel = FlutterMethodChannel(
      name: "save_image_channel",
      binaryMessenger: controller.binaryMessenger
    )
    channel.setMethodCallHandler { call, result in
      if call.method == "saveImageToGallery" {
        guard let args = call.arguments as? [String: Any],
              let path = args["path"] as? String else {
          result(FlutterError(code: "INVALID", message: "Invalid args", details: nil))
          return
        }
        self.saveImage(path: path, result: result)
      }
    }

    // ─── Deep Link Channel ────────────────────────────────────────────────────
    methodChannel = FlutterMethodChannel(
      name: "com.kreen.app/deep_link",
      binaryMessenger: controller.binaryMessenger
    )

    methodChannel?.setMethodCallHandler { [weak self] call, result in
      if call.method == "getPendingLink" {
        result(self?.pendingLink)
        self?.pendingLink = nil
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    // Handle cold start dari Universal Link
    if let url = launchOptions?[.url] as? URL {
      let urlString = url.absoluteString
      if urlString.contains("mobile-deeplink") {
        pendingLink = urlString
      }
    }

    // Handle cold start dari Universal Link (NSUserActivity)
    if let userActivity = launchOptions?[.userActivityDictionary] as? [String: Any],
       let webpageURL = userActivity[UIApplication.LaunchOptionsKey.url.rawValue] as? URL {
      let urlString = webpageURL.absoluteString
      if urlString.contains("mobile-deeplink") {
        pendingLink = urlString
      }
    }

    FirebaseApp.configure()
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // ─── Save Image ───────────────────────────────────────────────────────────
  private func saveImage(path: String, result: @escaping FlutterResult) {
    PHPhotoLibrary.requestAuthorization { status in
      guard status == .authorized else {
        DispatchQueue.main.async {
          result(
            FlutterError(
              code: "PERMISSION_DENIED",
              message: "Photo permission denied",
              details: nil
            )
          )
        }
        return
      }

      guard let image = UIImage(contentsOfFile: path) else {
        DispatchQueue.main.async {
          result(
            FlutterError(
              code: "IMAGE_ERROR",
              message: "Cannot load image",
              details: nil
            )
          )
        }
        return
      }

      DispatchQueue.main.async {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        result(true)
      }
    }
  }

  // ─── Universal Link (foreground / background) ─────────────────────────────
  override func application(
    _ application: UIApplication,
    continue userActivity: NSUserActivity,
    restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
  ) -> Bool {

    guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
          let url = userActivity.webpageURL else {
      return false
    }

    let urlString = url.absoluteString
    guard urlString.contains("mobile-deeplink") else { return false }

    print("iOS Universal Link: \(urlString)")

    if methodChannel != nil {
      methodChannel?.invokeMethod("onNewLink", arguments: urlString)
    } else {
      pendingLink = urlString
    }

    return true
  }

  // ─── URL Scheme fallback ──────────────────────────────────────────────────
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {

    let urlString = url.absoluteString
    guard urlString.contains("mobile-deeplink") else { return false }

    print("iOS URL Scheme: \(urlString)")

    if methodChannel != nil {
      methodChannel?.invokeMethod("onNewLink", arguments: urlString)
    } else {
      pendingLink = urlString
    }

    return true
  }
}