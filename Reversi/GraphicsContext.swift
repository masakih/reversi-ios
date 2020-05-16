//
//  GraphicsContext.swift
//  Reversi
//
//  Created by Hori,Masaki on 2020/05/16.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//


#if os(iOS)

import UIKit

private func currentContext() -> CGContext? {
    
    UIGraphicsGetCurrentContext()
}

#elseif os(macOS)

import Cocoa

private func currentContext() -> CGContext? {
    
    NSGraphicsContext.current?.cgContext
}

#endif

extension CGContext {
    
    static var current: CGContext? { currentContext() }
}
