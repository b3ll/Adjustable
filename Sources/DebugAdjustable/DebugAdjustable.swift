//
//  DebugAdjustable.swift
//
//
//  Created by Adam Bell on 4/1/24.
//

#if canImport(UIKit)

import Foundation
import UIKit

/**
 A property wrapper for `UIView` that will adjust a given value by use of a `UISlider`.
 - Note: This relies on `DebugAdjustableInvalidation` to be implemented on the owning class. Defaults are provided for `UIView` and `UIViewController`.

 ```
 class SomeView: UIView {

 @DebugAdjustable(in: 0.0...100.0) var subviewPadding: CGFloat = 0.0

 }
 ```
 */

public protocol DebugAdjustableInvalidation {

    func invalidateForDebugAdjustable()

}

extension UIView: DebugAdjustableInvalidation {

    @objc open func invalidateForDebugAdjustable() {
        setNeedsLayout()
    }

}


extension UIViewController: DebugAdjustableInvalidation {

    @objc open func invalidateForDebugAdjustable() {
        viewIfLoaded?.setNeedsLayout()
    }

}

public protocol DebugAdjustableSupportedValue: BinaryFloatingPoint {}

extension Float: DebugAdjustableSupportedValue {}
extension Double: DebugAdjustableSupportedValue {}

@propertyWrapper
public final class DebugAdjustable<Value> where Value: DebugAdjustableSupportedValue {

    public typealias ViewType = DebugAdjustableInvalidation
    public typealias ValueChanged = (_ enclosingSelf: DebugAdjustableInvalidation, _ value: Value) -> Void

    private var stored: Value
    private var debugSlider: DebugAdjustableSlider
    private var targetToInvalidate: ViewType?

    private var title: String?
    private var valueChanged: ValueChanged?

    // Heavily inspired by the work done by ebg here: https://forums.swift.org/t/property-wrappers-access-to-both-enclosing-self-and-wrapper-instance/32526
    public static subscript<EnclosingSelf>(
        _enclosingInstance instance: EnclosingSelf,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<EnclosingSelf, DebugAdjustable>
    ) -> Value where EnclosingSelf: ViewType {
        get {
            // Configure on the getter since it's called anytime the value is accessed (including initially)
            instance[keyPath: storageKeyPath].targetToInvalidate = instance

            let debugSlider = instance[keyPath: storageKeyPath].debugSlider
            if debugSlider.title == nil {
                debugSlider.title = storageKeyPath.debugDescription.components(separatedBy: ".").last?.replacingOccurrences(of: "_", with: "")
            }

            return Value(debugSlider.wrappedSlider.value)
        }
        set {
            let debugSlider = instance[keyPath: storageKeyPath].debugSlider

            let oldValue = Value(debugSlider.wrappedSlider.value)

            if newValue != oldValue {
                debugSlider.wrappedSlider.value = Float(oldValue)
            }
        }
    }

    public var wrappedValue: Value {
        get { fatalError("called wrappedValue getter") }
        set { fatalError("called wrappedValue setter") }
    }

    public init(wrappedValue: Value, _ valueRange: ClosedRange<Value> = 0.0...100.0, title: String? = nil, valueChanged: ValueChanged? = nil) {
        self.stored = wrappedValue
        self.valueChanged = valueChanged
        self.debugSlider = DebugAdjustableSlider(frame: .zero, minimumValue: Float(valueRange.lowerBound), maximumValue: Float(valueRange.upperBound))
        debugSlider.title = title
        debugSlider.onValueChanged = { [weak self] value in
            self?.targetToInvalidate?.invalidateForDebugAdjustable()
            if let targetToInvalidate = self?.targetToInvalidate, let valueChanged = self?.valueChanged {
                valueChanged(targetToInvalidate, Value(value))
            }
        }
        debugSlider.wrappedSlider.value = Float(wrappedValue)
    }

}

#endif
