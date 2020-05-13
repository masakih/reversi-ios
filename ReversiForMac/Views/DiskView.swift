//
//  DiskView.swift
//  ReversiForMac
//
//  Created by Hori,Masaki on 2020/05/10.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

import Cocoa

public class DiskView: NSView {
    
    /// このビューが表示するディスクの色を決定します。
    public var disk: Disk = .dark {
        didSet { needsDisplay = true }
    }
    
    /// Interface Builder からディスクの色を設定するためのプロパティです。 `"dark"` か `"light"` の文字列を設定します。
    @IBInspectable public var name: String {
        get { disk.name }
        set { disk = .init(name: newValue) }
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        setUp()
    }

    private func setUp() {
        
    }

    override public func draw(_ rect: CGRect) {
        
        NSColor.clear.set()
        NSBezierPath(rect: bounds).fill()
        
        disk.nsColor.set()
        NSBezierPath(ovalIn: bounds).fill()
    }
}

extension Disk {
    fileprivate var nsColor: NSColor {
        switch self {
        case .dark: return NSColor(named: "DarkColor")!
        case .light: return NSColor(named: "LightColor")!
        }
    }
    
    fileprivate var name: String {
        switch self {
        case .dark: return "dark"
        case .light: return "light"
        }
    }
    
    fileprivate init(name: String) {
        switch name {
        case Disk.dark.name:
            self = .dark
        case Disk.light.name:
            self = .light
        default:
            preconditionFailure("Illegal name: \(name)")
        }
    }
}
