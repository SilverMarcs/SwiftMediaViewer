//
//  SMVGIFView.swift
//  SwiftMediaViewer
//
//  Inline GIF player backed by WebView with optional autoplay and fullscreen zoom.
//

import SwiftUI
#if !os(tvOS)
import WebKit
#endif

public struct SMVGIFView: View {
    private let url: URL
    private let targetSize: Int

    @State private var isPlaying: Bool
    #if !os(tvOS)
    @State private var page: WebPage?
    #endif

    public init(
        url: URL,
        autoplay: Bool = true,
        targetSize: Int = 1000
    ) {
        self.url = url
        self.targetSize = targetSize
        self._isPlaying = State(initialValue: autoplay)
    }

    public var body: some View {
        #if os(tvOS)
        CachedAsyncImage(url: url, targetSize: targetSize)
        #else
        let showGIF = isPlaying

        ZStack {
            placeholderView(isVisible: !showGIF)
            playingView(isVisible: showGIF)
        }
        .task(id: showGIF ? url : nil) {
            guard showGIF else { return }
            await loadPageIfNeeded(for: url)
        }
        #endif
    }

    #if !os(tvOS)
    @ViewBuilder
    private func placeholderView(isVisible: Bool) -> some View {
        CachedAsyncImage(url: url, targetSize: targetSize)
            .opacity(isVisible ? 1 : 0)
            .overlay {
                if isVisible {
                    Image(systemName: "play.fill")
                        .imageScale(.large)
                        .padding()
                        .glassEffect(in: .circle)
                        .foregroundStyle(.white)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                guard isVisible else { return }
                isPlaying = true
            }
    }

    @ViewBuilder
    private func playingView(isVisible: Bool) -> some View {
        if let page, isVisible {
            WebView(page)
                .scrollDisabled(true)
                .webViewBackForwardNavigationGestures(.disabled)
                .webViewMagnificationGestures(.disabled)
                .webViewTextSelection(.disabled)
                .webViewContentBackground(.hidden)
        } else if isVisible {
            ProgressView()
        }
    }

    @MainActor
    private func loadPageIfNeeded(for url: URL) async {
        guard page == nil else { return }

        var configuration = WebPage.Configuration()
        configuration.defaultNavigationPreferences.preferredContentMode = .mobile
        let newPage = WebPage(configuration: configuration)

        let html = """
        <html>
        <head>
        <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
        <style>
        html, body { 
            margin: 0; 
            padding: 0; 
            background: transparent; 
            overflow: hidden;
            width: 100%;
            height: 100%;
        }
        body { 
            display: flex; 
            align-items: center; 
            justify-content: center; 
        }
        img { 
            width: 100%; 
            height: auto; 
            display: block; 
            pointer-events: none;
        }
        </style>
        </head>
        <body>
        <img src="\(url.absoluteString)" alt="gif" />
        </body>
        </html>
        """

        newPage.load(html: html, baseURL: url.deletingLastPathComponent())

        page = newPage
    }
    #endif
}
