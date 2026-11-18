//
//  SMVZoomTransition.swift
//  SwiftMediaViewer
//

#if os(iOS)
import SwiftUI

/// Applies a zoom navigation transition when there's a source to zoom from.
struct SMVZoomTransition: ViewModifier {
    let sourceID: String?
    let namespace: Namespace.ID?

    func body(content: Content) -> some View {
        if let sourceID, let namespace {
            content.navigationTransition(.zoom(sourceID: sourceID, in: namespace))
        } else {
            content
        }
    }
}
#endif
