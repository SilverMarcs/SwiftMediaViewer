//
//  SMVZoomPanGesture.swift
//  SwiftMediaViewer
//

#if os(iOS)
import SwiftUI
import UIKit

/// A one-finger pan that moves a zoomed video page around. It only starts
/// while the page is zoomed, so at 1× swipes still page through the feed and
/// close the viewer.
struct SMVZoomPanGesture: UIGestureRecognizerRepresentable {
    let isZoomed: () -> Bool
    let onBegan: () -> Void
    let onChanged: (CGSize) -> Void
    let onEnded: () -> Void

    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator {
        Coordinator(isZoomed: isZoomed)
    }

    func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
        let recognizer = UIPanGestureRecognizer()
        recognizer.maximumNumberOfTouches = 1
        recognizer.delegate = context.coordinator
        return recognizer
    }

    func updateUIGestureRecognizer(_ recognizer: UIPanGestureRecognizer, context: Context) {
        context.coordinator.isZoomed = isZoomed
    }

    func handleUIGestureRecognizerAction(_ recognizer: UIPanGestureRecognizer, context: Context) {
        let translation = recognizer.translation(in: recognizer.view)
        switch recognizer.state {
        case .began:
            onBegan()
        case .changed:
            onChanged(CGSize(width: translation.x, height: translation.y))
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
            isZoomed()
        }

        /// While panning a zoomed page, the zoom transition's swipe to close
        /// waits for this pan to fail. At 1× the pan fails at once.
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                               shouldBeRequiredToFailBy other: UIGestureRecognizer) -> Bool {
            SMVTransitionGestures.isSwipeToClose(other)
        }
    }
}
#endif
