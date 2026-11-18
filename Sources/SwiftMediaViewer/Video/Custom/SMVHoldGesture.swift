//
//  SMVHoldGesture.swift
//  SwiftMediaViewer
//

#if os(iOS)
import SwiftUI
import UIKit

/// A press-and-hold that reports when it starts and when the finger lifts.
///
/// SwiftUI's long press only reports the start, and pairing it with a drag to
/// catch the lift blocks the zoom transition's swipe to close. UIKit's long
/// press recognizer reports both, fails as soon as the finger moves early, and
/// leaves the taps and the swipe alone.
struct SMVHoldGesture: UIGestureRecognizerRepresentable {
    let minimumDuration: TimeInterval
    let onBegan: () -> Void
    let onEnded: () -> Void

    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator {
        Coordinator()
    }

    func makeUIGestureRecognizer(context: Context) -> UILongPressGestureRecognizer {
        let recognizer = UILongPressGestureRecognizer()
        recognizer.minimumPressDuration = minimumDuration
        recognizer.cancelsTouchesInView = false
        recognizer.delegate = context.coordinator
        return recognizer
    }

    func handleUIGestureRecognizerAction(_ recognizer: UILongPressGestureRecognizer, context: Context) {
        switch recognizer.state {
        case .began:
            onBegan()
        case .ended, .cancelled, .failed:
            onEnded()
        default:
            break
        }
    }

    /// Lets the hold run alongside the page's tap gestures and the scroll view.
    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                               shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
            true
        }
    }
}
#endif
