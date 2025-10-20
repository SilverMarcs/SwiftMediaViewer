//
//  SMVImageData.swift
//  SwiftMediaViewer
//
//  Single or multiple image view that renders image data and presents fullscreen when tapped.
//

import SwiftUI

public struct SMVImageData: View {
    private let dataItems: [Data]
    private let id: String

    @Namespace private var imageNamespace
    @State private var showFullscreen = false

    public init(data: Data, id: String = UUID().uuidString) {
        self.dataItems = [data]
        self.id = id
    }

    public init(dataItems: [Data], id: String = UUID().uuidString) {
        self.dataItems = dataItems
        self.id = id
    }

    public var body: some View {
        if let firstData = dataItems.first, let image = PlatformImage.from(data: firstData) {
            Image(platformImage: image)
                .resizable()
#if !os(macOS)
                .matchedTransitionSource(id: id, in: imageNamespace)
#endif
                .contentShape(Rectangle())
                .onTapGesture {
                    showFullscreen = true
                }
                .overlay(alignment: .bottomTrailing) {
                    if dataItems.count > 1 {
                        Text("+\(dataItems.count - 1)")
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
                    SMVImageDataModal(
                        dataItems: dataItems,
                        startIndex: 0,
                        namespace: imageNamespace,
                        sourceID: id
                    )
                }
        }
    }
}
