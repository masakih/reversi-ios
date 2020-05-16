//
//  PlatformImage.swift
//  Reversi
//
//  Created by Hori,Masaki on 2020/05/16.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

#if os(iOS)
import UIKit

public typealias PlatformImage = UIImage
#elseif os(macOS)
import AppKit

public typealias PlatformImage = NSImage
#endif

#if os(iOS)

extension UIColor {
    
    func makeImage(_ size: CGSize) -> UIImage {
        
        UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
        defer { UIGraphicsEndImageContext() }
        
        self.set()
        UIRectFill(CGRect(x: 0, y: 0, width: size.width, height: size.height))
        
        return UIGraphicsGetImageFromCurrentImageContext()!
    }
}

#endif

#if os(macOS)

extension NSColor {
    
    func makeImage(_ size: CGSize) -> NSImage {
        
        let i = NSImage(size: .init(width: size.width, height: size.height))
        do {
            i.lockFocus()
            defer { i.unlockFocus() }
            self.set()
            NSBezierPath(rect: NSRect(x: 0, y: 0, width: size.width, height: size.height)).fill()
        }
        
        return i
    }
}

#endif
