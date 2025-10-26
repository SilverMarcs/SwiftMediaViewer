//
//  SMVGalleryView.swift
//  SwiftMediaViewer
//
//  Created by Zabir Raihan on 25/09/2025.
//

import SwiftUI

public struct SMVGallery: View {
    let images: [URL] // Just URLs
    let targetSize: Int
    
    @Namespace private var galleryNamespace
    @State private var showFullscreen = false
    @State private var startIndex = 0
    @State private var selectedIndex: Int? = nil
    
    public init(images: [URL], targetSize: Int = 600) {
        self.images = images
        self.targetSize = targetSize
    }
    
    public var body: some View {
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
                let displayImages = Array(remainingImages.prefix(3))
                let remainingCount = remainingImages.count - displayImages.count
                
                HStack(spacing: 8) {
                    ForEach(Array(displayImages.enumerated()), id: \.offset) { thumbIndex, imageURL in
                        let actualIndex = thumbIndex + 1 // +1 because we skipped first image
                        
                        CachedAsyncImage(url: imageURL, targetSize: targetSize)
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 80)
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
}
