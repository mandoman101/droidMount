import Cocoa
import FlutterMacOS

class MainFlutterWindow: FlutterWindow {
  override func awakeFromNib() {
    super.awakeFromNib()
    
    // Set up the Flutter window
    let flutterViewController = FlutterViewController()
    flutterViewController.setInitialRoute("/")
    self.setFrame(NSMakeRect(0, 0, 1024, 768), display: true)
    self.contentView = FlutterView()
    self.flutterViewController = flutterViewController
  }
}