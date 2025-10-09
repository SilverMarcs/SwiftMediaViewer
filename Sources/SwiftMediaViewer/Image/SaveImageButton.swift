//
//  SaveImageButton.swift
//  SwiftDdit
//
//  Created by Zabir Raihan on 13/07/2025.
//

import SwiftUI
import Photos

public struct SaveImageButton: View {
    enum ImageSource {
        case url(String)
        case data(Data)
    }
    
    let source: ImageSource
    @State private var isSaved = false
    @State private var isSaving = false
    
    public init(url: String) {
        self.source = .url(url)
    }
    
    public init(data: Data) {
        self.source = .data(data)
    }
    
    public var body: some View {
        Button {
            Task { await saveImage() }
        } label: {
            Image(systemName: isSaved ? "checkmark" : "arrow.down")
                .foregroundStyle(isSaved ? .green : .primary)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .disabled(isSaving || isSaved)
    }
    
    private func saveImage() async {
        guard !isSaving else { return }
        
        isSaving = true
        defer { isSaving = false }
        
        do {
            let image: PlatformImage
            
            switch source {
            case .url(let urlString):
                guard let url = URL(string: urlString) else { return }
                
                // Try cache first
                if let cached = await MemoryCache.shared.get(for: url) {
                    image = cached
                } else {
                    // Download
                    let (data, _) = try await URLSession.shared.data(from: url)
                    guard let downloadedImage = PlatformImage(data: data) else {
                        print("❌ Failed to create image from data")
                        return
                    }
                    image = downloadedImage
                }
                
            case .data(let data):
                guard let dataImage = PlatformImage(data: data) else {
                    print("❌ Failed to create image from data")
                    return
                }
                image = dataImage
            }
            
            // Request authorization and save
            let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            guard status == .authorized else {
                print("❌ Photo library access not authorized")
                return
            }
            
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }
            
            // Show success for 2 seconds
            isSaved = true
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            isSaved = false
            
        } catch {
            print("❌ Failed to save image:", error)
        }
    }
}
