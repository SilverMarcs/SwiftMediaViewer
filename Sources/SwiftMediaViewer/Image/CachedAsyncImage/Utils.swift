//
//  Utils.swift
//  CachedAsyncImage
//
//  Created by Zabir Raihan on 17/07/2025.
//

import Foundation
import CryptoKit
import SwiftUI

enum ImageError: Error {
    case loadFailed
    case taskCancelled
}

#if os(macOS)
typealias PlatformImage = NSImage
#else
typealias PlatformImage = UIImage
#endif

extension Image {
    init(platformImage: PlatformImage) {
        #if os(macOS)
        self.init(nsImage: platformImage)
        #else
        self.init(uiImage: platformImage)
        #endif
    }
}

extension PlatformImage {
    /// The longer side in pixels.
    var pixelMaxDimension: Int {
        #if os(macOS)
        if let cg = cgImage(forProposedRect: nil, context: nil, hints: nil) {
            return max(cg.width, cg.height)
        }
        return max(Int(size.width), Int(size.height)) * 2
        #else
        return Int(max(size.width * scale, size.height * scale))
        #endif
    }

    static func from(data: Data) -> PlatformImage? {
        #if os(macOS)
        return NSImage(data: data)
        #else
        return UIImage(data: data)
        #endif
    }
}

// MARK: - Safe Array Access
extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

@inline(__always)
func sha256Hex(_ string: String) -> String {
    let data = Data(string.utf8)
    let digest = SHA256.hash(data: data)
    // Views look keys up while they're created, so skip String(format:) per byte.
    let hexDigits = Array("0123456789abcdef".utf8)
    var hex = [UInt8]()
    hex.reserveCapacity(SHA256.byteCount * 2)
    for byte in digest {
        hex.append(hexDigits[Int(byte >> 4)])
        hex.append(hexDigits[Int(byte & 0x0F)])
    }
    return String(decoding: hex, as: UTF8.self)
}

@inline(__always)
func cacheKey(for url: URL) -> String {
    if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
       let queryItems = components.queryItems,
       let originalURL = queryItems.first(where: { $0.name == "url" })?.value {
        return sha256Hex(originalURL)
    }
    return sha256Hex(url.absoluteString)
}
