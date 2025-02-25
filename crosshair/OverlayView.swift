import Cocoa

class OverlayView: NSView {
    var cursorX: CGFloat = 0
    var cursorY: CGFloat = 0

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        let path = NSBezierPath()
        path.lineWidth = 1.0
        
        // Draw vertical line: from top to bottom at the current cursor X.
        path.move(to: NSPoint(x: cursorX, y: 0))
        path.line(to: NSPoint(x: cursorX, y: bounds.height))
        
        // Draw horizontal line: from left to right at the current cursor Y.
        path.move(to: NSPoint(x: 0, y: cursorY))
        path.line(to: NSPoint(x: bounds.width, y: cursorY))
        
        NSColor.black.setStroke()
        path.stroke()
    }
}
