//
//  CachedAsyncImage.swift
//  CachedAsyncImage
//
//  Created by Zabir Raihan on 16/07/2025.
//

import SwiftUI

/// A SwiftUI view that loads and displays images asynchronously with automatic caching.
public struct CachedAsyncImage<Placeholder: View>: View {
    let url: URL?
    let targetSize: Int
    let placeholder: () -> Placeholder

    @State private var image: PlatformImage?
    /// The URL `image` shows, so a cached image isn't loaded a second time.
    @State private var loadedURL: URL?

    public init(
        url: URL?,
        targetSize: Int,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.targetSize = targetSize
        self.placeholder = placeholder
        // Lazy stacks recreate a row's state each time it scrolls back into
        // view. Starting from the memory cache shows the image in the first
        // frame, instead of a placeholder and a second render once an async
        // lookup returns.
        let cached = url.flatMap { MemoryCache.shared.image(for: $0, atLeast: targetSize) }
        _image = State(initialValue: cached)
        _loadedURL = State(initialValue: cached == nil ? nil : url)
    }

    // Default placeholder
    public init(url: URL?, targetSize: Int) where Placeholder == Color {
        self.init(url: url, targetSize: targetSize) {
            Color(.darkGray).opacity(0.1)
        }
    }

    public var body: some View {
        Group {
            if let image = image {
                #if os(macOS)
                Image(nsImage: image).resizable()
                #else
                Image(uiImage: image).resizable()
                #endif
            } else {
                placeholder()
            }
        }
        .task(id: url) {
            guard let url else {
                image = nil
                loadedURL = nil
                return
            }
            if loadedURL == url, image != nil { return }
            if let cached = MemoryCache.shared.image(for: url, atLeast: targetSize) {
                image = cached
                loadedURL = url
                return
            }
            let loaded = try? await ImageLoader.loadAndGetImage(url: url, targetSize: targetSize)
            image = loaded
            loadedURL = loaded == nil ? nil : url
        }
    }
}
