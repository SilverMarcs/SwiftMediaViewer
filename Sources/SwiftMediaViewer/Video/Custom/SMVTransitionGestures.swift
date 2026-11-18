//
//  SMVTransitionGestures.swift
//  SwiftMediaViewer
//

#if os(iOS)
import UIKit

/// Recognises the zoom navigation transition's own close gestures, so a
/// zoomed page can hold them off while it pinches or pans.
///
/// UIKit exposes no API for these, so they're matched by class name. If a
/// later iOS renames them, zooming still works; only pinching or panning a
/// zoomed page might also start closing the viewer.
enum SMVTransitionGestures {
    /// The pinch that closes the viewer.
    static func isPinchToClose(_ recognizer: UIGestureRecognizer) -> Bool {
        String(describing: type(of: recognizer)).contains("TransformGestureRecognizer")
    }

    /// The swipe that closes the viewer.
    static func isSwipeToClose(_ recognizer: UIGestureRecognizer) -> Bool {
        String(describing: type(of: recognizer)).contains("SwipeDismissGestureRecognizer")
    }
}
#endif
