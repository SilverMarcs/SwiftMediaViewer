//
//  SMVGalleryData.swift
//  SwiftMediaViewer
//
//  Created by Zabir Raihan on 25/09/2025.
//

import SwiftUI

public struct SMVGalleryData: View {
    let dataItems: [Data]
    let layout: SMVGalleryLayout
    
    @Namespace private var galleryNamespace
    @State private var selectedIndex: Int? = nil
    private let galleryID: String
    
    public init(
        dataItems: [Data],
        layout: SMVGalleryLayout = .mainWithThumbs()
    ) {
        self.dataItems = dataItems
        self.layout = layout
        self.galleryID = UUID().uuidString
    }
    
    public var body: some View {
        switch layout {
        case .mainWithThumbs(let thumbSize, let maxThumbs):
            mainWithThumbsLayout(thumbSize: thumbSize, maxThumbs: maxThumbs)
        case .adaptiveGrid(let minimum, let spacing, let showsIndicators):
            adaptiveGridLayout(
                minimum: minimum,
                spacing: spacing,
                showsIndicators: showsIndicators
            )
        }
    }
    
    // MARK: - Layouts
    
    @ViewBuilder
    private func mainWithThumbsLayout(thumbSize: CGFloat, maxThumbs: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Main image (first image)
            if let firstData = dataItems.first,
               let image = PlatformImage.from(data: firstData) {
                Image(platformImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(12)
                    .clipped()
                    #if !os(macOS)
                    .matchedTransitionSource(id: "\(galleryID)-0", in: galleryNamespace)
                    #endif
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedIndex = 0
                    }
            }
            
            // Thumbnails (remaining images)
            if dataItems.count > 1 {
                let remainingData = Array(dataItems.dropFirst())
                let displayData = Array(remainingData.prefix(maxThumbs))
                let remainingCount = remainingData.count - displayData.count
                
                HStack(spacing: 8) {
                    ForEach(Array(displayData.enumerated()), id: \.offset) { thumbIndex, data in
                        let actualIndex = thumbIndex + 1 // +1 because we skipped first image
                        
                        if let image = PlatformImage.from(data: data) {
                            Image(platformImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: thumbSize, height: thumbSize)
                                .cornerRadius(8)
                                .clipped()
                                #if !os(macOS)
                                .matchedTransitionSource(id: "\(galleryID)-\(actualIndex)", in: galleryNamespace)
                                #endif
                                .contentShape(Rectangle())
                                .overlay {
                                    if thumbIndex == displayData.count - 1 && remainingCount > 0 {
                                        Rectangle()
                                            .fill(.black.opacity(0.6))
                                            .cornerRadius(8)
                                            .overlay {
                                                Text("+\(remainingCount)")
                                                    .font(.headline)
                                                    .fontWeight(.semibold)
                                                    .foregroundStyle(.white)
                                            }
                                    }
                                }
                                .onTapGesture {
                                    selectedIndex = actualIndex
                                }
                        }
                    }
                }
            }
        }
        .conditionalFullScreen(item: $selectedIndex) { index in
            SMVImageDataModal(
                dataItems: dataItems,
                startIndex: index,
                namespace: galleryNamespace,
                sourceID: galleryID
            )
        }
    }
    
    @ViewBuilder
    private func adaptiveGridLayout(
        minimum: CGFloat,
        spacing: CGFloat,
        showsIndicators: Bool,
    ) -> some View {
        ScrollView(showsIndicators: showsIndicators) {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: minimum))], spacing: spacing) {
                ForEach(Array(dataItems.enumerated()), id: \.offset) { index, data in
                    if let image = PlatformImage.from(data: data) {
                        Image(platformImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                            .clipped()
                            .aspectRatio(1, contentMode: .fit)
                            .cornerRadius(12)
                            #if !os(macOS)
                            .matchedTransitionSource(id: "\(galleryID)-\(index)", in: galleryNamespace)
                            #endif
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedIndex = index
                            }
                    }
                }
            }
        }
        .conditionalFullScreen(item: $selectedIndex) { index in
            SMVImageDataModal(
                dataItems: dataItems,
                startIndex: index,
                namespace: galleryNamespace,
                sourceID: galleryID
            )
        }
    }
}
