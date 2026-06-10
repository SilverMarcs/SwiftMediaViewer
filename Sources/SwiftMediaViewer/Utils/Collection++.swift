//
//  Collection++.swift
//  SwiftMediaViewer
//
//  Created by Zabir Raihan on 09/06/2026.
//

import Foundation

// MARK: - Safe Array Access
extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
