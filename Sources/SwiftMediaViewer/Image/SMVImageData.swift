//
//  SMVImageData.swift
//  SwiftMediaViewer
//
//  Minimal single image view that renders image data and presents fullscreen when tapped.
//

import SwiftUI

public struct SMVImageData: View {
    private let data: Data
    private let id: String

    @Namespace private var imageNamespace
    @State private var showFullscreen = false

    public init(data: Data, id: String = UUID().uuidString) {
        self.data = data
        self.id = id
    }

    public var body: some View {
        Group {
            if let image = PlatformImage.from(data: data) {
                Image(platformImage: image)
                    .resizable()
                    #if !os(macOS)
                    .matchedTransitionSource(id: id, in: imageNamespace)
                    #endif
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showFullscreen = true
                    }
            }
        }
        .conditionalFullScreen(isPresented: $showFullscreen) {
            SMVImageDataModal(
                dataItems: [data],
                startIndex: 0,
                namespace: imageNamespace,
                sourceID: id
            )
        }
    }
}
