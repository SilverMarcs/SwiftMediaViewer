//
//  SMVImageDataModal.swift
//

import SwiftUI

public struct SMVImageDataModal: View {
    let dataItems: [Data]
    let startIndex: Int
    let namespace: Namespace.ID
    let sourceID: String

    @State private var currentIndex: Int

    public init(dataItems: [Data], startIndex: Int = 0, namespace: Namespace.ID, sourceID: String) {
        self.dataItems = dataItems
        self.startIndex = min(max(0, startIndex), max(0, dataItems.count - 1))
        self.namespace = namespace
        self.sourceID = sourceID
        self._currentIndex = State(initialValue: self.startIndex)
    }

    public var body: some View {
        #if os(macOS)
        ZStack {
            if let currentData = dataItems[safe: currentIndex],
               let image = PlatformImage.from(data: currentData) {
                Image(platformImage: image)
                    .resizable()
                    .scaledToFit()
                    .zoomable()
            }

            HStack {
                Button(action: previousImage) { Image(systemName: "chevron.left") }
                    .controlSize(.extraLarge)
                    .buttonStyle(.glass)
                    .buttonBorderShape(.circle)
                    .disabled(currentIndex == 0)

                Spacer()

                Button(action: nextImage) { Image(systemName: "chevron.right") }
                    .controlSize(.extraLarge)
                    .buttonStyle(.glass)
                    .buttonBorderShape(.circle)
                    .disabled(currentIndex == dataItems.count - 1)
            }
            .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        #else
        TabView(selection: $currentIndex) {
            ForEach(Array(dataItems.enumerated()), id: \.offset) { index, data in
                if let image = PlatformImage.from(data: data) {
                    Image(platformImage: image)
                        .resizable()
                        .scaledToFit()
                        .zoomable()
                        .tag(index)
                }
            }
        }
        .ignoresSafeArea()
        .tabViewStyle(.page)
        .navigationTransition(.zoom(sourceID: sourceID, in: namespace))
        #endif
    }

    private func nextImage() { guard currentIndex < dataItems.count - 1 else { return }; currentIndex += 1 }
    private func previousImage() { guard currentIndex > 0 else { return }; currentIndex -= 1 }
}
