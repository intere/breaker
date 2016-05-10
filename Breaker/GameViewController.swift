//
//  GameViewController.swift
//  Breaker
//
//  Created by Eric Internicola on 5/9/16.
//  Copyright (c) 2016 Eric Internicola. All rights reserved.
//

import UIKit
import QuartzCore
import SceneKit
import SpriteKit

class GameViewController: UIViewController {

    let gameSpeed: Float = 2.5
    var invincible = false

    var scnView: SCNView!
    var scnScene: SCNScene!
    var horizontalCameraNode: SCNNode!
    var verticalCameraNode: SCNNode!
    var ballNode: SCNNode!
    var paddleNode: SCNNode!
    var lastContactNode: SCNNode!
    var floorNode: SCNNode!
    var splashNode: SCNNode!

    var game = GameHelper.sharedInstance

    var touchX: CGFloat = 0
    var paddleX: Float = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        setupScene()
        setupNodes()
        setupSounds()
        setupSplash()
    }

    override func shouldAutorotate() -> Bool {
        return true
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }

    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {

        switch UIDevice.currentDevice().orientation {
        case .Portrait:
            scnView.pointOfView = verticalCameraNode
        default:
            scnView.pointOfView = horizontalCameraNode
        }
    }

    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        switch game.state {
        case .TapToPlay:
            game.reset()
            game.state = .Playing
            showSplash("")
            resetNodes()
            scnScene.rootNode.runAction(SCNAction.waitForDurationThenRunBlock(1) { (node) in
                self.ballNode.physicsBody?.velocity = SCNVector3(x: self.gameSpeed, y: 0, z: self.gameSpeed)
            })
            break

        case .GameOver:
            game.state = .TapToPlay
            showSplash("TapToPlay")
            return

        case .Playing:
            for touch in touches {
                let location = touch.locationInView(scnView)
                touchX = location.x
                paddleX = paddleNode.position.x
            }
        }
    }

    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        guard game.state == GameStateType.Playing else {
            return
        }

        for touch in touches {
            let location = touch.locationInView(scnView)
            paddleNode.position.x = paddleX + Float(location.x - touchX) * 0.1

            if paddleNode.position.x > 4.5 {
                paddleNode.position.x = 4.5
            } else if paddleNode.position.x < -4.5 {
                paddleNode.position.x = -4.5
            }
        }
        verticalCameraNode.position.x = paddleNode.position.x
        horizontalCameraNode.position.x = paddleNode.position.x
    }

}

// MARK: - SCNSceneRendererDelegate

extension GameViewController : SCNSceneRendererDelegate {

    func renderer(renderer: SCNSceneRenderer, updateAtTime time: NSTimeInterval) {
        guard game.state != GameStateType.GameOver else {
            showSplash("GameOver")
            scnScene.rootNode.runAction(SCNAction.sequence([SCNAction.waitForDuration(3), SCNAction.runBlock({ (node) in
                guard self.game.state == .GameOver else {
                    return
                }
                self.game.state = .TapToPlay
                self.showSplash("TapToPlay")
            })]))
            return
        }

        if let radians = ballNode.physicsBody?.velocity.xzAngle where abs(convertToDegrees(radians)) < 7 {
            let angle = convertToDegrees(radians)
            if angle < 0 {
                ballNode.physicsBody?.velocity.xzAngle = convertToRadians(angle - 5)
            } else {
                ballNode.physicsBody?.velocity.xzAngle = convertToRadians(angle + 5)
            }
        }

        if ballNode.position.x > 4.5 {
            ballNode.position.x = 4.5
        } else if ballNode.position.x < -4.5 {
            ballNode.position.x = -4.5
        }
        game.updateHUD()
    }
    
}

// MARK: - SCNPhysicsContactDelegate

extension GameViewController : SCNPhysicsContactDelegate {

