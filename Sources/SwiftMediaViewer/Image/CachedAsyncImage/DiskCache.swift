//
//  DiskCache.swift
//  CachedAsyncImage
//
//  Created by Zabir Raihan on 16/07/2025.
//

import Foundation

public actor DiskCache {
    public static let shared = DiskCache()
    private let fileManager = FileManager.default
    
    static let maxSize = 1024 * 1024 * 150

    private var cacheDirectory: URL? {
        fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first?
            .appendingPathComponent("ImageCacher")
    }

    private func createCacheDirectoryIfNeeded() {
        guard let cacheDirectory = cacheDirectory else { return }
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    private func fileURL(for url: URL) -> URL? {
        guard let dir = cacheDirectory else { return nil }
        return dir.appendingPathComponent(cacheKey(for: url))
    }

    private func checkDiskCacheSize() async {
        guard let cacheDirectory = cacheDirectory else { return }

        do {
            let files = try fileManager.contentsOfDirectory(
                at: cacheDirectory,
                includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey],
                options: []
            )

            var totalSize: Int64 = 0
            var fileInfos: [(url: URL, size: Int64, date: Date)] = []

            for fileURL in files {
                let attributes = try fileURL.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey])
                let size = Int64(attributes.fileSize ?? 0)
                let date = attributes.contentModificationDate ?? .distantPast
                totalSize += size
                fileInfos.append((url: fileURL, size: size, date: date))
            }

            if totalSize > Self.maxSize {
                fileInfos.sort { $0.date < $1.date }
                var sizeToRemove = totalSize - Int64(Self.maxSize)
                for info in fileInfos where sizeToRemove > 0 {
                    try? fileManager.removeItem(at: info.url)
                    sizeToRemove -= info.size
                }
            }
        } catch {
            print("Failed to manage disk cache size: \(error)")
        }
    }

    public func store(_ data: Data, for url: URL) {
        createCacheDirectoryIfNeeded()
        guard let fileURL = fileURL(for: url) else { return }
        try? data.write(to: fileURL, options: .atomic)

        if Int.random(in: 0...10) == 0 {
            Task { await checkDiskCacheSize() }
        }
    }

    public func retrieve(for url: URL) -> Data? {
        createCacheDirectoryIfNeeded()
        guard let fileURL = fileURL(for: url) else { return nil }
        return try? Data(contentsOf: fileURL)
    }

    public func clearCache() {
        guard let cacheDirectory = cacheDirectory else { return }
        try? fileManager.removeItem(at: cacheDirectory)
        createCacheDirectoryIfNeeded()
    }

    public func cleanupIfNeeded() async {
        await checkDiskCacheSize()
    }

    public func getDiskCacheSize() async -> Int64 {
        guard let cacheDirectory = cacheDirectory else { return 0 }
        
        do {
            let files = try fileManager.contentsOfDirectory(
                at: cacheDirectory,
                includingPropertiesForKeys: [.fileSizeKey],
                options: []
            )
            
            var totalSize: Int64 = 0
            for fileURL in files {
                let attributes = try fileURL.resourceValues(forKeys: [.fileSizeKey])
                totalSize += Int64(attributes.fileSize ?? 0)
            }
            
            return totalSize
        } catch {
            return 0
        }
    }
}
