//
//  ViewController.swift
//  DebugAdjustableDemo
//
//  Created by Adam Bell on 4/1/24.
//

import DebugAdjustable
import UIKit

public let MotionBlue = UIColor(red: 0.47, green: 0.80, blue: 0.99, alpha: 1.00)

import Combine

class DemoView: UIView {

    @DebugAdjustable(24...144.0, title: "square.size") var squareSize: Double = 44

    @DebugAdjustable(0.0...100.0) var sourceCopyCount: Double = 0.0
    @DebugAdjustable(-200...200.0) var sourceInstanceTransformX: Double = 0.0
    @DebugAdjustable(-200...200.0) var sourceInstanceTransformY: Double = 0.0

    @DebugAdjustable(0.0...100.0) var copyCopyCount: Double = 0.0
    @DebugAdjustable(-200...200.0) var copyInstanceTransformX: Double = 0.0
    @DebugAdjustable(-200...200.0) var copyInstanceTransformY: Double = 0.0

    @DebugAdjustable(-200...200.0, valueChanged: { enclosingSelf, value in
        print(enclosingSelf)
        print(value)
    }) var testPrint: Double = 0.0

    @DebugAdjustable(-10...10.0) var somePublishedValue: Double = 0.0

    let adjustableSquare = CALayer()

    let secondaryReplicatorLayer = CAReplicatorLayer()

    override class var layerClass: AnyClass {
        CAReplicatorLayer.self
    }

    private var replicatorLayer: CAReplicatorLayer {
        return layer as! CAReplicatorLayer
    }

    var publishedValueCancellable: AnyCancellable?

    override init(frame: CGRect) {
        super.init(frame: .zero)

        _ = testPrint

        adjustableSquare.backgroundColor = MotionBlue.cgColor

        let animation = CABasicAnimation()
        animation.fromValue = 0.2
        animation.toValue = 1.0
        animation.repeatCount = .infinity
        animation.autoreverses = true
        animation.duration = 2.0
        animation.fillMode = .backwards
        animation.isRemovedOnCompletion = false
        animation.keyPath = "opacity"
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        adjustableSquare.add(animation, forKey: "opacity")

        secondaryReplicatorLayer.addSublayer(adjustableSquare)

        let delay: TimeInterval = 0.1
        replicatorLayer.instanceDelay = delay
        secondaryReplicatorLayer.instanceDelay = delay * 2.0

        layer.addSublayer(secondaryReplicatorLayer)

        self.publishedValueCancellable = $somePublishedValue.sink(receiveValue: { newValue in
            print("Published: \(newValue)")
        })
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        secondaryReplicatorLayer.bounds = bounds
        secondaryReplicatorLayer.position = CGPoint(x: bounds.size.width / 2.0, y: bounds.size.height / 2.0)

        adjustableSquare.position = CGPoint(x: squareSize, y: squareSize)
        adjustableSquare.bounds.size = CGSize(width: squareSize, height: squareSize)

        replicatorLayer.instanceCount = Int(sourceCopyCount)
        replicatorLayer.instanceTransform = CATransform3DMakeTranslation(sourceInstanceTransformX, sourceInstanceTransformY, 0.0)

        secondaryReplicatorLayer.instanceCount = Int(copyCopyCount)
        secondaryReplicatorLayer.instanceTransform = CATransform3DMakeTranslation(copyInstanceTransformX, copyInstanceTransformY, 0.0)

        CATransaction.commit()
    }

}

class ViewController: UIViewController {

    let demoView = DemoView(frame: .zero)

    override func loadView() {
        self.view = UIView(frame: .zero)
        view.backgroundColor = .white

        view.addSubview(demoView)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let padding = 12.0
        demoView.frame = CGRect(x: view.safeAreaInsets.left + padding, y: view.safeAreaInsets.top + padding,
                                width: view.bounds.size.width - view.safeAreaInsets.left - view.safeAreaInsets.right - (padding * 2.0),
                                height: view.bounds.size.height - view.safeAreaInsets.top - view.safeAreaInsets.bottom - (padding * 2.0))
    }

}

