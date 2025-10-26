//
//  SMVGalleryLayout.swift
//  SwiftMediaViewer
//
//  Created by Zabir Raihan on 26/10/2025.
//

import SwiftUI

public enum SMVGalleryLayout {
    case mainWithThumbs(thumbSize: CGFloat = 80, maxThumbs: Int = 3)
    case adaptiveGrid(
        minimum: CGFloat = 150,
        spacing: CGFloat = 12,
        showsScrollIndicators: Bool = false,
    )
}
