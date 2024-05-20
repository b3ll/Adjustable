//
//  DebugAdjustableSlider.swift
//
//
//  Created by Adam Bell on 4/1/24.
//

#if canImport(UIKit)

import Motion
import Foundation
import UIKit

private let MotionBlue = UIColor(red: 0.47, green: 0.80, blue: 0.99, alpha: 1.00)

public class DebugAdjustableSlider: UIView, UIGestureRecognizerDelegate {

    private static var sliders: [DebugAdjustableSlider] = []
    internal static var sliderScrollView = {
        let sliderScrollView = UIScrollView(frame: .zero)
        sliderScrollView.isDirectionalLockEnabled = true
        sliderScrollView.showsHorizontalScrollIndicator = false
        return sliderScrollView
    }()

    internal static var sliderContainer = {
        let sliderContainer = UIView(frame: .zero)
        sliderContainer.layer.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        sliderContainer.layer.borderWidth = 1.0
        sliderContainer.layer.borderColor = UIColor.clear.cgColor
        sliderContainer.backgroundColor = .systemBackground.withAlphaComponent(0.2)
        return sliderContainer
    }()

    typealias OnValueChanged = (_ value: Float) -> Void

    var titleLabel: UILabel
    var title: String? {
        didSet {
            titleLabel.text = title
            setNeedsLayout()
        }
    }

    var valueLabel: UILabel

    var wrappedSlider: UISlider

    var onValueChanged: OnValueChanged?

    init(frame: CGRect = .zero, minimumValue: Float, maximumValue: Float) {
        self.titleLabel = UILabel(frame: .zero)
        self.valueLabel = UILabel(frame: .zero)
        self.wrappedSlider = UISlider(frame: .zero)
        super.init(frame: .zero)

        titleLabel.font = UIFont.preferredFont(forTextStyle: .body)
        titleLabel.numberOfLines = 1
        addSubview(titleLabel)

        valueLabel.font = UIFont.preferredFont(forTextStyle: .body)
        valueLabel.numberOfLines = 1
        addSubview(valueLabel)

        wrappedSlider.addAction(UIAction { [weak self] _ in
            guard let value = self?.wrappedSlider.value else {
                return
            }

            self?.sliderValueChanged(value)
        }, for: .valueChanged)
        wrappedSlider.minimumValue = minimumValue
        wrappedSlider.maximumValue = maximumValue
        wrappedSlider.isContinuous = true
        wrappedSlider.minimumTrackTintColor = MotionBlue
        addSubview(wrappedSlider)

        Self.sliders.append(self)
        Self.mountAndLayoutSliders()

        NotificationCenter.default.addObserver(forName: UIWindow.didBecomeVisibleNotification, object: nil, queue: .main) { notification in
            Self.mountAndLayoutSliders()
        }
    }

    private func sliderValueChanged(_ value: Float) {
        valueLabel.text = String(format: "%.2f", value)
        setNeedsLayout()

        onValueChanged?(value)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        super.layoutSubviews()

        titleLabel.sizeToFit()
        valueLabel.frame.origin = .zero

        valueLabel.sizeToFit()
        valueLabel.frame.origin = CGPoint(x: bounds.size.width - valueLabel.bounds.size.width, y: 0.0)

        let padding = 12.0
        wrappedSlider.frame = CGRect(x: padding, y: 0.0, width: bounds.size.width - (padding * 2.0), height: bounds.size.height)
    }

    public override func sizeThatFits(_ size: CGSize) -> CGSize {
        return CGSize(width: size.width, height: 64.0)
    }

    // MARK: - Sliders Layout

