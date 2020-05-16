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
    
    @IBOutlet private(set) var boardView: BoardView!
    
    @IBOutlet private var darkCountField: NSTextField!
    @IBOutlet private var lightCountField: NSTextField!
    
    @IBOutlet private var darkComputerSwitch: NSSwitch!
    @IBOutlet private var lightComputerSwitch: NSSwitch!

    
    @IBOutlet private var messageDiskView: DiskView!
    @IBOutlet private var messageField: NSTextField!
    
    @IBOutlet private var darkActivityIndicators: NSProgressIndicator!
    @IBOutlet private var lightActivityIndicators: NSProgressIndicator!
    
    var reversiEngine: ReversiEngine!
    var calcel: Set<AnyCancellable> = []
    
    var counts: (Int, Int) {
        
        get { (darkCountField.integerValue, lightCountField.integerValue) }
        set { (self.darkCountField.integerValue, self.lightCountField.integerValue) = newValue }
    }
    
    var darkPlayer: ReversiEngine.Player {
        
        get { darkComputerSwitch.state == .on ? .computer : .manual }
        set { darkComputerSwitch.state = (newValue == .computer) ? .on : .off }
    }
    
    var lightPlayer: ReversiEngine.Player {
        
        get { lightComputerSwitch.state == .on ? .computer : .manual }
        set { lightComputerSwitch.state = (newValue == .computer) ? .on : .off }
    }
    
    var turn: Disk? {
        
        get { messageDiskView.disk }
        set {
            
            switch newValue {
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
    }
    
    func side(for switcher: PlatformSwitcher) -> Disk {
        
        switch switcher {
            
        case darkComputerSwitch: return .dark
        case lightComputerSwitch: return .light
            
        default: fatalError("Never reachside(for: sender)")
        }
    }
    
    func setUp() {}
    
    func startThinking(turn: Disk) {
        
        [darkActivityIndicators, lightActivityIndicators][turn.index].startAnimation(nil)
    }
    
    func endThinking(turn: Disk) {
        
        [darkActivityIndicators, lightActivityIndicators][turn.index].stopAnimation(nil)
    }
}


// MARK: File-private extensions

extension Disk {
//    init(index: Int) {
//        for side in Disk.sides {
//            if index == side.index {
//                self = side
//                return
//            }
//        }
//        preconditionFailure("Illegal index: \(index)")
//    }
    
    var index: Int {
        switch self {
        case .dark: return 0
        case .light: return 1
        }
    }
}
