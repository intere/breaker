//
//  ColliderType.swift
//  Breaker
//
//  Created by Eric Internicola on 5/9/16.
//  Copyright © 2016 Eric Internicola. All rights reserved.
//

import UIKit

enum ColliderType: Int {
    case Ball = 0b1
    case Barrier = 0b10
    case Brick = 0b100
    case Paddle = 0b1000
}
