//
//  StartScene.swift
//  HoppyBunny
//
//  Created by Carlos Diez on 6/22/16.
//  Copyright © 2016 Carlos Diez. All rights reserved.
//

import SpriteKit

class StartScene: SKScene {
    var startScrollLayer: SKNode!
    var playButton: MSButtonNode!
    
    var scrollSpeed: CGFloat = 40
    let fixedDelta: CFTimeInterval = 1.0/60.0
    
    override func didMoveToView(view: SKView) {
        startScrollLayer = self.childNodeWithName("startScrollLayer")
        
        playButton = self.childNodeWithName("playButton") as! MSButtonNode
        playButton.selectedHandler = {
            let skView = self.view as SKView!
            let scene = GameScene(fileNamed:"GameScene") as GameScene!
            scene.scaleMode = .AspectFill
            skView.presentScene(scene)
        }
    }
    
    override func update(currentTime: NSTimeInterval) {
        scrollClouds()
    }
    
    func scrollClouds() {
        startScrollLayer.position.x -= scrollSpeed * CGFloat(fixedDelta)
        
        for cloud in startScrollLayer.children as![SKSpriteNode] {
            let cloudPosition = startScrollLayer.convertPoint(cloud.position, toNode: self)
            if cloudPosition.x <= -cloud.size.width / 2 {
                let newPosition = CGPointMake((self.size.width / 2) + cloud.size.width, cloudPosition.y)
                cloud.position = self.convertPoint(newPosition, toNode: startScrollLayer)
            }
        }
    }
}
