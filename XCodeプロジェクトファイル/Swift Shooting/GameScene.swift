//
//  GameScene.swift
//  Swift Shooting
//
//  Created by TienCheLee on 2020/1/20.
//  Copyright © 2020 TienCheLee. All rights reserved.
//

import SpriteKit
import GameplayKit
import CoreMotion //Motion Sensor
import AVFoundation //Audio

class GameScene: SKScene, SKPhysicsContactDelegate {
    //Life & ScoreBar Change
    var vc: GameViewController!//
    var musicPlyaer: AVAudioPlayer!
    
    //Player
    var GNAseprite = SKSpriteNode()
    
    //Enemy
    var enemyRate: CGFloat = 0.0
    var enemySize = CGSize(width: 0.0, height: 0.0)
    var timer: Timer?
    
    //Motion
    let motionManager = CMMotionManager()
    var accelerationX: CGFloat = 0.0
    
    //Collision
    //Category Bit Maskの定義
    let GNAsepriteCategory: UInt32 = 0b0001
    let missileCategory: UInt32 = 0b0010
    let enemyCategory: UInt32 = 0b0100
    
    //Life Bar
    var lifeLabelNode = SKLabelNode()
    var scoreLabelNode = SKLabelNode()
    //Life & Score property
    var life: Int = 0{
        didSet{
            self.lifeLabelNode.text = "LIFE: \(life)"
        }
    }
    var score: Int = 0{
        didSet{
            self.scoreLabelNode.text = "SCORE: \(score)"
        }
    }
    
    override func didMove(to view: SKView) {
        //Play BGM
        playMusic()
        
        //Player
        var sizeRate: CGFloat = 0.0
        var GNAsepriteSize = CGSize(width: 0.0, height: 0.0)
        let offsetY = frame.height / 20
        
        //Gravity & Collision Effect
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        physicsWorld.contactDelegate = self
        
        //Player
        self.GNAseprite = SKSpriteNode(imageNamed: "GN_Aseprite")
        
        sizeRate = (frame.width / 5) / self.GNAseprite.size.width
        
        GNAsepriteSize = CGSize(width: self.GNAseprite.size.width * sizeRate, height: self.GNAseprite.size.height * sizeRate)
        
        self.GNAseprite.scale(to: GNAsepriteSize)
        
        self.GNAseprite.position = CGPoint(x: 0, y:(-frame.height / 2) + offsetY + GNAsepriteSize.height / 2)
        
        //Enemy
        let tempEnemy = SKSpriteNode(imageNamed: "SwiftBoss")
        
        enemyRate = (frame.width / 10) / tempEnemy.size.width
        
        enemySize = CGSize(width: tempEnemy.size.width * enemyRate, height: tempEnemy.size.height * enemyRate)
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true,
                                     block:{ _ in
                                        self.moveEnemy()
                                        //self.moveBackground()
                                        
        })
        
        //Show Player & 自機への物理ボディ、カテゴリビットマスク、衝突ビットマスクの設定
        self.GNAseprite.physicsBody = SKPhysicsBody(rectangleOf: self.GNAseprite.size)
        self.GNAseprite.physicsBody?.categoryBitMask = self.GNAsepriteCategory
        self.GNAseprite.physicsBody?.collisionBitMask = self.enemyCategory
        self.GNAseprite.physicsBody?.contactTestBitMask = self.enemyCategory
        self.GNAseprite.physicsBody?.isDynamic = true
        
        addChild(self.GNAseprite)
        
        //Motion Sensor
        motionManager.accelerometerUpdateInterval = 0.05
        
        motionManager.startAccelerometerUpdates(to: OperationQueue.current!) {(val, _) in
            guard let unwrapVal = val else{
                return
            }
            let accel = unwrapVal.acceleration
            self.accelerationX = CGFloat(accel.x)
            print(accel.x)
        }
        
        //Show Life Bar
        self.life = 100
        self.lifeLabelNode.fontName = "HelveticaNeue-Bold"
        self.lifeLabelNode.fontColor = UIColor.red
        self.lifeLabelNode.fontSize = 35
        self.lifeLabelNode.position = CGPoint(
            x: frame.width / 2 - (self.lifeLabelNode.frame.width + 20),
            y: frame.height / 2 - self.lifeLabelNode.frame.height * 3)
        addChild(self.lifeLabelNode)
        