    private static func mountAndLayoutSliders() {
        if sliderScrollView.superview != sliderContainer {
            sliderContainer.addSubview(sliderScrollView)
        }
        sliderContainer.removeFromSuperview()

        if let panGestureRecognizer {
            panGestureRecognizer.view?.removeFromSuperview()
            panGestureRecognizer.view?.removeGestureRecognizer(panGestureRecognizer)
        }

        guard let window = (UIApplication.shared.connectedScenes.first(where: {$0 is UIWindowScene}) as? UIWindowScene)?.windows.first else { return }

        let panGestureRecognizer = panGestureRecognizer ?? UIPanGestureRecognizer(target: self, action: #selector(didDragSliderContainer(gestureRecognizer:)))
        sliderContainer.addGestureRecognizer(panGestureRecognizer)
        panGestureRecognizer.delegate = gestureRecognizerDelegate
        sliderScrollView.panGestureRecognizer.require(toFail: panGestureRecognizer)
        self.panGestureRecognizer = panGestureRecognizer

        let padding = 12.0
        let maxContainerSize = CGSize(width: min(window.bounds.size.width, 400.0) - (2.0 * padding), height: (window.bounds.size.height * 0.5) - (2.0 * padding))

        sliderContainer.bounds = CGRect(x: 0.0, y: 0.0,
                                        width: maxContainerSize.width - (window.safeAreaInsets.left + window.safeAreaInsets.right) - (padding * 2.0),
                                        height: maxContainerSize.height - (window.safeAreaInsets.top + window.safeAreaInsets.bottom) - (padding * 2.0))
                                        sliderContainer.layer.position = CGPoint(x: window.bounds.size.width / 2.0, y: (window.bounds.size.height / 2.0) + window.safeAreaInsets.top + padding)
        sliderContainer.layer.position = CGPoint(x: window.bounds.size.width / 2.0, y: window.safeAreaInsets.top + padding)
        window.addSubview(sliderContainer)

        var sliderYOffset = 0.0
        for slider in sliders {
            slider.removeFromSuperview()

            let sliderSize = slider.sizeThatFits(sliderContainer.bounds.size)
            slider.frame = CGRect(x: 0.0, y: sliderYOffset, width: sliderSize.width, height: sliderSize.height)
            slider.frame.origin.y = sliderYOffset
            sliderScrollView.addSubview(slider)

            sliderYOffset += slider.bounds.size.height + padding
        }

        sliderScrollView.bounds = sliderContainer.bounds
        sliderScrollView.layer.position = CGPoint(x: sliderContainer.bounds.size.width / 2.0, y: sliderContainer.bounds.size.height / 2.0)
        sliderScrollView.contentSize = CGSize(width: sliderContainer.bounds.size.width, height: sliders.last?.frame.maxY ?? 0.0)
    }

    // MARK: - Hide / Show Animations
    
    static var panGestureRecognizer: UIPanGestureRecognizer?

    static private var sliderContainerVisible: Bool = true

    static private let positionSpring = SpringAnimation<CGPoint>(response: 0.6, dampingRatio: 0.9)

    static private var initialSliderContainerPosition: CGPoint = .zero

    static private let gestureRecognizerDelegate = GestureRecognizerDelegate()

    @objc private static func didDragSliderContainer(gestureRecognizer: UIPanGestureRecognizer) {
        guard let superview = sliderContainer.superview else { return }

        let translation = gestureRecognizer.translation(in: superview)

        switch gestureRecognizer.state {
            case .began:
                positionSpring.stop()
                self.initialSliderContainerPosition = sliderContainer.layer.position
                gestureRecognizer.setTranslation(.zero, in: superview)
            case .changed:
                CADisableActions {
                    sliderContainer.layer.position.x = initialSliderContainerPosition.x + translation.x
                    sliderContainer.layer.position.y = initialSliderContainerPosition.y + translation.y
                }
                positionSpring.updateValue(to: sliderContainer.layer.position)
            case .ended, .cancelled:
                positionSpring.onValueChanged { newValue in
                    sliderContainer.layer.position = newValue
                }
                let velocity = gestureRecognizer.velocity(in: superview)
                positionSpring.velocity = velocity

                if abs(velocity.y) > 500.0 {
                    sliderContainerVisible.toggle()
                    toggleSliderContainerVisibility()
                }

                if sliderContainerVisible {
                    positionSpring.toValue = CGPoint(x: (superview.bounds.size.width / 2.0), y: superview.safeAreaInsets.top + 12.0)
                } else {
                    positionSpring.toValue = CGPoint(x: superview.bounds.size.width - (sliderContainer.bounds.size.width / 2.0) - 12.0, y: superview.safeAreaInsets.top + 12.0)
                }
                positionSpring.start()
            default:
                break
        }
    }

    @objc private static func toggleSliderContainerVisibility() {
        let smallContainerSize = CGSize(width: 64.0, height: 64.0)

        let animator = UIViewPropertyAnimator(duration: 0.4, dampingRatio: 1.0)
        animator.addAnimations {
            sliderContainer.backgroundColor = sliderContainerVisible ? UIColor.clear : MotionBlue
            sliderContainer.layer.borderColor = (sliderContainerVisible ? UIColor.clear : UIColor.white.withAlphaComponent(0.2)).cgColor
            sliderContainer.layer.borderWidth = sliderContainerVisible ? 0.0 : 2.0

            sliderContainer.layer.cornerRadius = sliderContainerVisible ? 0.0 : smallContainerSize.width / 2.0
            sliderContainer.layer.shadowOffset = sliderContainerVisible ? .zero : CGSize(width: 0.0, height: 2.0)
            sliderContainer.layer.shadowColor = (sliderContainerVisible ? UIColor.clear : UIColor.black).cgColor
            sliderContainer.layer.shadowRadius = sliderContainerVisible ? 0.0 : 4.0
            sliderContainer.layer.shadowOpacity = sliderContainerVisible ? 0.0 : 0.4

            sliderScrollView.alpha = sliderContainerVisible ? 1.0 : 0.0

            if sliderContainerVisible {
                sliderContainer.layer.transform = CATransform3DIdentity
                sliderContainer.bounds.size = sliderScrollView.bounds.size

                sliderScrollView.layer.transform = CATransform3DIdentity

            } else {
                sliderContainer.bounds.size = smallContainerSize

                let scaleTransform = CATransform3DMakeScale(smallContainerSize.width / sliderScrollView.bounds.size.width, smallContainerSize.height / sliderScrollView.bounds.size.height, 0.0)
                sliderScrollView.layer.transform = scaleTransform
            }
        }
        animator.isInterruptible = true
        animator.startAnimation()
    }

}

internal final class GestureRecognizerDelegate: NSObject, UIGestureRecognizerDelegate {

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let panGestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer else { return true }

        let velocity = panGestureRecognizer.velocity(in: DebugAdjustableSlider.sliderContainer)
        return DebugAdjustableSlider.sliderScrollView.contentOffset.y <= DebugAdjustableSlider.sliderScrollView.contentInset.top && velocity.y > 0.0
    }

}

#endif
