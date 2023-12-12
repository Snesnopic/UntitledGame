//
//  GameLogic.swift
//  UntitledGame
//
//  Created by Linar Zinatullin on 07/12/23.
//

import Foundation

class GameLogic: ObservableObject {
    
    static let shared: GameLogic = GameLogic()
    
    func setUpGame(){
        self.currentScore = 0
        self.isGameOver = false;
    }
    
    @Published var time: TimeInterval = 0
    @Published var currentScore: Int = 0
    @Published var currentXP: Int = 0
    @Published var xpToNextLvl: Int = 30
    @Published var isGameOver = false
    
    func increaseScore(points: Int){
        self.currentScore = self.currentScore + points
    }
    
    func updateXpBar(value: Int, newCap: Int){
        self.currentXP = value
        self.xpToNextLvl = newCap
    }
    
    func increaseTime(by t: TimeInterval){
        self.time = self.time + t
    }
    
    func finishGame(){
        if self.isGameOver == false{
            self.isGameOver = true
        }
    }
    
}
