import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var protectionTextField: UITextField?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Set up content protection method channel
    let controller = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(
      name: "com.mdf.content_protection",
      binaryMessenger: controller.binaryMessenger
    )

    channel.setMethodCallHandler { [weak self] (call, result) in
      switch call.method {
      case "enableProtection":
        self?.enableScreenProtection()
        result(true)
      case "disableProtection":
        self?.disableScreenProtection()
        result(true)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  /// Uses a UITextField with isSecureTextEntry to prevent screen capture on iOS.
  /// When isSecureTextEntry is true, the system blanks the content during
  /// screen recording/screenshots.
  private func enableScreenProtection() {
    guard protectionTextField == nil else { return }
    let field = UITextField()
    field.isSecureTextEntry = true
    // Insert the secure field's layer into the window
    if let window = self.window {
      window.addSubview(field)
      field.centerYAnchor.constraint(equalTo: window.centerYAnchor).isActive = true
      field.centerXAnchor.constraint(equalTo: window.centerXAnchor).isActive = true
      // Move the Flutter view as a sublayer of the secure text field's layer
      window.layer.superlayer?.addSublayer(field.layer)
      field.layer.sublayers?.first?.addSublayer(window.layer)
    }
    protectionTextField = field
  }

  private func disableScreenProtection() {
    protectionTextField?.removeFromSuperview()
    protectionTextField = nil
  }
}
