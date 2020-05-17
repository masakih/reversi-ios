//
//  Board.swift
//  Reversi
//
//  Created by Hori,Masaki on 2020/05/10.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

public protocol BoardDelegate: AnyObject {
    /// `board` の `x`, `y` で指定されるセルがタップされたときに呼ばれます。
    /// - Parameter board: セルをタップされた `Board` インスタンスです。
    /// - Parameter x: セルの列です。
    /// - Parameter y: セルの行です。
    func boardView(_ board: Board, didSelectCellAt coordinate: Board.Coordinate)
}

public func + (lhs: Board.Coordinate, rhs: Board.Coordinate) -> Board.Coordinate {
    
    (lhs.x + rhs.x, lhs.y + rhs.y)
}

public func - (lhs: Board.Coordinate, rhs: Board.Coordinate) -> Board.Coordinate {
    
    (lhs.x - rhs.x, lhs.y - rhs.y)
}

public func * (lhs: Int, rhs: Board.Coordinate) -> Board.Coordinate {
    
    (lhs * rhs.x, lhs * rhs.y)
}

public protocol Board: PlatformView {
    
    /// セルの座標を表す
    typealias Coordinate = (x: Int, y: Int)
    /// 行の座標の配列を表す
    typealias Line = [Coordinate]
    
    /// 盤の幅（ `8` ）を表します。
    var width: Int { get }
    
    /// 盤の高さ（ `8` ）を返します。
    var height: Int { get }
    
    /// 盤のセルの `x` の範囲（ `0 ..< 8` ）を返します。
    var xRange: Range<Int> { get }
    
    /// 盤のセルの `y` の範囲（ `0 ..< 8` ）を返します。
    var yRange: Range<Int> { get }
    
    /// セルがタップされたときの挙動を移譲するためのオブジェクトです。
    var delegate: BoardDelegate? { get set }
    
    
    /// 全てのセルの座標を表す
    var allCells: [Coordinate] { get }
    
    /// 全ての行を表す
    var allLines: [Line] { get }
    
    /// `coordinate` で指定されたセルの状態を返します。
    /// セルにディスクが置かれていない場合、 `nil` が返されます。
    /// - Parameter coordinate: セルの座標です。
    /// - Returns: セルにディスクが置かれている場合はそのディスクの値を、置かれていない場合は `nil` を返します。
    func diskAt(_ coordinate: Coordinate) -> Disk?
    
    /// `coordinate` で指定されたセルの状態を、与えられた `disk` に変更します。
    /// `animated` が `true` の場合、アニメーションが実行されます。
    /// アニメーションの完了通知は `completion` ハンドラーで受け取ることができます。
    /// - Parameter disk: セルに設定される新しい状態です。 `nil` はディスクが置かれていない状態を表します。
    /// - Parameter coordinate: セルの座標です。
    /// - Parameter animated: セルの状態変更を表すアニメーションを表示するかどうかを指定します。
    /// - Parameter completion: アニメーションの完了通知を受け取るハンドラーです。
    ///     `animated` に `false` が指定された場合は状態が変更された後で即座に同期的に呼び出されます。
    ///     ハンドラーが受け取る `Bool` 値は、 `UIView.animate()`  等に準じます。
    func setDisk(_ disk: Disk?, at coordinate: Coordinate, animated: Bool, completion: ((Bool) -> Void)?)
    func setDisk(_ disk: Disk?, at coordinate: Coordinate, animated: Bool)
    
    /// ボードをリセットする
    func reset()
}
