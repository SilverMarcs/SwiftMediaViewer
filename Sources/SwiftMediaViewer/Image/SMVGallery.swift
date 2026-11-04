//
//  SMVGallery.swift
//  SwiftMediaViewer
//
//  Created by Zabir Raihan on 25/09/2025.
//

import SwiftUI

/// A set of images that open in one fullscreen viewer, where the user swipes
/// between them.
///
/// The gallery owns the viewer; the app owns the inline layout. Lay the
/// images out however you like in `content`, and wrap each one in an
/// ``SMVGalleryItem`` so tapping it opens the viewer on that image:
///
/// ```swift
/// SMVGallery(images: urls) {
///     LazyVGrid(columns: columns) {
///         ForEach(urls.indices, id: \.self) { index in
///             SMVGalleryItem(index: index) {
///                 CachedAsyncImage(url: urls[index], targetSize: 600)
///                     .scaledToFill()
///             }
///         }
///     }
/// }
/// ```
public struct SMVGallery<Content: View>: View {
    let images: [URL]
    let targetSize: Int
    let content: Content

    @Namespace private var galleryNamespace
    @State private var selectedIndex: Int?

    /// - Parameters:
    ///   - images: Every image the viewer pages through, in order.
    ///   - targetSize: The decode size, in pixels, for the viewer's images.
    ///   - content: The inline layout. Wrap each image in an ``SMVGalleryItem``.
    public init(images: [URL], targetSize: Int = 600, @ViewBuilder content: () -> Content) {
        self.images = images
        self.targetSize = targetSize
        self.content = content()
    }

    public var body: some View {
        content
            .environment(\.smvGalleryContext, SMVGalleryContext(images: images, namespace: galleryNamespace) { index in
                selectedIndex = index
            })
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
