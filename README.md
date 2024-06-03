<p align="center">
    <img width="640pt" src="https://github.com/b3ll/Adjustable/blob/main/Resources/AdjustableLogo.png?raw=true">
</p>

<p align="center">
    <img src="https://github.com/b3ll/Adjustable/blob/main/Resources/DemoVideo.gif?raw=true">
</p>

This package provides property wrappers that can be used on properties for any value conforming to `ClosedRange` to allow for super fast iteration of UIs and interactions without the need to wait to recompile / relaunch an application. It does so by automatically adding an interactive slider for any property that you annotate with `@Adjustable` that sits on top of your app's window so you can dynamically adjust properties and see them update live. It's powered by a lot of the stuff I experimented with to make [SetNeedsDisplay](https://github.com/b3ll/SetNeedsDisplay).

This is *perfect* for adjusting animation parameters on-the-fly, tweaking constants, or refining things until they feel just right without needing to constantly recompile your app and allowing you to focus on making things feel great.

It uses a lot of neat runtime tricks to pull out the name of the variable so it can appropriately name the relevant slider and also features a collapsible menu that you can tuck away when you don't need it (powered by [Motion](https://www.github.com/b3ll/Motion)!). 

> [!Note]
> This is designed to only be used when developing applications and shouldn't be left in production builds. I would also not recommend annotating everything in your codebase with `@Adjustable` as this project isn't really built to scale (yet).

> [!Warning]
> This code contains some private Swift API stuff that powers `@Published` so there's a strong likelihood this will break in the future. I'd like to figure out ways to make the API a lot nicer in general, so if you have any ideas, let me know!

- [Usage](#usage)
- [Installation](#installation)
  - [Requirements](#requirements)
  - [Swift Package Manager](#swift-package-manager)
- [License](#license)
- [Thanks](#thanks)
- [Contact Info](#contact-info)

# Usage

Annotate your property of a type that conforms to `ClosedRange` like so:

```swift
class MyView: UIView {

    // A slider from `0.0` to `100.0` starting at `20.0` will be created.
    // Anytime the slider is changed, `invalidateForAdjustable()` is called on the enclosing class.
    @Adjustable(0.0...100.0) var someCustomProperty: Double = 20.0

    // A slider from `0.0` to `100.0` starting at `20.0` will be created.
    // Anytime the slider is changed, the `valueChanged` block is called with an instance of `self` that you can reference as well as the new value.
    @Adjustable(0.0...100.0, valueChanged: { enclosingSelf, newValue in
      // access `self` via `enclosingSelf`
      // do what you want with `newValue
    }) var someOtherCustomProperty: Double = 20.0

    override func invalidateForAdjustable() {
      print("someCustomProperty: \(someCustomProperty)")
      print("someOtherCustomProperty: \(someOtherCustomProperty)")
    }

}
```

You can also use `@Published`!

```swift
class MyCoolClass {
  
  @Adjustable(0.0...100.0) var somePublishedProperty: Double = 20.0

  var publishedCancellable: AnyCancellable?

  init() {
    self.publishedCancellable = $someProperty.sink { newValue in 
      print("somePublishedProperty: \(somePublishedProperty)")
    }
  }
  
}
```

It also works in SwiftUI!

```swift
class Model: ObservableObject {

  @Adjustable(0.0...255.0) var somePublishedProperty: Double = 20.0

}

struct MyView: View {
  
  @StateObject var model = Model()

  var body: some View {
    Rectangle()
      .foregroundColor(Color(hue: model.colourOffset / 255.0, saturation: 1.0, brightness: 1.0))
  }
  
}
```

Anytime any slider is adjusted, `invalidateForAdjustable` will be called on the enclosing class. This by default calls `setNeedsLayout` on `UIView` and `UIViewController`'s view, but this can be overridden and used to update the view's state or perform any action, really. There's also an inline block that can be supplied that contains an instance of the enclosing class (`enclosingSelf`) as well as the new value from the slider. `ObservableObject` invalidation is also supported and it will automatically call the correct `objectWillChange` event.

If you wish to override the default invalidation behaviour of `UIView` or `UIViewController` you can adopt the `AdjustableInvalidation` protocol:

```swift
import Motion

class MyView: UIView {

  @Adjustable(0.0...1.0) private var springResponse: Double = 0.5

  var springAnimation = SpringAnimation<CGFloat>(response: 0.5, damping: 1.0)

  func invalidateForAdjustable() {
      springAnimation.configure(response: springResponse, damping: 1.0)
  }

}
```

I've saved a lot of time using `Adjustable` in conjunction with [Motion](https://github.com/b3ll/Motion) for rapid iteration of animation constants (e.g. springs). I'll try an animation, tweak it, try it again, and tweak it some more etc. Once finished, I'll update the constant inline and remove the `@Adjustable`. This saves *so* much time and allows you to focus on adjusting interactions to feel as best they can be (instead of waiting for Xcode to build and run again).

Another thing I use it for is layout constants that are referenced in `layoutSubviews`. Adjusting the slider will change the value, invalidate layout automatically (via `setNeedsLayout`), and call `layoutSubviews` which makes iteration really easy.

> [!Note]
> Similar ideas for "hot-reloading" projects exist: [InjectionIII](https://github.com/johnno1962/InjectionIII) / [Inject](https://github.com/krzysztofzablocki/Inject), as well as SwiftUI Previews, and while they're great tools, I felt like adjusting via sliders allows you to really focus on the feel of things moreso than waiting for delta compilations / injections (as well as more stable than relying on injection of dylibs to not break things haha).

# Installation

## Requirements

- iOS 17+
- Swift 5.9 or higher

Currently Adjustable supports Swift Package Manager.

## Swift Package Manager

Add the following to your `Package.swift` (or add it via Xcode's GUI):

```swift
.package(url: "https://github.com/b3ll/Adjustable", from: "0.0.1")
```

# License

Adjustable is licensed under the [BSD 2-clause license](https://github.com/b3ll/Adjustable/blob/master/LICENSE).

# Thanks

Thanks to [@harlanhaskins](https://twitter.com/harlanhaskins) and [@hollyborla](https://twitter.com/hollyborla) for helping point me in the right direction and explain the complexity that this sort of solution entails.

More info [here](https://forums.swift.org/t/property-wrappers-access-to-both-enclosing-self-and-wrapper-instance/32526).

# Contact Info

Feel free to follow me on Mastodon: [@b3ll](https://www.mastodon.social/@b3ll)!
