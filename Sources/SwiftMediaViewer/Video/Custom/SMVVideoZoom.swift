//
//  SMVVideoZoom.swift
//  SwiftMediaViewer
//

#if os(iOS)
import Observation
import SwiftUI

/// One page's pinch zoom and pan.
///
/// A point of the video at `p` (measured from the page's center) is drawn at
/// `p * scale + offset`. Pinching keeps the point under the fingers in place;
/// once zoomed, one finger pans. Letting go below a small zoom snaps back to 1×.
@MainActor
@Observable
final class SMVVideoZoom {
    static let maximumScale: CGFloat = 4
    /// Pinching ends back at 1× below this.
    static let snapBackScale: CGFloat = 1.1

    private(set) var scale: CGFloat = 1
    private(set) var offset: CGSize = .zero

    @ObservationIgnored private var startScale: CGFloat = 1
    @ObservationIgnored private var startOffset: CGSize = .zero
    @ObservationIgnored private var startFocus: CGPoint = .zero

    var isZoomed: Bool { scale > 1 }

    // MARK: Pinch

    func beginPinch(at focus: CGPoint) {
        startScale = scale
        startOffset = offset
        startFocus = focus
    }

    /// - Parameters:
    ///   - pinchScale: The pinch's scale since it began.
    ///   - focus: Where the fingers are now, from the page's center.
    func updatePinch(scale pinchScale: CGFloat, focus: CGPoint) {
        // A little give below 1× and above the maximum, settled on release.
        let newScale = min(max(startScale * pinchScale, 0.85), Self.maximumScale * 1.15)
        let ratio = newScale / startScale
        scale = newScale
        offset = CGSize(
            width: focus.x - (startFocus.x - startOffset.width) * ratio,
            height: focus.y - (startFocus.y - startOffset.height) * ratio
        )
    }

    func endPinch(pageSize: CGSize) {
        settle(pageSize: pageSize)
    }

    // MARK: Pan

    func beginPan() {
        startOffset = offset
    }

    func updatePan(translation: CGSize) {
        offset = CGSize(width: startOffset.width + translation.width,
                        height: startOffset.height + translation.height)
    }

    func endPan(pageSize: CGSize) {
        settle(pageSize: pageSize)
    }

    // MARK: Reset

    func reset() {
        withAnimation(.snappy(duration: 0.25)) {
            scale = 1
            offset = .zero
        }
    }

    /// Snaps back to 1× when barely zoomed, caps the zoom, and keeps the
    /// zoomed page covering the screen.
    private func settle(pageSize: CGSize) {
        guard scale >= Self.snapBackScale else { return reset() }
        let settledScale = min(scale, Self.maximumScale)
        let limitX = pageSize.width * (settledScale - 1) / 2
        let limitY = pageSize.height * (settledScale - 1) / 2
        withAnimation(.snappy(duration: 0.25)) {
            scale = settledScale
            offset = CGSize(width: min(max(offset.width, -limitX), limitX),
                            height: min(max(offset.height, -limitY), limitY))
        }
    }
}
#endif
