//
//  View++.swift
//  SwiftMediaViewer
//
//  Created by Zabir Raihan on 25/09/2025.
//

import SwiftUI

extension View {
    @ViewBuilder
    func conditionalFullScreen<Content: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        #if os(macOS)
        self.sheet(isPresented: isPresented, content: content)
        #else
        self.fullScreenCover(isPresented: isPresented, content: content)
        #endif
    }
    
    @ViewBuilder
    func conditionalFullScreen<Item: Identifiable, Content: View>(
        item: Binding<Item?>,
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
        #if os(macOS)
        self.sheet(item: item, content: content)
        #else
        self.fullScreenCover(item: item, content: content)
        #endif
    }
}
