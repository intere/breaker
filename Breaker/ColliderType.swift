//
//  ColliderType.swift
//  Breaker
//
//  Created by Eric Internicola on 5/9/16.
//  Copyright © 2016 Eric Internicola. All rights reserved.
//

import UIKit

enum ColliderType: Int {
    case ball = 0b1
    case barrier = 0b10
    case brick = 0b100
    case paddle = 0b1000
}
