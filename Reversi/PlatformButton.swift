//
//  PlatformButton.swift
//  Reversi
//
//  Created by Hori,Masaki on 2020/05/16.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

#if os(iOS)
import UIKit

public typealias PlatformButton = UIButton
#elseif os(macOS)
import AppKit

public typealias PlatformButton = NSButton
#endif


#if os(iOS)

public extension UIButton {
    
    func setBackgroundImage(_ image: UIImage?) {
        
        setBackgroundImage(image, for: .normal)
        setBackgroundImage(image, for: .disabled)
    }
}

#endif

#if os(macOS)

public extension NSButton {
    
    func setBackgroundImage(_ image: NSImage?) {
        
        self.image = image
        imageScaling = .scaleProportionallyUpOrDown
        isBordered = false
    }
}

#endif
