//
//  SMVVideoTimeFormat.swift
//  SwiftMediaViewer
//

#if os(iOS)
import Foundation

/// Formats playback times for the scrubber, such as "0:12" or "1:02:03".
enum SMVVideoTimeFormat {
    /// `seconds` as minutes and seconds, adding hours for an hour or more.
    static func string(for seconds: Double) -> String {
        let whole = seconds.isFinite ? Int(max(seconds, 0).rounded(.down)) : 0
        let duration = Duration.seconds(whole)
        let pattern: Duration.TimeFormatStyle.Pattern = whole >= 3600 ? .hourMinuteSecond : .minuteSecond
        return duration.formatted(.time(pattern: pattern))
    }

    /// The scrubber's accessibility value, such as "0:12 of 1:05".
    static func accessibilityValue(current: Double, total: Double) -> String {
        guard total > 0 else { return string(for: current) }
        return "\(string(for: current)) of \(string(for: total))"
    }
}
#endif
