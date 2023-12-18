//
//  GameScene.swift
//  UntitledGame
//
//  Created by Giuseppe Francione on 06/12/23.
//

import SpriteKit
import AVFoundation

struct CollisionType {
    static let all : UInt32 = UInt32.max
    static let none : UInt32 = 0
    static let player : UInt32 = 1
    static let enemy : UInt32 = 2
    static let xp: UInt32 = 4
    static let playerWeapon: UInt32 = 8
    static let pickUp: UInt32 = 6
    
}

//class playerNode: SKScene {
//    var playerNode: SKSpriteNode!
//
//    override func didMove(to view: SKView) {
//
//        playerNode = SKSpriteNode(color: .red, size: CGSize(width: 50, height: 50))
//        playerNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
//        playerNode.physicsBody = SKPhysicsBody(rectangleOf: playerNode.size)
//        playerNode.physicsBody?.affectedByGravity = false
//        playerNode.physicsBody?.allowsRotation = false
//
//    }
//}

class SceneWrapper{
    var scene = GameScene()
    var joystickScene: Joystick
    init() {
        var screenWidth: CGFloat { UIScreen.main.bounds.size.width }
        var screenHeight: CGFloat { UIScreen.main.bounds.size.height }
        
        scene = GameScene()
        scene.size = CGSize(width: screenWidth, height: screenHeight)
        scene.scaleMode = .fill
        joystickScene = Joystick(player: scene.player,gameSceneReference: scene)
        joystickScene.size = CGSize(width: screenWidth, height: screenHeight)
    }
}

extension CGPoint: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(x)
        hasher.combine(y)
    }
}


class GameScene: SKScene, SKPhysicsContactDelegate, ObservableObject {
    static let shared: GameScene = GameScene()
    var lastUpdateTime: TimeInterval = 0
    var deltaTime: TimeInterval = 0
    var sceneCamera: SKCameraNode = SKCameraNode()
    var readyToLoad: Bool = true
    var player: SKSpriteNode!
    var healthBar: SKScene!
    var joystick: Joystick!
    
    var gameLogic: GameLogic = GameLogic.shared
    var lastUpdate: TimeInterval = 0
    var isPlayerAlive = true
    
    //enemies
    var enemyTypes = EnemyTypesVM().enemyTypes
    var spawnRate: Int = 0
    var readyToIncreaseSpawnRate: Bool = true
    var readyToIncreaseEnemyPower: Bool = true
    var multiplier: Double = 0
    //weapon
    var readyToShoot: Bool = true
    var shootDirection: CGVector = CGVector(dx: 1, dy: 0)
    var fireRate: Double = 1
    var dmg: Int = 10
    var spd: Int = 10
    //xp and pickups
    var xpOnMap: Set<SKNode> = []
    var readyToSpawnPickUp: Bool = true
    //map
    var tilePositions: Set<CGPoint> = []
    let tileSize = CGSize(width: 100, height: 100)
    //music
    var backgroundMusicPlayer: AVAudioPlayer?
    var currentTrack: String?
    
    var isBossReady = true
    
    var timer: Timer?
    
    
    override init(){
        super.init(size: CGSize(width: 500, height: 500))
        view?.showsFPS = true
        view?.showsPhysics = true
        setUpGame()
    }
    
    required init?(coder aDecoder: NSCoder){
        fatalError("coder problem")
    }
    
