//
//  Adjustable.swift
//
//
//  Created by Adam Bell on 4/1/24.
//

#if canImport(UIKit)

import Combine
import Foundation
import UIKit

/**
 A property wrapper for `UIView` that will adjust a given value by use of a `UISlider`.
 - Note: This relies on `AdjustableInvalidation` to be implemented on the owning class. Defaults are provided for `UIView` and `UIViewController`.

 ```
 class SomeView: UIView {

 @Adjustable(in: 0.0...100.0) var subviewPadding: CGFloat = 0.0

 }
 ```
 */

public protocol AdjustableInvalidation {

    func invalidateForAdjustable()

}

extension UIView: AdjustableInvalidation {

    @objc open func invalidateForAdjustable() {
        setNeedsLayout()
    }

}


extension UIViewController: AdjustableInvalidation {

    @objc open func invalidateForAdjustable() {
        viewIfLoaded?.setNeedsLayout()
    }

}

public protocol AdjustableSupportedValue: BinaryFloatingPoint {}

extension Float: AdjustableSupportedValue {}
extension Double: AdjustableSupportedValue {}

@propertyWrapper
public final class Adjustable<Value> where Value: AdjustableSupportedValue {

    // Would like to make this just `AdjustableInvalidation`, but that makes things tricky with supporting ObservableObject.
    public typealias ViewType = AnyObject
    public typealias ValueChanged = (_ enclosingSelf: AdjustableInvalidation, _ value: Value) -> Void

    @Published private var value: Value
    private var debugSlider: AdjustableSlider
    private var targetToInvalidate: AnyObject?

    private var title: String?
    private var valueChanged: ValueChanged?

    // Heavily inspired by the work done by ebg here: https://forums.swift.org/t/property-wrappers-access-to-both-enclosing-self-and-wrapper-instance/32526
    public static subscript<EnclosingSelf>(
        _enclosingInstance instance: EnclosingSelf,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Adjustable>
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
        get { return value }
        set { self.value = newValue }
    }

    public var projectedValue: Published<Value>.Publisher {
        get { return $value }
        set { $value = newValue }
    }

    public init(wrappedValue: Value, _ valueRange: ClosedRange<Value> = 0.0...100.0, title: String? = nil, valueChanged: ValueChanged? = nil) {
        self.value = wrappedValue
        self.valueChanged = valueChanged
        self.debugSlider = AdjustableSlider(frame: .zero, minimumValue: Float(valueRange.lowerBound), maximumValue: Float(valueRange.upperBound))
        debugSlider.title = title
        debugSlider.onValueChanged = { [weak self] value in
            self?.value = Value(value)
            (self?.targetToInvalidate as? AdjustableInvalidation)?.invalidateForAdjustable()

            if let observableObject = self?.targetToInvalidate as? (any ObservableObject) {
                if let objectWillChange = (observableObject.objectWillChange as any Publisher) as? ObservableObjectPublisher {
                    objectWillChange.send()
                }
            }

            if let targetToInvalidate = self?.targetToInvalidate, let valueChanged = self?.valueChanged, let targetToInvalidate = targetToInvalidate as? AdjustableInvalidation {
                valueChanged(targetToInvalidate, Value(value))
            }
        }
        debugSlider.wrappedSlider.value = Float(wrappedValue)
    }

}

#endif
