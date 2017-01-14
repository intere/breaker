//
//  CGFloat.swift
//  Breaker
//
//  Created by Internicola, Eric on 1/14/17.
//  Copyright © 2017 Eric Internicola. All rights reserved.
//

import SceneKit

extension CGFloat {

    /// Converts this value to radians (assumes we're in degrees already)
    var radians: CGFloat {
        return self * CGFloat(M_PI/180)
    }

    /// Converts this value to degrees (assumes we're in radians already)
    var degrees: CGFloat {
        return self * CGFloat(180/M_PI)
    }

    /// converts this CGFloat to a Float
    var float: Float {
        return Float(self)
    }
    
}
