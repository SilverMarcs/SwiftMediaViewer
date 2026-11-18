//
//  SMVPinchGesture.swift
//  SwiftMediaViewer
//

#if os(iOS)
import SwiftUI
import UIKit

/// A pinch that zooms a video page.
///
/// It declines to start when pinching inwards at 1×, so that pinch still
/// reaches the zoom transition and closes the viewer.
struct SMVPinchGesture: UIGestureRecognizerRepresentable {
    /// Whether the page is zoomed in, which lets an inward pinch zoom back out.
    let isZoomed: () -> Bool
    let onBegan: (CGPoint) -> Void
    let onChanged: (CGFloat, CGPoint) -> Void
    let onEnded: () -> Void

    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator {
        Coordinator(isZoomed: isZoomed)
    }

    func makeUIGestureRecognizer(context: Context) -> UIPinchGestureRecognizer {
        let recognizer = UIPinchGestureRecognizer()
        recognizer.delegate = context.coordinator
        return recognizer
    }

    func updateUIGestureRecognizer(_ recognizer: UIPinchGestureRecognizer, context: Context) {
        context.coordinator.isZoomed = isZoomed
    }

    func handleUIGestureRecognizerAction(_ recognizer: UIPinchGestureRecognizer, context: Context) {
        let focus = context.converter.localLocation
        switch recognizer.state {
        case .began:
            onBegan(focus)
            onChanged(recognizer.scale, focus)
        case .changed:
            onChanged(recognizer.scale, focus)
        case .ended, .cancelled, .failed:
            onEnded()
        default:
            break
        }
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var isZoomed: () -> Bool

        init(isZoomed: @escaping () -> Bool) {
            self.isZoomed = isZoomed
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard let pinch = gestureRecognizer as? UIPinchGestureRecognizer else { return true }
            // Inward at 1× belongs to the zoom transition's pinch to close.
            return isZoomed() || pinch.scale > 1
        }

        /// While this pinch is zooming, the zoom transition's pinch to close
        /// waits for it to fail, so zooming back out never closes the viewer.
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                               shouldBeRequiredToFailBy other: UIGestureRecognizer) -> Bool {
            SMVTransitionGestures.isPinchToClose(other) || SMVTransitionGestures.isSwipeToClose(other)
        }
    }
}
#endif
