//
//  SMVImage.swift
//  SwiftMediaView (standalone folder to be turned into a Swift Package)
//
//  Minimal image view that renders a remote image and presents a fullscreen
//  gallery when tapped. It applies no visual modifiers; callers control layout
//  (aspectRatio, frame, clipping, cornerRadius, etc.).
//

import SwiftUI
import CachedAsyncImage

public struct SMVImage: View {
    private let url: String
    private let allURLs: [String]
    private let targetSize: Int

    @Namespace private var ns

    @State private var showFullscreen: Bool = false
    @State private var startIndex: Int = 0

    public init(url: String, allURLs: [String]? = nil, targetSize: Int) {
        self.url = url
        self.allURLs = allURLs ?? [url]
        self.targetSize = targetSize
    }

    public var body: some View {
        Group {
            if let u = URL(string: url) {
                CachedAsyncImage(url: u, targetSize: targetSize)
                    #if !os(macOS)
                    .matchedTransitionSource(id: url, in: ns)
                    #endif
                    .contentShape(Rectangle())
                    .onTapGesture {
                        startIndex = allURLs.firstIndex(of: url) ?? 0
                        showFullscreen = true
                    }
            }
        }
        .fullScreenCover(isPresented: $showFullscreen) {
            SMVImageModal(urls: allURLs, startIndex: startIndex, targetSize: targetSize, namespace: ns)
        }
    }
}
