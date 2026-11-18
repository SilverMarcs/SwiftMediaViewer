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

Page dots are shown by default. Pass `showsPageIndicator: false` to `SMVGallery`
to hide them while keeping swipe navigation. `SMVImageModal` accepts the same
option for direct presentation. This option has no effect on macOS or tvOS,
which use previous/next buttons instead of page dots.

- Inline video view:

```swift
SMVVideo(videoURL: "https://example.com/video.mp4")
```

Tapping the video opens AVKit's player by default (`viewer: .native`).

### Custom video viewer (iOS)

An endless, vertically paging video viewer, presented as a full-screen cover
that zooms out of the tapped video. Your navigation and tab bars stay as they
are underneath. It draws only the video; you choose whether it has a scrubber
and overlay anything else yourself.

- Single tap: show or hide the controls.
- Double-tap the center: play or pause.
- Double-tap the left or right edge: skip 5 seconds (keep tapping to add more).
- Hold an edge: play at 2× until you let go.
- Swipe up or down: next or previous video. Swipe down on the first video, or
  pinch in, to close. The volume buttons control the sound.

Only the current video holds a player. Each video loads when you swipe to it, and the previous one is released.

**1. Open it** from an inline video (reuses its player and zooms out of it):

```swift
SMVVideo(videoURL: url, viewer: .custom(itemID: post.id, scrubber: .withControls,
                                        feed: { MyVideoFeed() }) { page in
    // Optional: your own content per page, laid out above the scrubber.
    if page.isShowingControls {
        SaveButton(id: page.item.id)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
    }
})
```

`scrubber` is `.withControls` (line shown with the controls, always draggable),
`.always`, or `.none`. The overlay closure gets an `SMVVideoPageContext`
(`item`, `isCurrent`, `isShowingControls`); empty space passes touches through.

or from anything else, by presenting a route:

```swift
@State private var route: SMVVideoViewerRoute?

content
    .smvVideoViewer(item: $route, scrubber: .withControls) { page in /* overlay */ }

// To open (the zoom source is optional):
route = SMVVideoViewerRoute(item: SMVVideoItem(id: post.id, url: videoURL),
                            feed: { MyVideoFeed() },
                            sourceID: post.id, namespace: ns)
```

**2. Supply more videos** (optional) with an `SMVVideoFeed`. The viewer asks
when the person nears the end, never twice at once, drops duplicates, and stops
when you return `[]`. The closure runs on every opening, so state starts fresh.

```swift
@MainActor
final class MyVideoFeed: SMVVideoFeed {
    func nextVideos() async throws -> [SMVVideoItem] {
        try await api.nextVideoPosts().map {
            SMVVideoItem(id: $0.id, url: $0.videoURL, thumbnailURL: $0.thumbnailURL, title: $0.author)
        }
    }
}
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
