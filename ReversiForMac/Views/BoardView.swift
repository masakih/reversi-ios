//
//  BoardView.swift
//  ReversiForMac
//
//  Created by Hori,Masaki on 2020/05/11.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

import Cocoa

private let lineWidth: CGFloat = 2

public class BoardView: NSView, Board {
    
    private var cellViews: [CellView] = []
    private var actions: [CellSelectionAction] = []
    
    /// 盤の幅（ `8` ）を表します。
    public let width: Int = 8
    
    /// 盤の高さ（ `8` ）を返します。
    public let height: Int = 8
    
    /// 盤のセルの `x` の範囲（ `0 ..< 8` ）を返します。
    public let xRange: Range<Int>
    
    /// 盤のセルの `y` の範囲（ `0 ..< 8` ）を返します。
    public let yRange: Range<Int>
    
    /// セルがタップされたときの挙動を移譲するためのオブジェクトです。
    public weak var delegate: BoardDelegate?
    
    override public init(frame: CGRect) {
        xRange = 0 ..< width
        yRange = 0 ..< height
        super.init(frame: frame)
        setUp()
    }
    
    required public init?(coder: NSCoder) {
        xRange = 0 ..< width
        yRange = 0 ..< height
        super.init(coder: coder)
        setUp()
    }
    
    public var allCells: [Board.Cell] {
        
        yRange.flatMap { y in xRange.map { x in (x, y) } }
    }
    
    public var allLines: [Board.Line] {
        
        yRange.map { y in xRange.map { x in (x, y) } }
    }
    
    public override func draw(_ dirtyRect: NSRect) {
        
        NSColor(named: "DarkColor")!.set()
        NSBezierPath(rect: bounds).fill()
        
        super.draw(dirtyRect)
    }
    
    private func setUp() {
        
        let cellViews: [CellView] = (0 ..< (width * height)).map { _ in
            let cellView = CellView()
            cellView.translatesAutoresizingMaskIntoConstraints = false
            return cellView
        }
        self.cellViews = cellViews
        
        cellViews.forEach(self.addSubview(_:))
        for i in cellViews.indices.dropFirst() {
            NSLayoutConstraint.activate([
                cellViews[0].widthAnchor.constraint(equalTo: cellViews[i].widthAnchor),
                cellViews[0].heightAnchor.constraint(equalTo: cellViews[i].heightAnchor),
            ])
        }
        
        NSLayoutConstraint.activate([
            cellViews[0].widthAnchor.constraint(equalTo: cellViews[0].heightAnchor),
        ])
        
        allCells.forEach { (x, y) in
            
            let topNeighborAnchor: NSLayoutYAxisAnchor
            if let cellView = cellViewAt(x: x, y: y - 1) {
                topNeighborAnchor = cellView.bottomAnchor
            } else {
                topNeighborAnchor = self.topAnchor
            }
            
            let leftNeighborAnchor: NSLayoutXAxisAnchor
            if let cellView = cellViewAt(x: x - 1, y: y) {
                leftNeighborAnchor = cellView.rightAnchor
            } else {
                leftNeighborAnchor = self.leftAnchor
            }
            
            let cellView = cellViewAt(x: x, y: y)!
            NSLayoutConstraint.activate([
                cellView.topAnchor.constraint(equalTo: topNeighborAnchor, constant: lineWidth),
                cellView.leftAnchor.constraint(equalTo: leftNeighborAnchor, constant: lineWidth),
            ])
            
            if y == height - 1 {
                NSLayoutConstraint.activate([
                    self.bottomAnchor.constraint(equalTo: cellView.bottomAnchor, constant: lineWidth),
                ])
            }
            if x == width - 1 {
                NSLayoutConstraint.activate([
                    self.rightAnchor.constraint(equalTo: cellView.rightAnchor, constant: lineWidth),
                ])
            }
        }
        
        reset()
        
        allCells.forEach { (x, y) in
            
            let cellView: CellView = cellViewAt(x: x, y: y)!
            let action = CellSelectionAction(boardView: self, x: x, y: y)
            actions.append(action) // To retain the `action`
            cellView.target = action
            cellView.action = #selector(action.selectCell)
        }
    }
    
    /// 盤をゲーム開始時に状態に戻します。このメソッドはアニメーションを伴いません。
    public func reset() {
        allCells.forEach { (x, y) in
            
            setDisk(nil, atX: x, y: y, animated: false)
        }
        
        setDisk(.light, atX: width / 2 - 1, y: height / 2 - 1, animated: false)
        setDisk(.dark, atX: width / 2, y: height / 2 - 1, animated: false)
        setDisk(.dark, atX: width / 2 - 1, y: height / 2, animated: false)
        setDisk(.light, atX: width / 2, y: height / 2, animated: false)
    }
    
    private func cellViewAt(x: Int, y: Int) -> CellView? {
        guard xRange.contains(x) && yRange.contains(y) else { return nil }
        return cellViews[y * width + x]
    }
    
    /// `x`, `y` で指定されたセルの状態を返します。
    /// セルにディスクが置かれていない場合、 `nil` が返されます。
    /// - Parameter x: セルの列です。
    /// - Parameter y: セルの行です。
    /// - Returns: セルにディスクが置かれている場合はそのディスクの値を、置かれていない場合は `nil` を返します。
    public func diskAt(x: Int, y: Int) -> Disk? {
        cellViewAt(x: x, y: y)?.disk
    }
    
    /// `x`, `y` で指定されたセルの状態を、与えられた `disk` に変更します。
    /// `animated` が `true` の場合、アニメーションが実行されます。
    /// アニメーションの完了通知は `completion` ハンドラーで受け取ることができます。
    /// - Parameter disk: セルに設定される新しい状態です。 `nil` はディスクが置かれていない状態を表します。
    /// - Parameter x: セルの列です。
    /// - Parameter y: セルの行です。
    /// - Parameter animated: セルの状態変更を表すアニメーションを表示するかどうかを指定します。
    /// - Parameter completion: アニメーションの完了通知を受け取るハンドラーです。
    ///     `animated` に `false` が指定された場合は状態が変更された後で即座に同期的に呼び出されます。
    ///     ハンドラーが受け取る `Bool` 値は、 `UIView.animate()`  等に準じます。
    public func setDisk(_ disk: Disk?, atX x: Int, y: Int, animated: Bool, completion: ((Bool) -> Void)?) {
        guard let cellView = cellViewAt(x: x, y: y) else {
            preconditionFailure() // FIXME: Add a message.
        }
        cellView.setDisk(disk, animated: animated, completion: completion)
    }
    public func setDisk(_ disk: Disk?, atX x: Int, y: Int, animated: Bool) {
        
        setDisk(disk, atX: x, y: y, animated: animated, completion: nil)
    }
}

private class CellSelectionAction: NSObject {
    private weak var boardView: BoardView?
    let x: Int
    let y: Int
    
    init(boardView: BoardView, x: Int, y: Int) {
        self.boardView = boardView
        self.x = x
        self.y = y
    }
    
    @objc func selectCell() {
        guard let boardView = boardView else { return }
        boardView.delegate?.boardView(boardView, didSelectCellAtX: x, y: y)
    }
}
