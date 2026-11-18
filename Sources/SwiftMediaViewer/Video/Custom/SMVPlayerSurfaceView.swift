//
//  SMVPlayerSurfaceView.swift
//  SwiftMediaViewer
//

#if os(iOS)
import AVFoundation
import SwiftUI

/// Renders a player in the custom viewer and reports when its first frame is ready.
struct SMVPlayerSurfaceView: UIViewRepresentable {
    let player: AVPlayer?
    let onReadyForDisplayChange: (Bool) -> Void

    func makeUIView(context: Context) -> SMVPlayerSurfaceUIView {
        let view = SMVPlayerSurfaceUIView()
        view.onReadyForDisplayChange = onReadyForDisplayChange
        view.player = player
        return view
    }

    func updateUIView(_ uiView: SMVPlayerSurfaceUIView, context: Context) {
        uiView.onReadyForDisplayChange = onReadyForDisplayChange
        if uiView.player !== player {
            uiView.player = player
        }
    }

    static func dismantleUIView(_ uiView: SMVPlayerSurfaceUIView, coordinator: ()) {
        // Detach so a borrowed inline player isn't kept by an offscreen layer.
        uiView.onReadyForDisplayChange = nil
        uiView.player = nil
    }
}
#endif
