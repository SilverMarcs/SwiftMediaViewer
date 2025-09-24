//
//  SMVImage.swift
//  SwiftMediaViewer
//
//  Minimal single image view that renders a remote image and presents fullscreen when tapped.
//

import SwiftUI

public struct SMVImage: View {
    private let url: String
    private let targetSize: Int

    @Namespace private var imageNamespace
    @State private var showFullscreen = false

    public init(url: String, targetSize: Int) {
        self.url = url
        self.targetSize = targetSize
    }

    public var body: some View {
        Group {
            if let u = URL(string: url) {
                CachedAsyncImage(url: u, targetSize: targetSize)
                    #if !os(macOS)
                    .matchedTransitionSource(id: url, in: imageNamespace)
                    #endif
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showFullscreen = true
                    }
            }
        }
        .conditionalFullScreen(isPresented: $showFullscreen) {
            SMVImageModal(
                urls: [url], // Single image array
                startIndex: 0,
                targetSize: targetSize,
                namespace: imageNamespace
            )
        }
    }
}
