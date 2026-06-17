import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    // Phone-like aspect ratio (iPhone 15 Pro: 393×852)
    let phoneWidth: CGFloat = 393
    let phoneHeight: CGFloat = 852
    let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
    let originX = screenFrame.midX - phoneWidth / 2
    let originY = screenFrame.midY - phoneHeight / 2
    let windowFrame = NSRect(x: originX, y: originY, width: phoneWidth, height: phoneHeight)
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    self.minSize = NSSize(width: 350, height: 700)
    self.maxSize = NSSize(width: 500, height: 1000)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