    func physicsWorld(world: SCNPhysicsWorld, didBeginContact contact: SCNPhysicsContact) {
        var contactNode: SCNNode!
        if contact.nodeA.name == "Ball" {
            contactNode = contact.nodeB
        } else {
            contactNode = contact.nodeA
        }

        guard lastContactNode == nil || lastContactNode != contactNode else {
            return
        }

        lastContactNode = contactNode

        if contactNode.physicsBody?.categoryBitMask == ColliderType.Barrier.rawValue {
            if contactNode.name == "Bottom" {
                if !invincible {
                    game.lives -= 1
                    if game.lives == 0 {
                        game.state = GameStateType.GameOver
                        ballNode.physicsBody?.velocity = SCNVector3(x: 0, y: 0, z: 0)
                        return
                    }
                    game.playSound(scnScene.rootNode, name: "Barrier")
                    invincible = true

                    scnScene.rootNode.runAction(SCNAction.sequence([SCNAction.waitForDuration(0.5), SCNAction.runBlock({ (node) in
                        self.invincible = false
                    })]))
                }
            }
        } else if contactNode.physicsBody?.categoryBitMask == ColliderType.Brick.rawValue {
            game.score += 1
            contactNode.hidden = true
            let brickNumber = random() % 3
            game.playSound(scnScene.rootNode,name: "Block\(brickNumber)")
        } else if contactNode.physicsBody?.categoryBitMask == ColliderType.Paddle.rawValue {
            if contactNode.name == "Left" {
                ballNode.physicsBody?.velocity.xzAngle -= convertToRadians(20)
            } else if contactNode.name == "Right" {
                ballNode.physicsBody?.velocity.xzAngle += convertToRadians(20)
            }
            game.playSound(scnScene.rootNode, name:"Paddle")
        }
        ballNode.physicsBody?.velocity.length = gameSpeed
    }

}

// MARK: - Helpers

private extension GameViewController {

    func setupScene() {
        scnView = self.view as! SCNView
        scnView.delegate = self
        scnScene = SCNScene(named: "Breaker.scnassets/Scenes/Game.scn")
        scnView.scene = scnScene

        scnScene.physicsWorld.contactDelegate = self

        debugScene()
    }

    func debugScene() {
        scnView.showsStatistics = true
        scnView.autoenablesDefaultLighting = true
//        scnView.allowsCameraControl = true
    }

    func setupNodes() {
        horizontalCameraNode = scnScene.rootNode.childNodeWithName("HorizontalCamera", recursively: true)
        verticalCameraNode = scnScene.rootNode.childNodeWithName("VerticalCamera", recursively: true)
        ballNode = scnScene.rootNode.childNodeWithName("Ball", recursively: true)
        paddleNode = scnScene.rootNode.childNodeWithName("Paddle", recursively: true)
        floorNode = scnScene.rootNode.childNodeWithName("Floor", recursively: true)
        splashNode = scnScene.rootNode.childNodeWithName("Splash", recursively: true)
        scnScene.rootNode.addChildNode(game.hudNode)

        ballNode.physicsBody?.contactTestBitMask = ColliderType.Barrier.rawValue | ColliderType.Brick.rawValue | ColliderType.Paddle.rawValue

        verticalCameraNode.constraints = [SCNLookAtConstraint(target: floorNode)]
        horizontalCameraNode.constraints = [SCNLookAtConstraint(target: floorNode)]
        ballNode.physicsBody?.velocity = SCNVector3(x: 0, y: 0, z: 0)
    }

    func setupSounds() {
        for name in [ "Paddle", "Block0", "Block1", "Block2", "Barrier" ] {
            game.loadSound(name, fileNamed: "Breaker.scnassets/Sounds/\(name).wav")
        }
    }

    func setupSplash() {
        showSplash("TapToPlay")
    }

}

// MARK: - Helpers

private extension GameViewController {

    func showSplash(name:String, imageFileName:String) -> SCNNode {
        splashNode.geometry?.materials.first?.diffuse.contents = UIImage(named: imageFileName)
        return splashNode
    }

    func showSplash(splashName:String) {
        var images = [ "TapToPlay": "Breaker.scnassets/Textures/TapToPlay_Diffuse.png", "GameOver": "Breaker.scnassets/Textures/GameOver_Diffuse.png" ]

        if let image = images[splashName] {
            splashNode.hidden = false
            showSplash(splashName, imageFileName: image)
        } else {
            splashNode.hidden = true
        }
    }

    func resetNodes() {

        if let blocks = scnScene.rootNode.childNodeWithName("Bricks", recursively: true) {
            for child in blocks.childNodes {
                child.hidden = false
            }
        }
        ballNode.position = SCNVector3(x: 0, y: 0, z: 0)
        ballNode.hidden = false
        splashNode.hidden = true
    }
}