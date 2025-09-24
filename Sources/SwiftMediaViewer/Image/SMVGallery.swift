//
//  SMVGalleryView.swift
//  SwiftMediaViewer
//
//  Created by Zabir Raihan on 25/09/2025.
//

import SwiftUI

public enum SMVGalleryLayout {
    case mainWithThumbs(thumbSize: CGFloat = 80, maxThumbs: Int = 3)
    // Add more layouts later: .grid(columns: Int), .carousel, etc.
}

public struct SMVGallery: View {
    let images: [String] // Just URLs
    let layout: SMVGalleryLayout
    let targetSize: Int
    
    @Namespace private var galleryNamespace
    @State private var showFullscreen = false
    @State private var startIndex = 0
    
    public init(images: [String], layout: SMVGalleryLayout = .mainWithThumbs(), targetSize: Int = 600) {
        self.images = images
        self.layout = layout
        self.targetSize = targetSize
    }
    
    public var body: some View {
        switch layout {
        case .mainWithThumbs(let thumbSize, let maxThumbs):
            mainWithThumbsLayout(thumbSize: thumbSize, maxThumbs: maxThumbs)
        }
    }
    
    @State private var selectedIndex: Int? = nil
    
    @ViewBuilder
    private func mainWithThumbsLayout(thumbSize: CGFloat, maxThumbs: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Main image (first image)
            if let firstURL = images.first, let url = URL(string: firstURL) {
                CachedAsyncImage(url: url, targetSize: targetSize)
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(12)
                    .clipped()
                    .matchedTransitionSource(id: firstURL, in: galleryNamespace)
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
                        
                        if let url = URL(string: imageURL) {
                            CachedAsyncImage(url: url, targetSize: targetSize)
                                .aspectRatio(contentMode: .fill)
                                .frame(width: thumbSize, height: thumbSize)
                                .cornerRadius(8)
                                .clipped()
                                .matchedTransitionSource(id: imageURL, in: galleryNamespace)
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
        }
        .fullScreenCover(item: $selectedIndex) { index in
            SMVImageModal(
                urls: images,
                startIndex: index,
                targetSize: targetSize,
                namespace: galleryNamespace
            )
        }
    }
}

extension Int: Identifiable { public var id: Int { self } }
