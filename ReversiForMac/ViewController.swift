//
//  ViewController.swift
//  ReversiForMac
//
//  Created by Hori,Masaki on 2020/05/10.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

import Cocoa

import Combine

class ViewController: NSViewController {
    
    @IBOutlet private var boardView: BoardView!
    
    @IBOutlet private var darkCountField: NSTextField!
    @IBOutlet private var lightCountField: NSTextField!
    
    @IBOutlet private var darkComputerSwitch: NSSwitch!
    @IBOutlet private var lightComputerSwitch: NSSwitch!

    
    @IBOutlet private var messageDiskView: DiskView!
    @IBOutlet private var messageField: NSTextField!
    
    @IBOutlet private var darkActivityIndicators: NSProgressIndicator!
    @IBOutlet private var lightActivityIndicators: NSProgressIndicator!
    
    private var reversiEngine: ReversiEngine!
    private var calcel: Set<AnyCancellable> = []

    override func viewDidLoad() {
        
    super.viewDidLoad()
        
    reversiEngine = ReversiEngine(boardView)
    
    reversiEngine.$counts
        .receive(on: DispatchQueue.main)
        .map{ counts in (String(counts.0), String(counts.1)) }
        .sink { counts in
            (self.darkCountField.stringValue, self.lightCountField.stringValue) = counts
    }
    .store(in: &calcel)
    
    reversiEngine.$darkPlayer
        .receive(on: DispatchQueue.main)
        .sink { darkPlayer in
            self.darkComputerSwitch.state = (darkPlayer == .computer) ? .on : .off
    }
    .store(in: &calcel)
    
    reversiEngine.$lightPlayer
        .receive(on: DispatchQueue.main)
        .sink { lightPlayer in
            self.lightComputerSwitch.state = (lightPlayer == .computer) ? .on : .off
    }
    .store(in: &calcel)
    
    reversiEngine.$turn
        .receive(on: DispatchQueue.main)
        .sink { turn in
            switch turn {
            case .some(let side):
                self.messageDiskView.disk = side
                self.messageField.stringValue = "'s turn"
            case .none:
                if let winner = self.reversiEngine.sideWithMoreDisks() {
                    self.messageDiskView.disk = winner
                    self.messageField.stringValue = " won"
                } else {
                    self.messageField.stringValue = "Tied"
                }
            }
    }
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
    @IBAction func pressResetButton(_ sender: NSButton) {
        
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
    @IBAction func changePlayerSwitch(_ sender: NSSwitch) {

        switch sender {
        case darkComputerSwitch:
            reversiEngine.darkPlayer = sender.state == .on ? .computer : .manual
        case lightComputerSwitch:
            reversiEngine.lightPlayer = sender.state == .on ? .computer : .manual
        default: fatalError("Unknown switch")
        }
    }
}

extension ViewController: ReversiEngineDelegate {
    
    func beginComputerThinking(_ reversi: ReversiEngine, turn: Disk) {
        
        [darkActivityIndicators, lightActivityIndicators][turn.index].startAnimation(nil)
    }
    
    func endComputerThinking(_ reversi: ReversiEngine, turn: Disk) {
        
         [darkActivityIndicators, lightActivityIndicators][turn.index].stopAnimation(nil)
    }
    
    func willPass(_ reversi: ReversiEngine, turn: Disk, completion: @escaping () -> Void) {
        
        let alert = Alert(
            title: "Pass",
            message: "Cannot place a disk."
        )
        
        // TODO: 文字列をfor iOSとfor macOSで差し替え出来るようにすること
        alert.addAction(AlertAction(title: "OK", style: .default) { _ in
            
            completion()
        })
        
        alert.show(for: self)
    }
}

// MARK: File-private extensions

extension Disk {
    init(index: Int) {
        for side in Disk.sides {
            if index == side.index {
                self = side
                return
            }
        }
        preconditionFailure("Illegal index: \(index)")
    }
    
    var index: Int {
        switch self {
        case .dark: return 0
        case .light: return 1
        }
    }
}
