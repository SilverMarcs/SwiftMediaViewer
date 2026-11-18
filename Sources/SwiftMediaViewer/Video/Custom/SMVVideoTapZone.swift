//
//  SMVVideoTapZone.swift
//  SwiftMediaViewer
//

#if os(iOS)
/// A strip of the custom viewer's page, which decides what taps and holds do.
/// The edges take a quarter of the width each and the center the half between.
enum SMVVideoTapZone: CaseIterable, Sendable {
    /// Double-tap skips back; hold plays at 2×.
    case leading
    /// Double-tap plays or pauses.
    case center
    /// Double-tap skips forward; hold plays at 2×.
    case trailing

    /// The strip's width in quarters of the page.
    var widthInQuarters: Int { self == .center ? 2 : 1 }

    /// Whether double-taps here skip and holds play at 2×.
    var isEdge: Bool { self != .center }

    /// The skip direction: -1 back, +1 forward, 0 for the center.
    var skipDirection: Double {
        switch self {
        case .leading: -1
        case .center: 0
        case .trailing: 1
        }
    }
}
#endif
