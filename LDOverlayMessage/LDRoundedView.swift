//
//  LDRoundedView.swift
//
//  Created by Lee Dowthwaite on 23/02/2016.
//  Copyright © 2016 Echelon Developments Ltd. All rights reserved.
//

import UIKit

@IBDesignable
open class LDRoundedView: UIView {

    @IBInspectable var circular: Bool = false
    @IBInspectable var cornerRadius: CGFloat {
        get {
            return self.layer.cornerRadius
        }
        set {
            let radius = circular ? bounds.width * 0.5 : newValue
            layer.cornerRadius = radius
            layer.masksToBounds = radius > 0
        }
    }
}
