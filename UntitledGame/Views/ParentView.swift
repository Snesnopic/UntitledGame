//
//  ParentView.swift
//  UntitledGame
//
//  Created by Linar Zinatullin on 07/12/23.
//

import SwiftUI
import AVFAudio

struct ParentView: View {
    @State var currentGameState: GameState = .mainScreen
    @StateObject var gameLogic: GameLogic = GameLogic.shared
    var body: some View {
        switch currentGameState {
        case .mainScreen:
            MainMenuView(currentGameState: $currentGameState)
        case .playing:
            GameView(currentGameState: $currentGameState)
                .environmentObject(gameLogic)
        case .gameOver:
            GameOverView(currentGameState: $currentGameState, score: $gameLogic.currentScore)
        }
    }
}


#Preview {
    ParentView()
}
