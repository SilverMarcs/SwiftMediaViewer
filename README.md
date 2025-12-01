# SwiftMediaViewer

A lightweight SwiftUI package for presenting remote images and videos with optional fullscreen, thumbnails and simple caching.

Requirements
- Swift tools version: 6.2
- Platforms: iOS 18+, macOS 15+

Installation
- Xcode: File > Add Packages... and add `https://github.com/SilverMarcs/SwiftMediaViewer.git`
- Package.swift example:

```swift
.package(url: "https://github.com/SilverMarcs/SwiftMediaViewer.git", from: "1.0.0")
```

Quick examples
- Import and use a single image:

```swift
import SwiftUI
import SwiftMediaViewer

SMVImage(
    url: URL(string: "https://example.com/image.jpg")!,
    targetSize: 600
)
```

- Gallery with thumbnails:

```swift
SMVGallery(
    images: [
        URL(string: "https://.../1.jpg")!,
        URL(string: "https://.../2.jpg")!,
        URL(string: "https://.../3.jpg")!
    ]
)
```

- Inline video view:

```swift
SMVVideo(videoURL: "https://example.com/video.mp4")
```

- Programmatic presentation (e.g., from a button tap):

```swift
struct ContentView: View {
    var body: some View {
        VStack {
            Button("Show Images") {
                guard let url = URL(string: "https://.../1.jpg") else { return }
                SMVImagePresenter.shared.present(url: url, targetSize: 600)
            }
        }
    }
}
```

See source files under `Sources/SwiftMediaViewer` for more customization points.
