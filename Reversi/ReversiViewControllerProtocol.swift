//
//  ReversiViewControllerProtocol.swift
//  Reversi
//
//  Created by Hori,Masaki on 2020/05/16.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//


protocol ReversiViewControllerProtocol {
    
    // Variable
    var boardView: BoardView! { get }
    
    var reversiEngine: ReversiEngine! { get }
    
    var counts: (Int, Int) { get set }
    
    var darkPlayer: ReversiEngine.Player { get set }
    
    var lightPlayer: ReversiEngine.Player { get set }
    
    var turn: Disk? { get set }
    
    
    /// Functions
    func setUp()
    
    func side(for switcher: PlatformSwitcher) -> Disk
    
    func startThinking(turn: Disk)
    func endThinking(turn: Disk)
    
}
