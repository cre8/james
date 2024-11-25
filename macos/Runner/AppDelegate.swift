import Cocoa
import FlutterMacOS
import ApplicationServices

@main
class AppDelegate: FlutterAppDelegate {
    override func applicationDidFinishLaunching(_ notification: Notification) {
        requestAccessibilityPermissions()

        guard let controller = NSApplication.shared.windows.first?.contentViewController as? FlutterViewController else {
            return
        }

        let channel = FlutterMethodChannel(name: "com.example.text_selection",
                                           binaryMessenger: controller.engine.binaryMessenger)

        channel.setMethodCallHandler { [weak self] (call, result) in
            if call.method == "getSelectedText" {
                if let selectedText = self?.getSelectedText() {
                    result(selectedText)
                } else {
                    result(FlutterError(code: "UNAVAILABLE",
                                        message: "Could not get selected text",
                                        details: nil))
                }
            } else {
                result(FlutterMethodNotImplemented)
            }
        }
    }

    func requestAccessibilityPermissions() {
            let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true]
            let isTrusted = AXIsProcessTrustedWithOptions(options)
            if !isTrusted {
                print("Accessibility permissions not granted. Please enable them in System Preferences.")
            }
        }

      func getSelectedText() -> String? {
        if !AXIsProcessTrusted() {
            print("Accessibility permissions are not granted.")
            return nil
        }

        guard let focusedApp = NSWorkspace.shared.frontmostApplication else {
            print("No focused application found.")
            return nil
        }

        let pid = focusedApp.processIdentifier
        let axApp = AXUIElementCreateApplication(pid)
        var focusedElement: CFTypeRef?

        // Get the focused UI element
        let focusedResult = AXUIElementCopyAttributeValue(axApp, kAXFocusedUIElementAttribute as CFString, &focusedElement)
        if focusedResult != .success {
            print("Failed to get focused element from the app: \(focusedResult.rawValue)")
            return nil
        }

        guard let element = focusedElement else {
            print("Focused element is nil.")
            return nil
        }

        var selectedText: CFTypeRef?

        // Get the selected text
        let textResult = AXUIElementCopyAttributeValue(element as! AXUIElement, kAXSelectedTextAttribute as CFString, &selectedText)
        if textResult != .success {
            print("Failed to get selected text: \(textResult.rawValue)")
            return nil
        }

        if let text = selectedText as? String {
            return text
        } else {
            print("Selected text is not a string.")
            return nil
        }
    }

}
