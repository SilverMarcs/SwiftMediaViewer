//
//  SMVImage.swift
//  SwiftMediaViewer
//
//  Single or multiple image view that renders remote images and presents fullscreen when tapped.
//

import SwiftUI

public struct SMVImage: View {
    private let url: URL

    @Namespace private var imageNamespace
    @State private var showFullscreen = false

    public init(url: URL) {
        self.url = url
    }

    public var body: some View {
        CachedAsyncImage(url: url)
            #if !os(macOS) && !os(tvOS)
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
                    namespace: imageNamespace
                )
            }
        
    }
}
