//
//  ViewController-extensions.swift
//  Reversi
//
//  Created by Hori,Masaki on 2020/05/16.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

import Foundation

// MARK: Lifcycle
extension ViewController {
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        setUp()
        
        reversiEngine = ReversiEngine(boardView)
        
        reversiEngine.$counts
            .receive(on: DispatchQueue.main)
            .sink { counts in self.counts = counts }
            .store(in: &calcel)
        
        reversiEngine.$darkPlayer
            .receive(on: DispatchQueue.main)
            .sink { darkPlayer in self.darkPlayer = darkPlayer }
            .store(in: &calcel)
        
        reversiEngine.$lightPlayer
            .receive(on: DispatchQueue.main)
            .sink { lightPlayer in self.lightPlayer = lightPlayer }
            .store(in: &calcel)
        
        reversiEngine.$turn
            .receive(on: DispatchQueue.main)
            .sink { turn in self.turn = turn }
            .store(in: &calcel)
        
        reversiEngine.delegate = self
        
        reversiEngine.start()
    }
}


// MARK: Inputs

extension ViewController {
    /// リセットボタンが押された場合に呼ばれるハンドラーです。
    /// アラートを表示して、ゲームを初期化して良いか確認し、
    /// "OK" が選択された場合ゲームを初期化します。
    @IBAction func pressResetButton(_ sender: Any?) {
        
        let alert = Alert(
            title: "Confirmation",
            message: "Do you really want to reset the game?"
        )
        alert.addAction(AlertAction(title: "Cancel", style: .calcel) { _ in })
        alert.addAction(AlertAction(title: "OK", style: .default) { [weak self] _ in

            self?.reversiEngine.reset()
        })
        
        alert.show(for: self)
    }
    
    /// プレイヤーのモードが変更された場合に呼ばれるハンドラーです。
    @IBAction func changePlayer(_ sender: PlatformSwitcher) {
        
       switch side(for: sender) {
        case .dark: reversiEngine.darkPlayer = sender.player
        case .light: reversiEngine.lightPlayer = sender.player
        }
    }
}


extension ViewController: ReversiEngineDelegate {
    
    func beginComputerThinking(_ reversi: ReversiEngine, turn: Disk) {
        
        startThinking(turn: turn)
    }
    
    func endComputerThinking(_ reversi: ReversiEngine, turn: Disk) {
        
        endThinking(turn: turn)
    }
    
    func willPass(_ reversi: ReversiEngine, turn: Disk, completion: @escaping () -> Void) {
        
        let alert = Alert(
            title: "Pass",
            message: "Cannot place a disk."
        )
        // TODO: titleを for iOSとfor macOSで差し替えられるようにすること
        alert.addAction(AlertAction(title: "Dismiss", style: .default) { _ in
            
            completion()
        })
        
        alert.show(for: self)
    }
}
