//
//  SMVImageModal.swift
//

import SwiftUI

public struct SMVImageModal: View {
    let urls: [String]
    let startIndex: Int
    let targetSize: Int
    let namespace: Namespace.ID

    @State private var currentIndex: Int

    public init(urls: [String], startIndex: Int = 0, targetSize: Int, namespace: Namespace.ID) {
        self.urls = urls
        self.startIndex = min(max(0, startIndex), max(0, urls.count - 1))
        self.targetSize = targetSize
        self.namespace = namespace
        self._currentIndex = State(initialValue: self.startIndex)
    }

    private var sourceID: String {
        guard currentIndex < urls.count else { return urls.first ?? "" }
        return urls[currentIndex]
    }

    public var body: some View {
        #if os(macOS)
        ZStack {
            if let currentURL = URL(string: urls[safe: currentIndex] ?? "") {
                CachedAsyncImage(url: currentURL, targetSize: 50)
                    .zoomable()
                    .overlay(alignment: .bottomTrailing) {
                        SaveImageButton(url: urls[safe: currentIndex] ?? "")
                            .padding()
                    }
            }

            HStack {
                Button(action: previousImage) { Image(systemName: "chevron.left") }
                    .controlSize(.extraLarge)
//                    .buttonStyle(.glass)
                    .disabled(currentIndex == 0)

                Spacer()

                Button(action: nextImage) { Image(systemName: "chevron.right") }
                    .controlSize(.extraLarge)
//                    .buttonStyle(.glass)
                    .disabled(currentIndex == urls.count - 1)
            }
            .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        #else
        TabView(selection: $currentIndex) {
            ForEach(Array(urls.enumerated()), id: \.offset) { index, s in
                if let u = URL(string: s) {
                    CachedAsyncImage(url: u, targetSize: targetSize)
                        .aspectRatio(contentMode: .fit)
                        .zoomable()
                        .overlay(alignment: .bottomTrailing) {
                            SaveImageButton(url: s)
                                .padding()
                        }
                        .tag(index)
                        
                }
            }
        }
        .ignoresSafeArea()
        .tabViewStyle(.page)
        .navigationTransition(.zoom(sourceID: sourceID, in: namespace))
        #endif
    }

    private func nextImage() { guard currentIndex < urls.count - 1 else { return }; currentIndex += 1 }
    private func previousImage() { guard currentIndex > 0 else { return }; currentIndex -= 1 }
}
