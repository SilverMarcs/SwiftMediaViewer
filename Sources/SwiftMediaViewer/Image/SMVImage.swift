//
//  SMVImage.swift
//  SwiftMediaViewer
//
//  Single or multiple image view that renders remote images and presents fullscreen when tapped.
//

import SwiftUI

public struct SMVImage: View {
    private let url: URL
    private let targetSize: Int

    @Namespace private var imageNamespace
    @State private var showFullscreen = false

    public init(url: URL, targetSize: Int) {
        self.url = url
        self.targetSize = targetSize
    }

    public var body: some View {
        CachedAsyncImage(url: url, targetSize: targetSize)
            #if !os(macOS)
            .matchedTransitionSource(id: url, in: imageNamespace)
            #endif
            .contentShape(Rectangle())
            .onTapGesture {
                showFullscreen = true
            }
            .conditionalFullScreen(isPresented: $showFullscreen) {
                SMVImageModal(
                    urls: [url],
                    startIndex: 0,
                    targetSize: targetSize,
                    namespace: imageNamespace
                )
            }
        
    }
}
