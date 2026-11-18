//
//  SMVVideoThumbnail.swift
//  SwiftMediaViewer
//

#if os(iOS)
import SwiftUI

/// The placeholder a page shows until its video's first frame is ready.
struct SMVVideoThumbnail: View {
    /// The pixel size thumbnails are decoded at.
    static let targetSize = 1080

    let item: SMVVideoItem

    var body: some View {
        if let thumbnailURL = item.thumbnailURL {
            CachedAsyncImage(url: thumbnailURL, targetSize: Self.targetSize) {
                Color.clear
            }
            .scaledToFit()
            // Centered on the page like the video, whatever the page's own alignment.
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityHidden(true)
        }
    }
}
#endif
