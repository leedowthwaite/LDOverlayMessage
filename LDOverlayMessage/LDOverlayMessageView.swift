//
//  LDOverlayMessageView.swift
//
//  Created by Lee Dowthwaite on 13/02/2017.
//  Copyright © 2017 Echelon Developments Ltd. All rights reserved.
//

import UIKit

@objc public protocol LDOverlayViewDelegate: NSObjectProtocol {
    func overlayMessageView(_ overlayMessageView: LDOverlayMessageView, willPresentInView: UIView)
    func overlayMessageView(_ overlayMessageView: LDOverlayMessageView, didPresentInView: UIView)
    func overlayMessageView(_ overlayMessageView: LDOverlayMessageView, willDismissFromView: UIView)
    func overlayMessageView(_ overlayMessageView: LDOverlayMessageView, didDismissFromView: UIView)
}

@objc open class LDOverlayMessageView: LDRoundedView {

    private static let kDefaultCornerRadius: CGFloat = 16
    
    public enum LDOverlayMessageStyle {
        case light, dark, blurredLight, blurredDark, debug

        func backgroundColor() -> UIColor {
            switch self {
            case .light:
                return .lightGray
            case .blurredLight:
                return .clear
            case .dark:
                 return .darkGray
            case .blurredDark:
                return .clear
            case .debug:
                return .cyan
            }
        }

        func textColor() -> UIColor {
            switch self {
            case .light,
                 .blurredLight:
                return .darkGray
            case .dark,
                 .blurredDark:
                return .lightGray
            case .debug:
                return .black
            }
        }

    }

    public var style: LDOverlayMessageStyle = .blurredLight
    public var fadeDuration: TimeInterval = 0.4
    public var delegate: LDOverlayViewDelegate?
    public var message: String?
    public var label: UILabel?

    private static var displayed: LDOverlayMessageView?
    private var hostView: UIView?
    private var blurView: UIVisualEffectView?

    // MARK: - construction
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.style = .blurredLight
        setup()
    }
    
    public init(withStyle style: LDOverlayMessageStyle) {
        super.init(frame: .zero)
        self.style = style
        setup()
    }
    
    open func setup() {
        self.backgroundColor = self.style.backgroundColor()
        self.cornerRadius = LDOverlayMessageView.kDefaultCornerRadius

        // add blur effect if required by style
        if let blur = blurEffect(forStyle: self.style) {
            self.blurView = UIVisualEffectView(frame: self.bounds)
            self.blurView?.effect = blur
            //let vibrancyView = UIVisualEffectView(effect: UIVibrancyEffect(blurEffect: blur))
            //vibrancyView.translatesAutoresizingMaskIntoConstraints = false
            //self.blurView?.contentView.addSubview(vibrancyView)
            self.addSubview(self.blurView!)
        }
        self.label = UILabel(frame: self.bounds)
        self.label?.backgroundColor = .clear
        self.label?.textColor = self.style.textColor()
        self.label?.text = "Lorem ipsum dolor whatever blah blah..."
        self.addSubview(self.label!)
    }

    private func blurEffect(forStyle style: LDOverlayMessageStyle) -> UIBlurEffect? {
        switch style {
        case .blurredLight:
            return UIBlurEffect(style: .light)
        case .blurredDark:
            return UIBlurEffect(style: .dark)
        default:
            return nil
        }
    }
    
    // MARK: - constraints and layout

    private func setupConstraints() {
        self.translatesAutoresizingMaskIntoConstraints = false
        if let parent = hostView {
            // this view
            self.centerXAnchor.constraint(equalTo: parent.centerXAnchor, constant: 0).isActive = true
            self.centerYAnchor.constraint(equalTo: parent.centerYAnchor, constant: 0).isActive = true
            
            if let blurView = self.blurView {
                blurView.translatesAutoresizingMaskIntoConstraints = false
                blurView.centerXAnchor.constraint(equalTo: self.centerXAnchor, constant: 0).isActive = true
                blurView.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: 0).isActive = true
                blurView.widthAnchor.constraint(equalTo: self.widthAnchor, constant: 0).isActive = true
                blurView.heightAnchor.constraint(equalTo: self.heightAnchor, constant: 0).isActive = true
            }
            // subviews
            if let label = self.label {
                label.translatesAutoresizingMaskIntoConstraints = false
                label.centerXAnchor.constraint(equalTo: self.centerXAnchor, constant: 0).isActive = true
                label.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: 0).isActive = true
                label.setContentHuggingPriority(1000, for: .horizontal)
                label.setContentHuggingPriority(1000, for: .vertical)
                // set main view to be larger than label
                self.widthAnchor.constraint(equalTo: label.widthAnchor, constant: 200).isActive = true
                self.heightAnchor.constraint(equalTo: label.heightAnchor, constant: 100).isActive = true
                
                label.invalidateIntrinsicContentSize()
            }
        }
    }

    override open func layoutSubviews() {
        if let parent = hostView {
            parent.bringSubview(toFront: self)
        }
        self.setNeedsUpdateConstraints()
    }

    // MARK: - dismiss the HUD

    open func dismiss() {
        self.dismiss(animated: true)
    }

    open func dismiss(animated: Bool) {
        guard let view = hostView else { return }
        self.delegate?.overlayMessageView(self, willDismissFromView: view)
        if (animated) {
            self.alpha = 1
            UIView.animate(withDuration: self.fadeDuration, animations: {
                self.alpha = 0
            }) { (complete) in
                self.removeFromSuperview()
                self.hostView = nil
                LDOverlayMessageView.displayed = nil
                self.delegate?.overlayMessageView(self, didDismissFromView: view)
            }
        } else {
            self.removeFromSuperview()
            self.hostView = nil
            LDOverlayMessageView.displayed = nil
            self.delegate?.overlayMessageView(self, didDismissFromView: view)
        }
    }

    // MARK: - show the HUD
    
    open func show(in specificView: UIView?) {
        self.alpha = 0
        guard let view = viewOrWindow(view: specificView) else { return }
        
        // remove any previous HUD
        removeDisplayedOverlay()
        
        // ensure view is at front of view hierarchy
        hostView = view
        //view.addSubview(self)
        view.insertSubview(self, at: 0)
        LDOverlayMessageView.displayed = self
        
        setupConstraints()
        self.layoutSubviews()

        self.delegate?.overlayMessageView(self, willPresentInView: view)
        UIView.animate(withDuration: self.fadeDuration, animations: {
            self.alpha = 1
        }) { (complete) in
            self.delegate?.overlayMessageView(self, didPresentInView: view)
        }
    }

    // MARK: show convenience methods
    
    open func show(withMessage message: String, for duration: TimeInterval = 2) {
        self.show(in: nil, withMessage: message, for: duration)
    }

    open func show(in view: UIView?, withMessage message: String, for duration: TimeInterval = 2) {
        self.message = message
        self.label?.text = message
        self.show(in: view)
        invoke(after: duration) {
            self.dismiss()
        }
    }

    // MARK: - support methods
    
    private func viewOrWindow(view: UIView?) -> UIView? {
        if let view = view {
            return view
        } else {
            guard let window = UIApplication.shared.keyWindow else { return nil }
            return window
        }
    }

    private func removeDisplayedOverlay() {
        if let overlay = LDOverlayMessageView.displayed {
            overlay.dismiss(animated: false)
        }
    }
}

extension LDOverlayMessageView {

    fileprivate func invoke(after delay:Double, closure:@escaping ()->()) {
        DispatchQueue.main.asyncAfter(
            deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
    }

}
