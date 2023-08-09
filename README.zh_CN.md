<picture>
  <img src="https://raw.githubusercontent.com/kejinlu/SwiftyUploader/main/assets/logo.svg" alt="SwiftyUploader logo" height="70">
</picture>

---

<p align="center">
      <a href="README.md">English<a/> | 中文
</p>

# 概述
SwiftyUploader是一个iOS平台上的基于 SwiftNIO 实现的文件上传服务器.如果你的iOS App 需要从电脑上或者别的手机上传文件到你的 App，你可以使用此库快速实现此功能。
SwiftyUploader的Web页面部分使用了 [GCDWebUploader](https://github.com/swisspol/GCDWebServer/tree/master/GCDWebUploader/GCDWebUploader.bundle/Contents/Resources)的代码。

<picture>
  <img src="https://raw.githubusercontent.com/kejinlu/SwiftyUploader/main/assets/webui1.png" alt="SwiftyUploader logo" width="70%">
</picture>


# 使用

## 要求

- iOS 14.0+
- Xcode 14.3
- Swift 5.8

## 集成
你可以使用 [The Swift Package Manager](https://swift.org/package-manager) 进行集成，如果仅仅测试的可以在 Xcode 中添加依赖的窗口中输入 `https://github.com/kejinlu/SwiftyUploader.git` 添加依赖，或者直接使用本地依赖的方式进行测试。

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

## 代码

启动服务器:

```swift
let uploader = SwiftyUploader()

DispatchQueue.global().async {
    do {
        try uploader.run()
    } catch {
        DispatchQueue.main.async {
            print("Failed to start server: \(error)")
        }
        return
    }
}
```

停止服务器:

```swift
DispatchQueue.global().async {
    do {
        try uploader.stop()
    } catch {
        DispatchQueue.main.async {
            print("Failed to stop server: \(error)")
        }
        return
    }
}
```

如果你需要 web 界面支持自适应的国际化语言，需要在 app 的 info.plist中增加下面的设置

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

