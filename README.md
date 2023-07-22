<picture>
  <img src="https://raw.githubusercontent.com/kejinlu/SwiftyUploader/main/assets/logo.svg" alt="SwiftyUploader logo" height="70">
</picture>

---

<p align="center">
      English | <a href="README.zh_CN.md">中文<a/>
</p>

# Overview
SwiftyUploader is a file upload server for iOS platform implemented based on SwiftNIO. If your iOS App needs to upload files from a computer or another phone to your App, you can use this library to quickly implement this feature. The Web page part of SwiftyUploader uses the code from [GCDWebUploader](https://github.com/swisspol/GCDWebServer/tree/master/GCDWebUploader/GCDWebUploader.bundle/Contents/Resources).

<picture>
  <img src="https://raw.githubusercontent.com/kejinlu/SwiftyUploader/main/assets/webui1.png" alt="SwiftyUploader logo" width="70%">
</picture>

# Usage

## Requirements

- iOS 14.0+
- Xcode 14.3
- Swift 5.8

## Integration
You can use The Swift Package Manager for integration. Or you can enter `https://github.com/kejinlu/SwiftyUploader.git` in the dependency window in Xcode to add dependencies, or directly use local dependencies for testing.

```swift
// swift-tools-version:5.8
import PackageDescription

let package = Package(
    name: "YOUR_PROJECT_NAME",
    dependencies: [
        .package(url: "https://github.com/kejinlu/SwiftyUploader.git", from: "0.0.1"),
    ]
)
```
Then run `swift build` whenever you get prepared.

## Code

```swift
let uploader = SwiftyUploader()
uploader.run()
```

If you need web page support for international languages, you need to add the following settings in the app's info.plist

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleAllowMixedLocalizations</key>
    <true/>
</dict>
</plist>
```

