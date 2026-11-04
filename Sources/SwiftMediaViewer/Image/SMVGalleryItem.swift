//
//  SMVGalleryItem.swift
//  SwiftMediaViewer
//

import SwiftUI

/// One image in an ``SMVGallery``'s inline layout. Tapping it opens the
/// gallery's fullscreen viewer on this image, and on iOS the viewer zooms
/// out of it and back into whichever image the user swiped to.
///
/// Outside an `SMVGallery` it does nothing when tapped.
public struct SMVGalleryItem<Label: View>: View {
    let index: Int
    let label: Label

    @Environment(\.smvGalleryContext) private var gallery

    /// - Parameters:
    ///   - index: This image's position in the gallery's `images`.
    ///   - label: How the image appears inline.
    public init(index: Int, @ViewBuilder label: () -> Label) {
        self.index = index
        self.label = label()
    }

    public var body: some View {
        Button {
            gallery?.open(index)
        } label: {
            label
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        #if !os(macOS) && !os(tvOS)
        .modifier(GalleryTransitionSource(id: gallery?.images[safe: index], namespace: gallery?.namespace))
        #endif
    }
}

#if !os(macOS) && !os(tvOS)
/// Marks the item as where the viewer zooms from, once it is inside a gallery.
private struct GalleryTransitionSource: ViewModifier {
    let id: URL?
    let namespace: Namespace.ID?

    func body(content: Content) -> some View {
        if let id, let namespace {
            content.matchedTransitionSource(id: id, in: namespace)
        } else {
            content
        }
    }
}
#endif
