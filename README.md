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

SMVImage(url: "https://example.com/image.jpg", targetSize: 600)
```

- Gallery: `SMVGallery` provides the fullscreen viewer and swiping between images; the inline layout is yours. Wrap each image in `SMVGalleryItem` so tapping it opens the viewer on that image:

```swift
SMVGallery(images: urls, targetSize: 600) {
    LazyVGrid(columns: [GridItem(), GridItem()]) {
        ForEach(urls.indices, id: \.self) { index in
            SMVGalleryItem(index: index) {
                CachedAsyncImage(url: urls[index], targetSize: 600)
                    .scaledToFill()
                    .frame(height: 120)
                    .clipped()
            }
        }
    }
}
```

- Inline video view:

```swift
SMVVideo(videoURL: "https://example.com/video.mp4")
```

- Programmatic presentation (e.g., from a button tap):

```swift
struct ContentView: View {
    @State private var presenter = SMVImagePresenter()

    var body: some View {
        VStack {
            Button("Show Images") {
                presenter.present(urls: ["https://.../1.jpg", "https://.../2.jpg"], targetSize: 600)
            }
        }
        .smvImageGateway(presenter: presenter)
    }
}
```

See source files under `Sources/SwiftMediaViewer` for more customization points.
