//
//  GameScene.swift
//  HoppyBunny
//
//  Created by Carlos Diez on 6/21/16.
//  Copyright (c) 2016 Carlos Diez. All rights reserved.
//

import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    var hero: SKSpriteNode!
    var restartButton: MSButtonNode!
    var playButton: MSButtonNode!
    var scrollLayer: SKNode!
    var obstacleLayer: SKNode!
    var parallaxScrollLayer: SKNode!
    var scoreLabel: SKLabelNode!
    var highScoreLabel: SKLabelNode!
    
    var points = 0
    
    var sinceTouch : CFTimeInterval = 0
    var spawnTimer: CFTimeInterval = 0
    let fixedDelta: CFTimeInterval = 1.0/60.0
    let scrollSpeed: CGFloat = 160
    
    enum GameSceneState {
        case Start, Active, GameOver
    }
    
    enum GameDifficulty: Double {
        case Easy = 2, Medium = 1.5, Hard = 0.8
    }
    
    var gameDifficulty: GameDifficulty = .Easy
    var gameState: GameSceneState = .Active
    
    override func didMoveToView(view: SKView) {
        /* Setup your scene here */
        
        physicsWorld.contactDelegate = self
        
        /* Recursive node search for 'hero' (child of referenced node) */
        hero = self.childNodeWithName("//hero") as! SKSpriteNode
        
        /* Set reference to scroll layer node */
        scrollLayer = self.childNodeWithName("scrollLayer")
        obstacleLayer = self.childNodeWithName("obstacleLayer")
        parallaxScrollLayer = self.childNodeWithName("parallaxScrollLayer")
        
        scoreLabel = self.childNodeWithName("scoreLabel") as! SKLabelNode
        highScoreLabel = self.childNodeWithName("highScoreLabel") as! SKLabelNode
        
        restartButton = self.childNodeWithName("restartButton") as! MSButtonNode
        restartButton.selectedHandler = {
            let skView = self.view as SKView!
            let scene = GameScene(fileNamed:"GameScene") as GameScene!
            scene.scaleMode = .AspectFill
            skView.presentScene(scene)
        }
        
        restartButton.state = .Hidden
        highScoreLabel.hidden = true
        
        scoreLabel.text = String(points)
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        /* Called when a touch begins */
        if gameState != .Active { return }
        
        hero.physicsBody?.velocity = CGVectorMake(0, 0)
        
        hero.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 250))
        
        /* Play SFX */
        let flapSFX = SKAction.playSoundFileNamed("sfx_flap", waitForCompletion: false)
        self.runAction(flapSFX)
    }
    
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
        if gameState != .Active { return }
        //playButton.state = .Hidden
        
        /* Grab current velocity */
        let velocityY = hero.physicsBody?.velocity.dy ?? 0
        
        /* Check and cap vertical velocity */
        if velocityY > 400 {
            hero.physicsBody?.velocity.dy = 400
        }
        
        scrollWorld()
        updateObstacles()
    }
    
    func scrollWorld() {
        scrollLayer.position.x -= scrollSpeed * CGFloat(fixedDelta)
        
        /* Loop through scroll layer nodes */
        for ground in scrollLayer.children as! [SKSpriteNode] {
            
            /* Get ground node position, convert node position to scene space */
            let groundPosition = scrollLayer.convertPoint(ground.position, toNode: self)
            
            /* Check if ground sprite has left the scene */
            if groundPosition.x <= -ground.size.width / 2 {
                
                /* Reposition ground sprite to the second starting position */
                let newPosition = CGPointMake( (self.size.width / 2) + ground.size.width, groundPosition.y)
                
                /* Convert new node position back to scroll layer space */
                ground.position = self.convertPoint(newPosition, toNode: scrollLayer)
            }
        }
        
        parallaxScrollLayer.position.x -= (scrollSpeed / 4) * CGFloat(fixedDelta)
        
        for cloud in parallaxScrollLayer.children as![SKSpriteNode] {
            let cloudPosition = parallaxScrollLayer.convertPoint(cloud.position, toNode: self)
            if cloudPosition.x <= -cloud.size.width / 2 {
                let newPosition = CGPointMake((self.size.width / 2) + cloud.size.width, cloudPosition.y)
                cloud.position = self.convertPoint(newPosition, toNode: parallaxScrollLayer)
            }
        }
    }
    
    func updateObstacles() {
        /* Update Obstacles */
        
        obstacleLayer.position.x -= scrollSpeed * CGFloat(fixedDelta)
        
        /* Loop through obstacle layer nodes */
        for obstacle in obstacleLayer.children as! [SKReferenceNode] {
            
            /* Get obstacle node position, convert node position to scene space */
            let obstaclePosition = obstacleLayer.convertPoint(obstacle.position, toNode: self)
            
            /* Check if obstacle has left the scene */
            if obstaclePosition.x <= 0 {
                
                /* Remove obstacle node from obstacle layer */
                obstacle.removeFromParent()
            }
        }
        
        if spawnTimer >= gameDifficulty.rawValue {
            
            /* Create a new obstacle reference object using our obstacle resource */
            let resourcePath = NSBundle.mainBundle().pathForResource("Obstacle", ofType: "sks")
            let newObstacle = SKReferenceNode (URL: NSURL (fileURLWithPath: resourcePath!))
            obstacleLayer.addChild(newObstacle)
            
            /* Generate new obstacle position, start just outside screen and with a random y value */
            var randomPosition: CGPoint!
            if gameDifficulty == .Easy {
                randomPosition = CGPointMake(352, CGFloat.random(min: 290, max: 330))
            }
            else if gameDifficulty == .Medium{
                randomPosition = CGPointMake(352, CGFloat.random(min: 250, max: 360))
            }
            else if gameDifficulty == .Hard {
                randomPosition = CGPointMake(352, CGFloat.random(min: 234, max: 382))
            }
            
            /* Convert new node position back to obstacle layer space */
            newObstacle.position = self.convertPoint(randomPosition, toNode: obstacleLayer)
            
            // Reset spawn timer
            spawnTimer = 0
        }
        
        spawnTimer += fixedDelta
    }
    
    func didBeginContact(contact: SKPhysicsContact) {
        /* Ensure only called while game running */
        if gameState != .Active { return }
        
        /* Get references to bodies involved in collision */
        let contactA:SKPhysicsBody = contact.bodyA
        let contactB:SKPhysicsBody = contact.bodyB
        
        /* Get references to the physics body parent nodes */
        let nodeA = contactA.node!
        let nodeB = contactB.node!
        
        /* Did our hero pass through the 'goal'? */
        if nodeA.name == "goal" || nodeB.name == "goal" {
            
            /* Increment points */
            points += 1
            
            /* Update score label */
            scoreLabel.text = String(points)
            
            let goalSFX = SKAction.playSoundFileNamed("sfx_goal", waitForCompletion: false)
            self.runAction(goalSFX)
            
            if points >= 5 && points < 45 {
                gameDifficulty = .Medium
            }
            else if points > 45 {
                gameDifficulty = .Hard
            }
            
            /* We can return now */
            return
        }
        
        /* Hero touches anything, game over */
        
        /* Change game state to game over */
        gameState = .GameOver
        
        
        /* Stop any new angular velocity being applied */
        hero.physicsBody?.allowsRotation = false
        
        /* Reset angular velocity */
        hero.physicsBody?.angularVelocity = 0
        
        /* Stop hero flapping animation */
        hero.removeAllActions()
        
        let heroDeath = SKAction.runBlock({
            
            /* Put our hero face down in the dirt */
            self.hero.zRotation = CGFloat(-90).degreesToRadians()
            /* Stop hero from colliding with anything else */
            self.hero.physicsBody?.collisionBitMask = 0
        })
        
        /* Run action */
        hero.runAction(heroDeath)
        
        
        /* Load the shake action resource */
        let shakeScene:SKAction = SKAction.init(named: "Shake")!
        
        /* Loop through all nodes  */
        for node in self.children {
            
            /* Apply effect each ground node */
            node.runAction(shakeScene)
        }
        
        let userDefaults = NSUserDefaults.standardUserDefaults()
        var highscore = userDefaults.integerForKey("highscore")
        
        if points > highscore {
            userDefaults.setValue(points, forKey: "highscore")
            userDefaults.synchronize()
        }
        
        highscore = userDefaults.integerForKey("highscore")
        
        highScoreLabel.text = "High Score: \(highscore)"
 
        /* Show restart button */
        
        restartButton.state = .Active
        highScoreLabel.hidden = false
        
    }
}
