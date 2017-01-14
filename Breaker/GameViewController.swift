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

    override var shouldAutorotate : Bool {
        return true
    }

    override var prefersStatusBarHidden : Bool {
        return true
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {

        switch UIDevice.current.orientation {
        case .portrait:
            scnView.pointOfView = verticalCameraNode
        default:
            scnView.pointOfView = horizontalCameraNode
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        switch game.state {
        case .tapToPlay:
            game.reset()
            game.state = .playing
            showSplash("")
            resetNodes()
            scnScene.rootNode.runAction(SCNAction.waitForDurationThenRunBlock(1) { (node) in
                self.ballNode.physicsBody?.velocity = SCNVector3(x: self.gameSpeed, y: 0, z: self.gameSpeed)
            })
            break

        case .gameOver:
            game.state = .tapToPlay
            showSplash("TapToPlay")
            return

        case .playing:
            for touch in touches {
                let location = touch.location(in: scnView)
                touchX = location.x
                paddleX = paddleNode.position.x
            }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard game.state == GameStateType.playing else {
            return
        }

        for touch in touches {
            let location = touch.location(in: scnView)
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

    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        guard game.state != GameStateType.gameOver else {
            showSplash("GameOver")
            scnScene.rootNode.runAction(SCNAction.sequence([SCNAction.wait(duration: 3), SCNAction.run({ (node) in
                guard self.game.state == .gameOver else {
                    return
                }
                self.game.state = .tapToPlay
                self.showSplash("TapToPlay")
            })]))
            return
        }

        if let radians = ballNode.physicsBody?.velocity.xzAngle, abs(radians.degrees) < 7 {
            let angle = radians.degrees
            if angle < 0 {
                ballNode.physicsBody?.velocity.xzAngle = (angle - 5).radians
            } else {
                ballNode.physicsBody?.velocity.xzAngle = (angle + 5).radians
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

    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
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

        if contactNode.physicsBody?.categoryBitMask == ColliderType.barrier.rawValue {
            if contactNode.name == "Bottom" {
                if !invincible {
                    game.lives -= 1
                    if game.lives == 0 {
                        game.state = GameStateType.gameOver
                        ballNode.physicsBody?.velocity = SCNVector3(x: 0, y: 0, z: 0)
                        return
                    }
                    game.playSound(scnScene.rootNode, name: "Barrier")
                    invincible = true

                    scnScene.rootNode.runAction(SCNAction.sequence([SCNAction.wait(duration: 0.5), SCNAction.run({ (node) in
                        self.invincible = false
                    })]))
                }
            }
        } else if contactNode.physicsBody?.categoryBitMask == ColliderType.brick.rawValue {
            game.score += 1
            contactNode.isHidden = true
            let brickNumber = Int(arc4random()) % 3
            game.playSound(scnScene.rootNode,name: "Block\(brickNumber)")
        } else if contactNode.physicsBody?.categoryBitMask == ColliderType.paddle.rawValue {
            if contactNode.name == "Left" {
                ballNode.physicsBody?.velocity.xzAngle -= Float(20).radians
            } else if contactNode.name == "Right" {
                ballNode.physicsBody?.velocity.xzAngle += Float(20).radians
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
        horizontalCameraNode = scnScene.rootNode.childNode(withName: "HorizontalCamera", recursively: true)
        verticalCameraNode = scnScene.rootNode.childNode(withName: "VerticalCamera", recursively: true)
        ballNode = scnScene.rootNode.childNode(withName: "Ball", recursively: true)
        paddleNode = scnScene.rootNode.childNode(withName: "Paddle", recursively: true)
        floorNode = scnScene.rootNode.childNode(withName: "Floor", recursively: true)
        splashNode = scnScene.rootNode.childNode(withName: "Splash", recursively: true)
        scnScene.rootNode.addChildNode(game.hudNode)

        ballNode.physicsBody?.contactTestBitMask = ColliderType.barrier.rawValue | ColliderType.brick.rawValue | ColliderType.paddle.rawValue

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

    func showSplash(_ name:String, imageFileName:String) -> SCNNode {
        splashNode.geometry?.materials.first?.diffuse.contents = UIImage(named: imageFileName)
        return splashNode
    }

    func showSplash(_ splashName:String) {
        var images = [ "TapToPlay": "Breaker.scnassets/Textures/TapToPlay_Diffuse.png", "GameOver": "Breaker.scnassets/Textures/GameOver_Diffuse.png" ]

        if let image = images[splashName] {
            splashNode.isHidden = false
            let _ = showSplash(splashName, imageFileName: image)
        } else {
            splashNode.isHidden = true
        }
    }

    func resetNodes() {

        if let blocks = scnScene.rootNode.childNode(withName: "Bricks", recursively: true) {
            for child in blocks.childNodes {
                child.isHidden = false
            }
        }
        ballNode.position = SCNVector3(x: 0, y: 0, z: 0)
        ballNode.isHidden = false
        splashNode.isHidden = true
    }
}
