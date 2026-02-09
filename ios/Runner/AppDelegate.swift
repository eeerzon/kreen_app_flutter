import Flutter
import UIKit
import FirebaseCore
import Photos

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller = window?.rootViewController as! FlutterViewController
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

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

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
}
