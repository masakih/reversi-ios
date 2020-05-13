//
//  CellView.swift
//  ReversiForMac
//
//  Created by Hori,Masaki on 2020/05/10.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

import Cocoa

private let animationDuration: TimeInterval = 0.25

public class CellView: NSControl {
    private let button: NSButton = NSButton(frame: .zero)
    private let diskView: DiskView = DiskView()
    
    private var _disk: Disk?
    public var disk: Disk? {
        get { _disk }
        set { setDisk(newValue, animated: true) }
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
        
        do { // button
            do { // backgroundImage
                let i = NSImage(size: .init(width: 1, height: 1))
                do {
                    i.lockFocus()
                    defer { i.unlockFocus() }
                    NSColor(named: "CellColor")!.set()
                    NSBezierPath(rect: NSRect(x: 0, y: 0, width: 1, height: 1)).fill()
                }
                
                button.image = i
                button.imageScaling = .scaleProportionallyUpOrDown
                button.isBordered = false
            }
            self.addSubview(button)
        }

        do { // diskView
            
            diskView.removeConstraints(diskView.constraints)
            diskView.autoresizingMask = .none
            self.addSubview(diskView)
        }

        needsLayout = true
    }
    
    public override func layout() {
        super.layout()
        
        button.frame = bounds
        layoutDiskView()
    }
    
    private func layoutDiskView() {
        let cellSize = bounds.size
        let diskDiameter = Swift.min(cellSize.width, cellSize.height) * 0.8
        let diskSize: CGSize
        if _disk == nil || diskView.disk == _disk {
            diskSize = CGSize(width: diskDiameter, height: diskDiameter)
        } else {
            diskSize = CGSize(width: 1, height: diskDiameter)
        }
        diskView.frame = CGRect(
            origin: CGPoint(x: (cellSize.width - diskSize.width) / 2, y: (cellSize.height - diskSize.height) / 2),
            size: diskSize
        )
        diskView.alphaValue = _disk == nil ? 0.0 : 1.0
    }
    
    private func show() {
        
        let cellSize = bounds.size
        let diskDiameter = Swift.min(cellSize.width, cellSize.height) * 0.8
        let diskSize: CGSize
            diskSize = CGSize(width: diskDiameter, height: diskDiameter)
        diskView.frame = CGRect(
            origin: CGPoint(x: (cellSize.width - diskSize.width) / 2, y: (cellSize.height - diskSize.height) / 2),
            size: diskSize
        )
        diskView.alphaValue = 1.0
    }
    
    private func turn(to disk: Disk, completionHandler: @escaping () -> Void) {
        
        precondition(_disk != nil)
        
        let cellSize = bounds.size
        let diskDiameter = Swift.min(cellSize.width, cellSize.height) * 0.8
        let diskSize = CGSize(width: 1, height: diskDiameter)
        let endFrame = CGRect(
            origin: CGPoint(x: (cellSize.width - diskSize.width) / 2, y: (cellSize.height - diskSize.height) / 2),
            size: diskSize
        )
        
        let attr = ViewAnimationAttributes(target: diskView,
                                           startFrame: nil,
                                           endFrame: endFrame,
                                           effect: nil)
        
        let anime = ViewAnimation(viewAnimations: [attr])
        anime.duration = animationDuration
        anime.start {
            
            self._disk = disk
            self.diskView.disk = disk
            
            let diskSize = CGSize(width: diskDiameter, height: diskDiameter)
            let endFrame = CGRect(
                origin: CGPoint(x: (cellSize.width - diskSize.width) / 2, y: (cellSize.height - diskSize.height) / 2),
                size: diskSize
            )
            
            let attr = ViewAnimationAttributes(target: self.diskView,
                                               startFrame: nil,
                                               endFrame: endFrame,
                                               effect: nil)
            
            let anime = ViewAnimation(viewAnimations: [attr])
            anime.duration = animationDuration
            anime.start {
                
                self.diskView.alphaValue = 1.0
                
                completionHandler()
            }
        }
    }
    
    public func setDisk(_ disk: Disk?, animated: Bool, completion: ((Bool) -> Void)? = nil) {
        
        let diskBefore: Disk? = _disk
        _disk = disk
        let diskAfter: Disk? = _disk
        
        if animated {
            
            switch (diskBefore, diskAfter) {
            case (.none, .none):
                completion?(true)
                
            case (.none, .some(let animationDisk)):
                diskView.disk = animationDisk
                show()
                completion?(true)
                
            case (.some, .none):
                
                NSAnimationContext.runAnimationGroup({ [weak self] con in
                    
                    con.duration = animationDuration
                    con.timingFunction = CAMediaTimingFunction(name: .easeIn)
                    
                    self?.layoutDiskView()
                    
                }, completionHandler: {
                    
                    completion?(true)
                })
                
            case (.some, .some):

                turn(to: disk!) {

                    completion?(true)
                }
            }
            
        } else {
            
            if let diskAfter = diskAfter {
                
                diskView.disk = diskAfter
            }
            completion?(true)
            needsLayout = true
        }
    }
    
    public override var target: AnyObject? {
        get { button.target }
        set { button.target = newValue }
    }
    
    public override var action: Selector? {
        get { button.action }
        set { button.action = newValue }
    }
}
