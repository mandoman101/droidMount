import Cocoa
import FlutterMacOS
import ApplicationServices

@NSApplicationMain
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationDidFinishLaunching(_ notification: Notification) {
    let controller = window?.contentViewController as! FlutterViewController

    // Permission bridge
    let permissionChannel = FlutterMethodChannel(
      name: "com.mandoman.openclawdesktop/permissions",
      binaryMessenger: controller.engine.binaryMessenger
    )
    permissionChannel.setMethodCallHandler { [weak self] call, result in
      self?.handlePermissionCall(call, result: result)
    }
  }

  private func handlePermissionCall(
    _ call: FlutterMethodCall,
    result: @escaping FlutterResult
  ) {
    switch call.method {
    case "getPermissionStatus":
      let accessibility = AXIsProcessTrusted()
      // Screen recording: cannot check programmatically on macOS
      result([
        "accessibilityGranted": accessibility,
        "screenRecordingGranted": false
      ])

    case "requestAccessibility":
      let granted = AXIsProcessTrustedWithOptions(
        [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true] as CFDictionary
      )
      result(granted)

    case "requestScreenRecording":
      result(false)

    case "openAccessibilitySettings":
      openSystemPreferences(panel: "Privacy_Accessibility")
      result(nil)

    case "openScreenRecordingSettings":
      openSystemPreferences(panel: "Privacy_ScreenRecording")
      result(nil)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func openSystemPreferences(panel: String) {
    let url = URL(
      string: "x-apple.systempreferences:com.apple.preference.security?\(panel)"
    )!
    NSWorkspace.shared.open(url)
  }
}
