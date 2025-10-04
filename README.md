# SwiftMediaViewer

SwiftMediaViewer is a lightweight, reusable Swift utility to present and navigate media (images, videos) in iOS apps. It provides a simple, Swift-native viewer with zooming, panning, and basic playback support.

## Features
- Image viewing with pinch-to-zoom and double-tap to zoom
- Video playback support
- Simple API with minimal setup
- Swift 5 / iOS 13+ compatibility

## Requirements
- Swift 5
- iOS 13.0+

## Installation
### Swift Package Manager
Add this repository as a Swift Package to your project:

1. In Xcode select File → Add Packages...
2. Enter: https://github.com/SilverMarcs/SwiftMediaViewer
3. Choose the version or branch you want (Default: main)

### Manual
- Clone or copy the source files from this repo into your project.

## Usage
Import the package/module and present the viewer with an array of media items.

```swift
import SwiftMediaViewer

let urls: [URL] = [/* image/video URLs */]
let viewer = MediaViewerController(items: urls, startIndex: 0)
present(viewer, animated: true)
```

Check the source for configuration options (transition style, start index, dismiss behavior).

## Examples
See the `Example` folder (if present) or run the sample app target in this repo for a complete usage example.

## Contributing
Contributions, issues and feature requests are welcome. Feel free to open an issue or submit a pull request.

## License
This project is licensed under the MIT License - see the LICENSE file for details.

## Contact
Created by SilverMarcs. If you have questions or feedback open an issue or contact me via my GitHub profile.
