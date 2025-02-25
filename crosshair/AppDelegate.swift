import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var overlayView: OverlayView!
    var timer: Timer?
    
    // We'll store the eventTap reference here so we can remove it if needed.
    var eventTap: CFMachPort?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // 1. Create transparent overlay window
        guard let screen = NSScreen.main else { return }
        let screenRect = screen.frame
        
        window = NSWindow(contentRect: screenRect,
                          styleMask: .borderless,
                          backing: .buffered,
                          defer: false)
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces]
        window.isOpaque = false
        window.backgroundColor = .clear
        window.ignoresMouseEvents = true
        
        // 2. Add crosshair overlay view
        overlayView = OverlayView(frame: screenRect)
        window.contentView = overlayView
        window.makeKeyAndOrderFront(nil)
        
        // 3. Timer to track mouse position
        timer = Timer.scheduledTimer(timeInterval: 0.01,
                                     target: self,
                                     selector: #selector(updateMousePosition),
                                     userInfo: nil,
                                     repeats: true)
        
        // 4. Set up a low-level event tap for any key press
        startGlobalKeyCapture()
    }
    
    @objc func updateMousePosition() {
        let mouseLocation = NSEvent.mouseLocation
        let convertedPoint = window.convertPoint(fromScreen: mouseLocation)
        
        overlayView.cursorX = convertedPoint.x
        overlayView.cursorY = convertedPoint.y
        overlayView.needsDisplay = true
    }
    
    func startGlobalKeyCapture() {
        // We only care about keyDown events
        let eventMask = (1 << CGEventType.keyDown.rawValue)
        
        // Create an event tap at the session level
        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { _, _, event, _ in
                // Terminate on any key press
                NSApp.terminate(nil)
                // Pass the event on to the OS
                return Unmanaged.passUnretained(event)
            },
            userInfo: nil
        ) else {
            print("Failed to create event tap.")
            return
        }
        
        self.eventTap = eventTap
        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
        
        print("Global key capture started. Press any key to quit.")
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        timer?.invalidate()
        if let eventTap = eventTap {
            // Disable and remove the event tap
            CGEvent.tapEnable(tap: eventTap, enable: false)
            CFRunLoopRemoveSource(CFRunLoopGetMain(),
                                  CFMachPortCreateRunLoopSource(nil, eventTap, 0),
                                  .commonModes)
        }
    }
}

