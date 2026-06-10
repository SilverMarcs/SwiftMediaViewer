//
//  CachedAsyncImage.swift
//  SwiftMediaViewer
//
//  Created by Zabir Raihan on 16/07/2025.
//

import SwiftUI

/// Loads and displays a remote image asynchronously.
///
/// A thin wrapper over the system `AsyncImage`. On the 2027 OS releases
/// (iOS 27, macOS 27, tvOS 27 and later) `AsyncImage` applies standard HTTP
/// caching automatically, so there is no custom caching layer here — the system
/// cache and its default `URLSession` configuration do the work.
public struct CachedAsyncImage<Placeholder: View>: View {
    let url: URL?
    let placeholder: () -> Placeholder

    public init(
        url: URL?,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.placeholder = placeholder
    }

    // Default placeholder
    public init(url: URL?) where Placeholder == Color {
        self.url = url
        self.placeholder = { Color(.darkGray).opacity(0.1) }
    }

    public var body: some View {
        AsyncImage(url: url) { image in
            image.resizable()
        } placeholder: {
            placeholder()
        }
    }
}
