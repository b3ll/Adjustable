![DebugAdjustable-Logo](https://github.com/b3ll/DebugAdjustable/blob/main/Resources/DebugAdjustableLogo.png?raw=true)

This package provides property wrappers that can be used on properties for any value conforming to `ClosedRange` to allow for super fast iteration of UIs without the need to recompile an application. It does so by automatically an interactive slider for any property that you annotate with `@DebugAdjustable` that sits on top of your app's window so you can dynamically adjust properties and see them update live. It's powered by a lot of the stuff I experimented with to make [SetNeedsDisplay](https://github.com/b3ll/SetNeedsDisplay).

It uses a lot of neat runtime tricks to pull out the name of the variable so it can appropriately name the relevant slider and also features a collapsible menu that you can tuck away when you don't need it (powered by [Motion](https://www.github.com/b3ll/Motion)!). 

> [!Note]
> This is designed really to only be used when developing applications and shouldn't be left in production builds.

> [!Warning]
> This code contains some private Swift API stuff that powers `@Published` so there's a strong likelihood this will break in the future. I'd like to figure out ways to make the API a lot nicer in general, so if you have any ideas, let me know!

- [DebugAdjustable](#debugadjustable)
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
    // Anytime the slider is changed, `invalidateForDebugAdjustable()` is called on the enclosing class.
    @DebugAdjustable(0.0...100.0) var someCustomProperty: Double = 20.0

    // A slider from `0.0` to `100.0` starting at `20.0` will be created.
    // Anytime the slider is changed, the `valueChanged` block is called with an instance of `self` that you can reference as well as the new value.
    @DebugAdjustable(0.0...100.0, valueChanged: { enclosingSelf, newValue in
      // access `self` via `enclosingSelf`
      // do what you want with `newValue
    }) var someOtherCustomProperty: Double = 20.0

    override func invalidateForDebugAdjustable() {
      print("someCustomProperty: \(someCustomProperty)")
      print("someOtherCustomProperty: \(someOtherCustomProperty)")
    }

}
```

You can also use `@Published`!

```swift
class MyCoolClass {
  
  @DebugAdjustable(0.0...100.0) var somePublishedProperty: Double = 20.0

  var publishedCancellable: AnyCancellable?

  init() {
    self.publishedCancellable = $someProperty.sink { newValue in 
      print("somePublishedProperty: \(somePublishedProperty)")
    }
  }
  
}
```

Anytime any slider is adjusted, `invalidateForDebugAdjustable` will be called on the enclosing class. This by default calls `setNeedsLayout` on `UIView` and `UIViewController`'s view, but this can be overridden and used to update the view's state or perform any action, really. There's also an inline block that can be supplied that contains an instance of the enclosing class (`enclosingSelf`) as well as the new value from the slider.

One thing I use it for is layout constants that are referenced in `layoutSubviews`. Adjusting the slider will change the value, invalidate layout, and call `layoutSubviews` which makes iteration really easy.

# Installation

## Requirements

- iOS 17+
- Swift 5.9 or higher

Currently DebugAdjustable supports Swift Package Manager (or manually adding `DebugAdjustable.swift` to your project).

## Swift Package Manager

Add the following to your `Package.swift` (or add it via Xcode's GUI):

```swift
.package(url: "https://github.com/b3ll/DebugAdjustable", from: "0.0.1")
```

# License

DebugAdjustable is licensed under the [BSD 2-clause license](https://github.com/b3ll/DebugAdjustable/blob/master/LICENSE).

# Thanks

Thanks to [@harlanhaskins](https://twitter.com/harlanhaskins) and [@hollyborla](https://twitter.com/hollyborla) for helping point me in the right direction and explain the complexity that this sort of solution entails.

More info [here](https://forums.swift.org/t/property-wrappers-access-to-both-enclosing-self-and-wrapper-instance/32526).

# Contact Info

Feel free to follow me on twitter: [@b3ll](https://www.twitter.com/b3ll)!
