//
//  ImageSources.swift
//  SwiftMediaViewer
//
//  Lets an app load images for URLs in its own scheme, such as files fetched
//  over its own connection, which URLSession can't load.
//

import Foundation
import Synchronization

public enum SMVImageSources {
    /// Returns encoded image data for a URL, given the largest pixel size it
    /// will be shown at, so the source can send a smaller image.
    public typealias Loader = @Sendable (_ url: URL, _ maxPixelSize: Int) async throws -> Data

    private static let loaders = Mutex<[String: Loader]>([:])

    /// Loads every image whose URL has `scheme` with `load`. Images from these
    /// sources are kept in memory only, not on disk.
    public static func register(scheme: String, _ load: @escaping Loader) {
        loaders.withLock { $0[scheme.lowercased()] = load }
    }

    static func loader(for url: URL) -> Loader? {
        guard let scheme = url.scheme?.lowercased() else { return nil }
        return loaders.withLock { $0[scheme] }
    }
}
