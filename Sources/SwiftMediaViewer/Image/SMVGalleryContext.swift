//
//  SMVGalleryContext.swift
//  SwiftMediaViewer
//

import SwiftUI

/// What an ``SMVGalleryItem`` needs from its enclosing ``SMVGallery``.
struct SMVGalleryContext {
    let images: [URL]
    let namespace: Namespace.ID
    let open: (Int) -> Void
}

extension EnvironmentValues {
    /// Nil outside an ``SMVGallery``.
    @Entry var smvGalleryContext: SMVGalleryContext?
}
