//
//  SMVGalleryView.swift
//  SwiftMediaViewer
//
//  Created by Zabir Raihan on 25/09/2025.
//

import SwiftUI

public struct SMVGallery: View {
    let images: [URL] // Just URLs
    let layout: SMVGalleryLayout
    let targetSize: Int
    
    @Namespace private var galleryNamespace
    @State private var showFullscreen = false
    @State private var startIndex = 0
    @State private var selectedIndex: Int? = nil
    
    public init(
        images: [URL],
        layout: SMVGalleryLayout = .mainWithThumbs(),
        targetSize: Int = 600
    ) {
        self.images = images
        self.layout = layout
        self.targetSize = targetSize
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
            if let firstURL = images.first {
                CachedAsyncImage(url: firstURL, targetSize: targetSize)
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(12)
                    .clipped()
                    #if !os(macOS)
                    .matchedTransitionSource(id: firstURL, in: galleryNamespace)
                    #endif
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedIndex = 0
                    }
            }
            
            // Thumbnails (remaining images)
            if images.count > 1 {
                let remainingImages = Array(images.dropFirst())
                let displayImages = Array(remainingImages.prefix(maxThumbs))
                let remainingCount = remainingImages.count - displayImages.count
                
                HStack(spacing: 8) {
                    ForEach(Array(displayImages.enumerated()), id: \.offset) { thumbIndex, imageURL in
                        let actualIndex = thumbIndex + 1 // +1 because we skipped first image
                        
                        CachedAsyncImage(url: imageURL, targetSize: targetSize)
                            .aspectRatio(contentMode: .fill)
                            .frame(width: thumbSize, height: thumbSize)
                            .cornerRadius(8)
                            .clipped()
                            #if !os(macOS)
                            .matchedTransitionSource(id: imageURL, in: galleryNamespace)
                            #endif
                            .contentShape(Rectangle())
                            .overlay {
                                if thumbIndex == displayImages.count - 1 && remainingCount > 0 {
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
        .conditionalFullScreen(item: $selectedIndex) { index in
            SMVImageModal(
                urls: images,
                startIndex: index,
                targetSize: targetSize,
                namespace: galleryNamespace
            )
        }
    }
    
    @ViewBuilder
    private func adaptiveGridLayout(
        minimum: CGFloat,
        spacing: CGFloat,
        showsIndicators: Bool
    ) -> some View {
        ScrollView(showsIndicators: showsIndicators) {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: minimum))], spacing: spacing) {
                ForEach(Array(images.enumerated()), id: \.offset) { index, imageURL in
                    CachedAsyncImage(url: imageURL, targetSize: targetSize)
                        // Make items square and cropped to fill the cell
                        .aspectRatio(1, contentMode: .fill)
                        .cornerRadius(12)
                        .clipped()
                        #if !os(macOS)
                        .matchedTransitionSource(id: imageURL, in: galleryNamespace)
                        #endif
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedIndex = index
                        }
                }
            }
        }
        .conditionalFullScreen(item: $selectedIndex) { index in
            SMVImageModal(
                urls: images,
                startIndex: index,
                targetSize: targetSize,
                namespace: galleryNamespace
            )
        }
    }
}