        //Show Score Bar
        self.score = 0
        self.scoreLabelNode.fontName = "HelveticaNeue-Bold"
        self.scoreLabelNode.fontColor = UIColor.green
        self.scoreLabelNode.fontSize = 35
        self.scoreLabelNode.position = CGPoint(
            x: -frame.width / 2 + self.scoreLabelNode.frame.width,
            y: frame.height / 2 - self.scoreLabelNode.frame.height * 3)
        addChild(self.scoreLabelNode)
        
    }
    
    override func didSimulatePhysics(){
        let pos = self.GNAseprite.position.x + self.accelerationX * 30
        if pos > frame.width / 2 - self.GNAseprite.frame.width / 2 {return}
        if pos < -frame.width / 2 + self.GNAseprite.frame.width / 2 {return}
        self.GNAseprite.position.x = pos
    }
    
    func moveEnemy(){
        let enemyNames = ["SwiftBoss", "SwiftBoss2", "SwiftBoss3"]
        let idx = Int.random(in: 0 ..< 3)
        let selectedEnemy = enemyNames[idx]
        let enemy = SKSpriteNode(imageNamed: selectedEnemy)
        
        enemy.scale(to: enemySize)
        
        let xPosition = (frame.width / CGFloat.random(in: 1...5)) - frame.width / 2
        
        enemy.position = CGPoint(x: xPosition, y: frame.height / 2)
        
        //Add Collision
        enemy.physicsBody = SKPhysicsBody(rectangleOf: enemy.size)
        enemy.physicsBody?.categoryBitMask = enemyCategory
        enemy.physicsBody?.collisionBitMask = missileCategory ///
        enemy.physicsBody?.contactTestBitMask = missileCategory ///
        enemy.physicsBody?.isDynamic = true
        
        addChild(enemy)
        
        let move = SKAction.moveTo(y: -frame.height / 2, duration: 1.0)
        
        let remove = SKAction.removeFromParent()
        
        enemy.run(SKAction.sequence([move, remove]))
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let missile = SKSpriteNode(imageNamed: "SwiftFunnel")
        
        let missilePosition = CGPoint(x: self.GNAseprite.position.x,
                                     y: self.GNAseprite.position.y +
                                        (self.GNAseprite.size.height / 2) - (missile.size.height / 2))
        
        missile.position = missilePosition
        
        //Add Collision
        missile.physicsBody = SKPhysicsBody(rectangleOf: missile.size)
        missile.physicsBody?.categoryBitMask = self.missileCategory
        missile.physicsBody?.collisionBitMask = self.enemyCategory
        missile.physicsBody?.contactTestBitMask = self.enemyCategory
        missile.physicsBody?.isDynamic = true
        
        addChild(missile)
        
        let move = SKAction.moveTo(y: frame.height + missile.size.height, duration: 0.7)
        
        let remove = SKAction.removeFromParent()
        
        let shootSoundAction = SKAction.playSoundFileNamed("shoot2", waitForCompletion: true)
        
        run(shootSoundAction)
        
        missile.run(SKAction.sequence([move, remove]))
    }
        
    func didBegin(_ contact: SKPhysicsContact) {
        
        
        let explosion = SKEmitterNode(fileNamed: "particle")
        explosion?.position = contact.bodyA.node?.position ?? CGPoint(x: 0, y: 0)
        addChild(explosion!)

        self.run(SKAction.wait(forDuration: 0.35)){
            explosion?.removeFromParent()
        }
        //衝突する位置で発生
        contact.bodyA.node?.removeFromParent()
        contact.bodyB.node?.removeFromParent()
        
        //Audio
        let hitSoundAction = SKAction.playSoundFileNamed("hit", waitForCompletion: true)
        
        let hitSound2Action = SKAction.playSoundFileNamed("Hits_3", waitForCompletion: true)
        
        
        //Missile hits Enemy
        if contact.bodyA.categoryBitMask == missileCategory ||
            contact.bodyB.categoryBitMask == missileCategory{
            self.score += 1000
            //play sound effect
            run(hitSound2Action)
        }
        
        //Enemy hits Player Effect
        if contact.bodyA.categoryBitMask == GNAsepriteCategory ||
            contact.bodyB.categoryBitMask == GNAsepriteCategory{
            self.life -= 20
            ///
            if self.life >= 0{
                run(hitSoundAction)
            }
            ///
            //After One Second restart
            self.run(SKAction.wait(forDuration: 0.5)){
                self.restart()
            }
        }
    }
    
    func playMusic() {
        if let musicPath = Bundle.main.url(forResource: "waitBGM", withExtension: "mp3"){
            musicPlyaer = try! AVAudioPlayer(contentsOf: musicPath, fileTypeHint: nil)
            musicPlyaer.play()
        }
    }
    
    func restart() {
        if self.life <= 0{
            musicPlyaer.stop()
            vc.dismiss(animated: true, completion: nil)
        }
        
        // if Life > 1 then show Player again
        addChild(self.GNAseprite)
    }
        
}
