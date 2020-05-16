//
//  PlatformSwitcher.swift
//  Reversi
//
//  Created by Hori,Masaki on 2020/05/16.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

#if os(iOS)
import UIKit

public typealias PlatformSwitcher = UISegmentedControl
#elseif os(macOS)
import AppKit

public typealias PlatformSwitcher = NSSwitch
#endif


#if os(iOS)

extension UISegmentedControl {
    
    var player: ReversiEngine.Player {
        
        ReversiEngine.Player(rawValue: selectedSegmentIndex)!
    }
}

#endif


#if os(macOS)

extension NSSwitch {
    
    var player: ReversiEngine.Player {
        
        state == .on ? .computer : .manual
    }
}

#endif
