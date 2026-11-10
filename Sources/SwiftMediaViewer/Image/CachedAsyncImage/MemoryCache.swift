//
//  ImageCacher.swift
//  CachedAsyncImage
//
//  Created by Zabir Raihan on 16/07/2025.
//

import SwiftUI

public actor MemoryCache {
    public static let shared = MemoryCache()

    /// `NSCache` is thread-safe, so views read it synchronously while they're
    /// created; see `image(for:atLeast:)`.
    private nonisolated(unsafe) let cache = NSCache<NSString, PlatformImage>()

    init() {
        cache.totalCostLimit = 1024 * 1024 * 50
    }

    #if os(macOS)
    private func cost(for image: NSImage) -> Int {
        if let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            return cg.bytesPerRow * cg.height
        }
        let w = Int(image.size.width * 2)
        let h = Int(image.size.height * 2)
        return w * h * 4
    }
    #else
    private func cost(for image: UIImage) -> Int {
        if let cg = image.cgImage {
            return cg.bytesPerRow * cg.height
        }
        let scale = image.scale
        let w = Int(image.size.width * scale)
        let h = Int(image.size.height * scale)
        return w * h * 4
    }
    #endif

    func insert(_ image: PlatformImage, for url: URL) {
        let key = cacheKey(for: url) as NSString
        cache.setObject(image, forKey: key, cost: cost(for: image))
    }

    func get(for url: URL) -> PlatformImage? {
        cache.object(forKey: cacheKey(for: url) as NSString)
    }

    /// The cached image for `url` when its longer side is at least
    /// `targetSize` pixels, without waiting on the actor. A view that already
    /// has its image shows it in its first frame instead of a placeholder.
    nonisolated func image(for url: URL, atLeast targetSize: Int) -> PlatformImage? {
        guard let image = cache.object(forKey: cacheKey(for: url) as NSString),
              image.pixelMaxDimension >= targetSize else { return nil }
        return image
    }

    public func clearCache() {
        cache.removeAllObjects()
    }
}
