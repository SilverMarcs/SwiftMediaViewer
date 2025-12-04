//
//  SMVImageModal.swift
//

import SwiftUI

public struct SMVImageModal: View {
    let urls: [URL]
    let startIndex: Int
    let targetSize: Int
    let namespace: Namespace.ID

    @State private var currentIndex: Int

    public init(urls: [URL], startIndex: Int = 0, targetSize: Int, namespace: Namespace.ID) {
        self.urls = urls
        self.startIndex = min(max(0, startIndex), max(0, urls.count - 1))
        self.targetSize = targetSize
        self.namespace = namespace
        self._currentIndex = State(initialValue: self.startIndex)
    }

    private var sourceID: URL {
        guard currentIndex < urls.count else { return urls.first ?? URL(string: "")! }
        return urls[currentIndex]
    }

     public var body: some View {
         #if os(macOS) || os(tvOS)
         if let currentURL = urls[safe: currentIndex] {
             CachedAsyncImage(url: currentURL, targetSize: 50)
                 .zoomable()
                 .frame(maxWidth: .infinity)
                 .overlay {
                     if urls.count > 1 {
                         HStack {
                             Button(action: previousImage) { Image(systemName: "chevron.left") }
                                 #if os(tvOS)
                                 .buttonStyle(.bordered)
                                 #else
                                 .controlSize(.extraLarge)
                                 .buttonStyle(.glass)
                                 .buttonBorderShape(.circle)
                                 #endif
                                 .disabled(currentIndex == 0)
                             
                             Spacer()
                             
                             Button(action: nextImage) { Image(systemName: "chevron.right") }
                                 #if os(tvOS)
                                 .buttonStyle(.bordered)
                                 #else
                                 .controlSize(.extraLarge)
                                 .buttonStyle(.glass)
                                 .buttonBorderShape(.circle)
                                 #endif
                                 .disabled(currentIndex == urls.count - 1)
                         }
                         .padding(.horizontal)
                     }
                 }
         }
         #else
         TabView(selection: $currentIndex) {
             ForEach(Array(urls.enumerated()), id: \.offset) { index, s in
                 CachedAsyncImage(url: s, targetSize: targetSize)
                     .aspectRatio(contentMode: .fit)
                     .zoomable()
                     .tag(index)
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
