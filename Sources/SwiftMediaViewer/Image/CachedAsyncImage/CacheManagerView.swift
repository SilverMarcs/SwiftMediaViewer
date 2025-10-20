//
//  CacheManagerView.swift
//  CachedAsyncImage
//
//  Created by Zabir Raihan on 20/10/2025.
//

import SwiftUI

public struct CacheManagerView: View {
    @State private var deleteAlertPresented = false
    @State private var diskCacheSize: Int64 = 0
    
    public init() {}
    
    public var body: some View {
        Button {
            deleteAlertPresented = true
        } label: {
            Label {
                Text("Clear Image Cache")
                if diskCacheSize > 0 {
                    Text(formatBytes(diskCacheSize))
                }
            } icon: {
                Image(systemName: "trash")
            }
            .contentShape(.rect)
        }
        #if os(macOS)
        .buttonStyle(.plain)
        #endif
        .alert("Clear Image Cache", isPresented: $deleteAlertPresented) {
            Button("Clear", role: .destructive) {
                CachedAsyncImageConfiguration.clearAllCaches()
                Task {
                    diskCacheSize = await DiskCache.shared.getDiskCacheSize()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will clear all cached images, freeing up storage space.")
        }
        .task {
            diskCacheSize = await DiskCache.shared.getDiskCacheSize()
        }
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: bytes)
    }
}

#Preview {
    CacheManagerView()
        .padding()
}
