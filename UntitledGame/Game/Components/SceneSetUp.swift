//
//  SceneSetUp.swift
//  UntitledGame
//
//  Created by Linar Zinatullin on 07/12/23.
//

import Foundation
import SpriteKit

extension GameScene {
    
    func setUpGame() {
        self.gameLogic.setUpGame()
        self.backgroundColor = SKColor.darkGray
        let playerInitialPosition = CGPoint(x: self.frame.width/2, y: self.frame.height/2)
        self.createPlayer(at: playerInitialPosition)
        self.camera = sceneCamera
    }
    
    private func setUpPhysicsWorld() {
        // TODO: Customize!
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = .zero
        
    }
    
    private func createPlayer(at position: CGPoint) {
        self.player.name = "player"
        
        player.size = (player.texture?.size())!
        self.player.position = position
        
        player.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: player.texture!.size().width, height:  (player.texture?.size().height)!))
        
        player.physicsBody?.categoryBitMask = CollisionType.player
        player.physicsBody?.collisionBitMask = CollisionType.enemy
        player.physicsBody?.contactTestBitMask = CollisionType.enemy
        player.physicsBody?.isDynamic = false
        self.player.physicsBody?.affectedByGravity = false
        addChild(self.player)
    }
}
