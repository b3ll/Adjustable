//
//  AdjustableSlider.swift
//
//
//  Created by Adam Bell on 4/1/24.
//

#if canImport(UIKit)

import Motion
import Foundation
import UIKit

private let MotionBlue = UIColor(red: 0.0, green: 212.0/255.0, blue: 1.0, alpha: 1.0)

public class AdjustableSlider: UIView, UIGestureRecognizerDelegate {

    enum DockedCorner: CaseIterable {
        case topLeading
        case topTrailing
        case bottomLeading
        case bottomTrailing
    }

    private static var dockedCornerPoints: [DockedCorner: CGPoint] = [:]

    private static var sliders: [AdjustableSlider] = []
    internal static var sliderScrollView = {
        let sliderScrollView = UIScrollView(frame: .zero)
        sliderScrollView.isDirectionalLockEnabled = true
        sliderScrollView.showsHorizontalScrollIndicator = false
        return sliderScrollView
    }()

    internal static var sliderContainer = {
        let sliderContainer = UIView(frame: .zero)
        sliderContainer.layer.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        sliderContainer.backgroundColor = .clear
        return sliderContainer
    }()

    private static var sliderContainerBackground = {
        let sliderContainerBackground = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
        sliderContainerBackground.alpha = 0.0
        sliderContainerBackground.isUserInteractionEnabled = false
        sliderContainerBackground.layer.masksToBounds = true
        return sliderContainerBackground
    }()

    private static let smallContainerSize = CGSize(width: 64.0, height: 64.0)

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
        Self.updateSliderContainerVisibility(animated: false)

        NotificationCenter.default.addObserver(forName: UIWindow.didBecomeVisibleNotification, object: nil, queue: .main) { notification in
            Self.mountAndLayoutSliders()
            Self.updateSliderContainerVisibility(animated: false)
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
        if sliderContainerBackground.superview != sliderContainer {
            sliderContainer.addSubview(sliderContainerBackground)
        }

        if sliderScrollView.superview != sliderContainer {
            sliderContainer.addSubview(sliderScrollView)
        }
        sliderContainer.removeFromSuperview()

        if let panGestureRecognizer {
            panGestureRecognizer.view?.removeFromSuperview()
            panGestureRecognizer.view?.removeGestureRecognizer(panGestureRecognizer)
        }

        if let tapGestureRecognizer {
            tapGestureRecognizer.view?.removeFromSuperview()
            tapGestureRecognizer.view?.removeGestureRecognizer(tapGestureRecognizer)
        }

        guard let window = (UIApplication.shared.connectedScenes.first(where: {$0 is UIWindowScene}) as? UIWindowScene)?.windows.first else { return }

        let panGestureRecognizer = panGestureRecognizer ?? UIPanGestureRecognizer(target: self, action: #selector(didDragSliderContainer(gestureRecognizer:)))
        sliderContainer.addGestureRecognizer(panGestureRecognizer)
        panGestureRecognizer.delegate = gestureRecognizerDelegate
        sliderScrollView.panGestureRecognizer.require(toFail: panGestureRecognizer)
        self.panGestureRecognizer = panGestureRecognizer

        let tapGestureRecognizer = tapGestureRecognizer ?? UITapGestureRecognizer(target: self, action: #selector(didTapSliderContainer(gestureRecognizer:)))
        sliderContainer.addGestureRecognizer(tapGestureRecognizer)
        self.tapGestureRecognizer = tapGestureRecognizer

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

        sliderContainerBackground.bounds = sliderContainer.bounds
        sliderContainerBackground.layer.position = sliderScrollView.layer.position

        generateDockedCornerPoints(within: window)
    }

    private static func generateDockedCornerPoints(within view: UIView) {
        self.dockedCornerPoints = DockedCorner.allCases.enumerated().reduce(into: [DockedCorner: CGPoint]()) { corners, corner in
            let inset = 24.0
            let safeAreaInsets = view.safeAreaInsets

            var cornerPoint = CGPoint(x: inset, y: view.safeAreaInsets.top + inset)

            switch corner.element {
                case .topLeading:
                    break
                case .topTrailing:
                    cornerPoint.x = view.bounds.size.width - inset
                case .bottomLeading:
                    cornerPoint.y = view.bounds.size.height - safeAreaInsets.bottom - (smallContainerSize.width) - inset
                case .bottomTrailing:
                    cornerPoint.x = view.bounds.size.width - inset
                    cornerPoint.y = view.bounds.size.height - safeAreaInsets.bottom - (smallContainerSize.width) - inset
            }

            corners[corner.element] = cornerPoint
        }
    }

    // MARK: - Hide / Show Animations
    
    static private var dockedCorner: DockedCorner = .topTrailing

    static var panGestureRecognizer: UIPanGestureRecognizer?
    static var tapGestureRecognizer: UITapGestureRecognizer?

    static internal var sliderContainerVisible: Bool = true

    static private let positionSpring = SpringAnimation<CGPoint>(response: 0.6, dampingRatio: 0.9)

    static private var initialSliderContainerPosition: CGPoint = .zero

    static private let gestureRecognizerDelegate = GestureRecognizerDelegate()

    @objc private static func didTapSliderContainer(gestureRecognizer: UITapGestureRecognizer) {
        switch gestureRecognizer.state {
            case .ended:
                if !sliderContainerVisible {
                    sliderContainerVisible.toggle()
                    updateSliderContainerVisibility()

                    updateSliderContainerPosition(with: .zero)
                }
            default:
                break
        }
    }

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
                updateSliderContainerPosition(with: velocity)
            default:
                break
        }
    }