    func updateTiles() {
        let playerPosition = player.position
        let visibleXDistance = 700
        let visibleYDistance = 700
        
        let minX = playerPosition.x - CGFloat(visibleXDistance)
        let maxX = playerPosition.x + CGFloat(visibleXDistance)
        let minY = playerPosition.y - CGFloat(visibleYDistance)
        let maxY = playerPosition.y + CGFloat(visibleYDistance)
        
        
        // Load new tiles
        for x in stride(from: minX, through: maxX, by: tileSize.width) {
            for y in stride(from: minY, through: maxY, by: tileSize.height) {
                let position = CGPoint(x: x, y: y)
                if !isTilePresent(at: position) {
                    if((position.x >= minX && position.x < (minX + 400)) || (position.x > (maxX - 400) && position.x <= maxX)){
                        addTile(at: position)
                    }else if((position.y >= minY && position.y < (minY + 300)) || (position.y > (maxY - 300) && position.y <= maxY)){
                        addTile(at: position)
                    }
                }
            }
        }
        for tile in self.children.compactMap({ $0 as? SKSpriteNode }) {
            if tile.position.x < minX || tile.position.x > maxX ||
                tile.position.y < minY || tile.position.y > maxY {
                tilePositions.remove(tile.position)
                tile.removeFromParent()
            }
        }
        
    }
    
    func isTilePresent(at position: CGPoint) -> Bool {
        return tilePositions.contains(position)
    }
    
    func addTile(at position: CGPoint) {
        let tileImageName: String
        let tileType = Int.random(in: 1...100)
        if(tileType <= 70){
            tileImageName = "Moon1"
        }else{
            tileImageName = "Moon2"
        }
        
        let tile = SKSpriteNode(imageNamed: tileImageName)
        tile.position = position
        tile.zPosition = -3
        addChild(tile)
        
        tilePositions.insert(position)
    }
    
    override func didMove(to view: SKView) {
        print("You are in the game scene!")
        
        
        //Music
        playTracks()
        
        let initialTiles = 20
        let tileSize = CGSize(width: 128, height: 128)
        
        for x in -initialTiles...initialTiles {
            for y in -initialTiles...initialTiles {
                let position = CGPoint(x: CGFloat(x) * tileSize.width, y: CGFloat(y) * tileSize.height)
                addTile(at: position)
            }
        }
        
    }
    
    func distanceBetween(node1: SKNode, node2: SKNode) -> Float {
        return hypotf(Float(node1.position.x - node2.position.x), Float(node1.position.y - node2.position.y))
    }
    override func update(_ currentTime: TimeInterval) {
        
        if(self.lastUpdate == 0){
            self.lastUpdate = currentTime
        }
        
        let timeElapsedSinceLastUpdate = min(currentTime - self.lastUpdate, 0.5)
        
        self.gameLogic.increaseTime(by: timeElapsedSinceLastUpdate)
        
        self.lastUpdate = currentTime
        
        enemyLogic(currentTime: currentTime)
        camera?.position = player.position
        
        //enable to have a wider view
        //camera?.setScale(5)
        
        if ((gameLogic.showPowerUp) || gameLogic.showPauseMenu){
            self.scene?.isPaused = true
        }else{
            self.scene?.isPaused = false
        }
        
        if lastUpdateTime.isZero {
            lastUpdateTime = currentTime
        }
        
        deltaTime = currentTime - lastUpdateTime
        
        
        lastUpdateTime = currentTime
        
        if readyToShoot {
            readyToShoot = false
            shoot()
            DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(fireRate)) {
                self.readyToShoot = true
            }
        }
        if readyToLoad {
            readyToLoad = false
            updateTiles()
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.readyToLoad = true
            }
        }
    
        if readyToIncreaseSpawnRate {
            readyToIncreaseSpawnRate = false
            self.spawnRate = self.spawnRate + 7
            DispatchQueue.main.asyncAfter(deadline: .now() + 45) {
                self.readyToIncreaseSpawnRate = true
            }
        }
        
        if readyToIncreaseEnemyPower {
            readyToIncreaseEnemyPower = false
            multiplier = multiplier + 1
            //print(multiplier)
            DispatchQueue.main.asyncAfter(deadline: .now() + 110) {
                self.readyToIncreaseEnemyPower = true
            }
        }
        
        if readyToSpawnPickUp{
            readyToSpawnPickUp = false
            spawnPickUp()
            DispatchQueue.main.asyncAfter(deadline: .now() + 60) {
                self.readyToSpawnPickUp = true
            }
        }
        
        
    }
    
}

