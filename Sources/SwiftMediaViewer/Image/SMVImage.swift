//
//  SMVImage.swift
//  SwiftMediaViewer
//
//  Single or multiple image view that renders remote images and presents fullscreen when tapped.
//

import SwiftUI

public struct SMVImage: View {
    private let urls: [String]
    private let targetSize: Int

    @Namespace private var imageNamespace
    @State private var showFullscreen = false

    public init(url: String, targetSize: Int) {
        self.urls = [url]
        self.targetSize = targetSize
    }

    public init(urls: [String], targetSize: Int) {
        self.urls = urls
        self.targetSize = targetSize
    }

    public var body: some View {
        if let firstURL = urls.first, let u = URL(string: firstURL) {
            CachedAsyncImage(url: u, targetSize: targetSize)
                #if !os(macOS)
                .matchedTransitionSource(id: firstURL, in: imageNamespace)
                #endif
                .contentShape(Rectangle())
                .onTapGesture {
                    showFullscreen = true
                }
                .overlay(alignment: .bottomTrailing) {
                    if urls.count > 1 {
                        Text("+\(urls.count - 1)")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(8)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(6)
                            .padding(12)
                    }
                }
                .conditionalFullScreen(isPresented: $showFullscreen) {
                    SMVImageModal(
                        urls: urls,
                        startIndex: 0,
                        targetSize: targetSize,
                        namespace: imageNamespace
                    )
                }
        }
    }
}
