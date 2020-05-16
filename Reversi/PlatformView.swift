//
//  PlatformView.swift
//  Reversi
//
//  Created by Hori,Masaki on 2020/05/16.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

#if os(iOS)
import UIKit

public typealias PlatformView = UIView
#elseif os(macOS)
import AppKit

public typealias PlatformView = NSView
#endif

#if os(macOS)

public extension NSView {
    
    var backgroundColor: Color {
        
        get { .clear }
        set {}
    }
    
    var isUserInteractionEnabled: Bool {
        
        get { false }
        set {}
    }
    
    func setNeedsDisplay() {
        
        needsDisplay = true
    }
}

#endif