    private static func updateSliderContainerPosition(with velocity: CGPoint) {
        guard let superview = sliderContainer.superview else { return }

        if sliderContainerVisible {
            // Collapsing container
            if abs(velocity.y) > 500.0 {
                sliderContainerVisible.toggle()
                updateSliderContainerVisibility()
            }

            positionSpring.toValue = CGPoint(x: (superview.bounds.size.width / 2.0), y: superview.safeAreaInsets.top + 12.0)
        } else {
            // Docking Container
            let decayFunction = DecayFunction<CGPoint>()
            let destination = decayFunction.solveToValue(value: sliderContainer.layer.position, velocity: velocity)

            let closestCorner = dockedCornerPoints.sorted { a, b -> Bool in
                let distanceA = a.value.distance(to: destination)
                let distanceB = b.value.distance(to: destination)
                return distanceA < distanceB
            }.first!

            self.dockedCorner = closestCorner.key

            positionSpring.toValue = closestCorner.value
        }

        positionSpring.velocity = velocity
        positionSpring.start()
    }

    @objc private static func updateSliderContainerVisibility(animated: Bool = true) {
        let animations = {
            sliderContainerBackground.layer.cornerCurve = .continuous
            sliderContainerBackground.layer.cornerRadius = sliderContainerVisible ? 0.0 : smallContainerSize.width / 2.0

            sliderContainer.layer.cornerRadius = sliderContainerVisible ? 0.0 : smallContainerSize.width / 2.0
            sliderContainer.layer.shadowOffset = sliderContainerVisible ? .zero : CGSize(width: 0.0, height: 2.0)
            sliderContainer.layer.shadowColor = (sliderContainerVisible ? UIColor.clear : UIColor.black).cgColor
            sliderContainer.layer.shadowRadius = sliderContainerVisible ? 0.0 : 4.0
            sliderContainer.layer.shadowOpacity = sliderContainerVisible ? 0.0 : 0.3

            sliderScrollView.alpha = sliderContainerVisible ? 1.0 : 0.0

            if sliderContainerVisible {
                sliderContainer.layer.transform = CATransform3DIdentity
                sliderContainer.bounds.size = sliderScrollView.bounds.size

                sliderScrollView.layer.transform = CATransform3DIdentity
                sliderScrollView.layer.position = CGPoint(x: sliderContainer.bounds.size.width / 2.0, y: sliderContainer.bounds.size.height / 2.0)

                sliderContainerBackground.frame = sliderContainer.bounds
                sliderContainerBackground.alpha = 0.0
            } else {
                sliderContainer.bounds.size = smallContainerSize

                let scaleTransform = CATransform3DMakeScale(smallContainerSize.width / sliderScrollView.bounds.size.width, smallContainerSize.height / sliderScrollView.bounds.size.height, 0.0)
                sliderScrollView.layer.transform = scaleTransform
                sliderScrollView.layer.position = CGPoint(x: sliderContainer.bounds.size.width / 2.0, y: sliderContainer.bounds.size.height / 2.0)

                sliderContainerBackground.frame = sliderContainer.bounds
                sliderContainerBackground.alpha = 1.0
            }
        }

        if !animated {
            CADisableActions {
                animations()
            }
            return
        }

        let animator = UIViewPropertyAnimator(duration: 0.4, dampingRatio: 1.0)
        animator.addAnimations {
            animations()
        }
        animator.isInterruptible = true
        animator.startAnimation()
    }

}

fileprivate extension CGPoint {

    func distance(to point: CGPoint) -> CGFloat {
        return sqrt(pow(point.x - x, 2.0) + pow(point.y - y, 2.0))
    }

}

internal final class GestureRecognizerDelegate: NSObject, UIGestureRecognizerDelegate {

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let panGestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer, AdjustableSlider.sliderContainerVisible else { return true }

        let velocity = panGestureRecognizer.velocity(in: AdjustableSlider.sliderContainer)
        return AdjustableSlider.sliderScrollView.contentOffset.y <= AdjustableSlider.sliderScrollView.contentInset.top && velocity.y > 0.0
    }

}

#endif
