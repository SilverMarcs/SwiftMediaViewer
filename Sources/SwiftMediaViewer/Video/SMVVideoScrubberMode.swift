//
//  SMVVideoScrubberMode.swift
//  SwiftMediaViewer
//

import Foundation

/// Whether the custom viewer has a scrubber along the bottom of each video.
///
/// The scrubber is a thin progress line with a tall touch area. Dragging it
/// seeks, and it thickens and shows the time while dragged.
public enum SMVVideoScrubberMode: Sendable {
    /// Drawn while the controls are showing (after a single tap). While idle
    /// the line is invisible but can still be dragged. This is the default.
    case withControls
    /// Always drawn.
    case always
    /// No scrubber.
    case none
}
