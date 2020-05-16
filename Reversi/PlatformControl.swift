//
//  PlatformControl.swift
//  Reversi
//
//  Created by Hori,Masaki on 2020/05/16.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

#if os(iOS)
import UIKit

public typealias PlatformControl = UIControl
#elseif os(macOS)
import AppKit

public typealias PlatformControl = NSControl
#endif

#if os(iOS)

public extension UIControl {
    
    func addNormalAction(_ target: AnyObject, action: Selector) {
        
        addTarget(target, action: action, for: .touchUpInside)
    }
}

#endif


#if os(macOS)

public extension NSControl {
    
    func addNormalAction(_ target: AnyObject, action: Selector) {
        
        self.target = target
        self.action = action
    }
}

#endif
