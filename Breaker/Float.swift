//
//  Float.swift
//  Breaker
//
//  Created by Internicola, Eric on 1/14/17.
//  Copyright © 2017 Eric Internicola. All rights reserved.
//

import SceneKit

extension Float {

    /// Converts this value to radians (assumes we're in degrees already)
    var radians: Float {
        return self * Float(M_PI/180)
    }

    /// Converts this value to degrees (assumes we're in radians already)
    var degrees: Float {
        return self * Float(180/M_PI)
    }

    /// Converts this Float to a CGFloat
    var cgfloat: CGFloat {
        return CGFloat(self)
    }
    
}
