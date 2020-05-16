//
//  WindowController.swift
//  ReversiForMac
//
//  Created by Hori,Masaki on 2020/05/16.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

import Cocoa

class WindowController: NSWindowController {
    
    override func windowDidLoad() {
        
        super.windowDidLoad()
        
        window?.aspectRatio = NSSize(width: 1.05, height: 1.0)
    }
}
