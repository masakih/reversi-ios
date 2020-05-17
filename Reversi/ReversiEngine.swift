//
//  ReversiEngine.swift
//  Reversi
//
//  Created by Hori,Masaki on 2020/05/06.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

import Foundation
import Combine

protocol ReversiEngineDelegate: AnyObject {
    
    func beginComputerThinking(_ reversi: ReversiEngine, turn: Disk)
    func endComputerThinking(_ reversi: ReversiEngine, turn: Disk)
    
    /// パスが発生した時に呼び出される
    /// - Parameter completion: 処理が終わった時に呼び出す必要がある
    func willPass(_ reversi: ReversiEngine, turn: Disk, completion: @escaping () -> Void)
}

final class ReversiEngine {
    
    let board: Board
    
    weak var delegate: ReversiEngineDelegate?
    
    /// 双方のディスクの数
    @Published private(set) var counts: (dark: Int, light: Int) = (0, 0)
    
    /// Dark側のPlayer
    @Published var darkPlayer: Player = .manual {
        
        didSet {
            
            if !isAnimating, currentPlayer == darkPlayer, case .computer = darkPlayer {
                playTurnOfComputer()
            }
        }
    }
    /// Light側のPlayer
    @Published var lightPlayer: Player = .manual {
           
           didSet {
               
               if !isAnimating, currentPlayer == lightPlayer, case .computer = lightPlayer {
                   playTurnOfComputer()
               }
           }
       }
    
    /// どちらの色のプレイヤーのターンかを表します。ゲーム終了時は `nil` です。
    @Published private(set) var turn: Disk? = .dark
    
    private var animationCanceller: Canceller?
    private var isAnimating: Bool { animationCanceller != nil }
    
    private var playerCancellers: [Disk: Canceller] = [:]
    
    init(_ board: Board) {
        
        self.board = board
        board.delegate = self
    }
    
    /// 現在のターンのPlayer
    var currentPlayer: Player? {
        
        switch turn {
        case .dark?: return darkPlayer
        case .light?: return lightPlayer
        case .none: return nil
        }
    }
}

// MARK: Reversi logics
extension ReversiEngine {
    
    /// ディスクの数を更新
    private func updateCounts() {
        
        counts = (countDisks(of: .dark), countDisks(of: .light))
    }
    
    /// `side` で指定された色のディスクが盤上に置かれている枚数を返します。
    /// - Parameter side: 数えるディスクの色です。
    /// - Returns: `side` で指定された色のディスクの、盤上の枚数です。
    private func countDisks(of side: Disk) -> Int {

        board.allCells
            .filter { coordinate in board.diskAt(coordinate) == side  }
            .count
    }
    
    /// 盤上に置かれたディスクの枚数が多い方の色を返します。
    /// 引き分けの場合は `nil` が返されます。
    /// - Returns: 盤上に置かれたディスクの枚数が多い方の色です。引き分けの場合は `nil` を返します。
    func sideWithMoreDisks() -> Disk? {
        
        switch counts {
        case let (d, l) where d == l: return nil
        case let (d, l) where d > l: return .dark
        case let (d, l) where d < l: return .light
            
        default: fatalError("Never reach")
        }
    }
    
    private func flippedDiskCoordinatesByPlacingDisk(_ disk: Disk, at coordinate: Board.Coordinate) -> [Board.Coordinate] {
        
        let directions = [
            (x: -1, y: -1),
            (x:  0, y: -1),
            (x:  1, y: -1),
            (x:  1, y:  0),
            (x:  1, y:  1),
            (x:  0, y:  1),
            (x: -1, y:  0),
            (x: -1, y:  1),
        ]
        
        guard board.diskAt(coordinate) == nil else {
            return []
        }
        
        /// その方向がひっくり返せるかを調べる
        func canFlip(_ direction: (x: Int, y: Int)) -> Bool {
            
            func searchSame(_ coordinate: Board.Coordinate) -> Bool {
                
                let next = coordinate + direction
                guard let targetDisk = board.diskAt(next) else { return false }
                if targetDisk == disk { return true }
                
                return searchSame(next)
            }
            
            let next = coordinate + direction
            guard let targetDisk = board.diskAt(next) else { return false }
            if targetDisk == disk { return false }
            
            return searchSame(next)
        }
        
        /// その方向でひっくり返せるコマの座標の配列を返す
        /// 指定する方向はひっくり返せることが分かっていなければならない
        func flippedCoordinates(by direction: (x: Int, y: Int)) -> [Board.Coordinate] {
            
            (1...10).lazy
                .map { coordinate + $0 * direction }
                .prefix { coordinate in board.diskAt(coordinate) != disk }
        }
        
        return directions.filter(canFlip(_:)).flatMap(flippedCoordinates(by:))
    }
    
    /// `x`, `y` で指定されたセルに、 `disk` が置けるかを調べます。
    /// ディスクを置くためには、少なくとも 1 枚のディスクをひっくり返せる必要があります。
    /// - Parameter x: セルの列です。
    /// - Parameter y: セルの行です。
    /// - Returns: 指定されたセルに `disk` を置ける場合は `true` を、置けない場合は `false` を返します。
    private func canPlaceDisk(_ disk: Disk, at coordinate: Board.Coordinate) -> Bool {
        
        !flippedDiskCoordinatesByPlacingDisk(disk, at: coordinate).isEmpty
    }
    
    /// `side` で指定された色のディスクを置ける盤上のセルの座標をすべて返します。
    /// - Returns: `side` で指定された色のディスクを置ける盤上のすべてのセルの座標の配列です。
    private func validMoves(for side: Disk) -> [Board.Coordinate] {
        
        board.allCells.filter { coordinate in canPlaceDisk(side, at: coordinate) }
    }
    
    /// `x`, `y` で指定されたセルに `disk` を置きます。
    /// - Parameter x: セルの列です。
    /// - Parameter y: セルの行です。
    /// - Parameter isAnimated: ディスクを置いたりひっくり返したりするアニメーションを表示するかどうかを指定します。
    /// - Parameter completion: アニメーション完了時に実行されるクロージャです。
    ///     このクロージャは値を返さず、アニメーションが完了したかを示す真偽値を受け取ります。
    ///     もし `animated` が `false` の場合、このクロージャは次の run loop サイクルの初めに実行されます。
    /// - Throws: もし `disk` を `x`, `y` で指定されるセルに置けない場合、 `DiskPlacementError` を `throw` します。
    private func placeDisk(_ disk: Disk, at coordinate: Board.Coordinate, animated isAnimated: Bool, completion: ((Bool) -> Void)? = nil) throws {
        
        let diskCoordinates = flippedDiskCoordinatesByPlacingDisk(disk, at: coordinate)
        if diskCoordinates.isEmpty {
            throw DiskPlacementError(disk: disk, x: coordinate.x, y: coordinate.y)
        }
        
        if isAnimated {
            let cleanUp: () -> Void = { [weak self] in
                self?.animationCanceller = nil
            }
            animationCanceller = Canceller(cleanUp)
            animateSettingDisks(at: [coordinate] + diskCoordinates, to: disk) { [weak self] isFinished in
                guard let self = self else { return }
                guard let canceller = self.animationCanceller else { return }
                if canceller.isCancelled { return }
                cleanUp()

                completion?(isFinished)
                try? self.saveGame()
                self.updateCounts()
            }
        } else {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.board.setDisk(disk, at: coordinate, animated: false)
                for coordinate in diskCoordinates {
                    self.board.setDisk(disk, at: coordinate, animated: false)
                }
                completion?(true)
                try? self.saveGame()
                self.updateCounts()
            }
        }
    }
    
    /// `coordinates` で指定されたセルに、アニメーションしながら順番に `disk` を置く。
    /// `coordinates` から先頭の座標を取得してそのセルに `disk` を置き、
    /// 残りの座標についてこのメソッドを再帰呼び出しすることで処理が行われる。
    /// すべてのセルに `disk` が置けたら `completion` ハンドラーが呼び出される。
    private func animateSettingDisks<C: Collection>(at coordinates: C, to disk: Disk, completion: @escaping (Bool) -> Void)
        where C.Element == (Int, Int)
    {
        guard let coordinate = coordinates.first else {
            completion(true)
            return
        }
        
        let animationCanceller = self.animationCanceller!
        board.setDisk(disk, at: coordinate, animated: true) { [weak self] isFinished in
            guard let self = self else { return }
            if animationCanceller.isCancelled { return }
            if isFinished {
                self.animateSettingDisks(at: coordinates.dropFirst(), to: disk, completion: completion)
            } else {
                for coordinate in coordinates {
                    self.board.setDisk(disk, at: coordinate, animated: false)
                }
                completion(false)
            }
        }
    }
}

// MARK: Game management

extension ReversiEngine {
    
    /// ゲームを始める
    func start() {
        
        do {
            try loadGame()
        } catch _ {
            newGame()
        }
    }
    
    /// ゲームを再開する
    func resume() {
        
        waitForPlayer()
    }
    
    /// リセットを行う
    func reset() {
        
        newGame()
        
        // TODO: ↓ これ必要？
        waitForPlayer()
    }
    /// ゲームの状態を初期化し、新しいゲームを開始します。
    private func newGame() {
        board.reset()
        turn = .dark
        darkPlayer = .manual
        lightPlayer = .manual
        
        updateCounts()
        
        try? saveGame()
    }
    
    /// プレイヤーの行動を待ちます。
    private func waitForPlayer() {
        guard let player = self.currentPlayer else { return }
        switch player {
        case .manual:
            break
        case .computer:
            playTurnOfComputer()
        }
    }
    
    /// プレイヤーの行動後、そのプレイヤーのターンを終了して次のターンを開始します。
    /// もし、次のプレイヤーに有効な手が存在しない場合、パスとなります。
    /// 両プレイヤーに有効な手がない場合、ゲームの勝敗を表示します。
    private func nextTurn() {
        guard var turn = self.turn else { return }

        turn.flip()
        
        if validMoves(for: turn).isEmpty {
            if validMoves(for: turn.flipped).isEmpty {
                
                self.turn = nil
                
            } else {
                
                delegate?.willPass(self, turn: turn) { [weak self] in self?.nextTurn() }
                
                self.turn = turn
            }
            
        } else {
            
            self.turn = turn
            waitForPlayer()
        }
    }
    
    /// "Computer" が選択されている場合のプレイヤーの行動を決定します。
    private func playTurnOfComputer() {
        
        guard let turn = self.turn else { preconditionFailure() }
        let coordinate = validMoves(for: turn).randomElement()!

        delegate?.beginComputerThinking(self, turn: turn)
        
        let cleanUp: () -> Void = { [weak self] in
            guard let self = self else { return }
            self.playerCancellers[turn] = nil
            
            self.delegate?.endComputerThinking(self, turn: turn)
        }
        let canceller = Canceller(cleanUp)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            
            guard let self = self else { return }
            if canceller.isCancelled { return }
            cleanUp()
            
            try! self.placeDisk(turn, at: coordinate, animated: true) { [weak self] _ in
                self?.nextTurn()
            }
        }
        
        playerCancellers[turn] = canceller
    }
}



extension ReversiEngine: BoardDelegate {
    /// `board` の `x`, `y` で指定されるセルがタップされたときに呼ばれます。
    /// - Parameter board: セルをタップされた `Board` インスタンスです。
    /// - Parameter x: セルの列です。
    /// - Parameter y: セルの行です。
    func boardView(_ board: Board, didSelectCellAt coordinate: Board.Coordinate) {
        
        guard let turn = turn else { return }
        if isAnimating { return }
        guard case .manual = currentPlayer else { return }
        // try? because doing nothing when an error occurs
        try? placeDisk(turn, at: coordinate, animated: true) { [weak self] _ in
            self?.nextTurn()
        }
    }
}


// MARK: Save and Load

extension ReversiEngine {
    private var path: String {
        (NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first! as NSString).appendingPathComponent("Game")
    }
    
    /// ゲームの状態をファイルに書き出し、保存します。
    func saveGame() throws {
        var output: String = ""
        output += turn.symbol
        output += darkPlayer.rawValue.description
        output += lightPlayer.rawValue.description
        output += "\n"
        
        board.allLines
            .forEach { line in
                
                line.forEach { coordinate in
                    
                    output += board.diskAt(coordinate).symbol
                }
                output += "\n"
        }
        
        do {
            try output.write(toFile: path, atomically: true, encoding: .utf8)
        } catch let error {
            throw FileIOError.read(path: path, cause: error)
        }
    }
    
    /// ゲームの状態をファイルから読み込み、復元します。
    func loadGame() throws {
        let input = try String(contentsOfFile: path, encoding: .utf8)
        var lines: ArraySlice<Substring> = input.split(separator: "\n")[...]
        
        guard var line = lines.popFirst() else {
            throw FileIOError.read(path: path, cause: nil)
        }
        
        do { // turn
            guard
                let diskSymbol = line.popFirst(),
                let disk = Optional<Disk>(symbol: diskSymbol.description)
            else {
                throw FileIOError.read(path: path, cause: nil)
            }
            turn = disk
        }

        // players
        guard
            let darkPlayerSymbol = line.popFirst(),
            let darkPlayerNumber = Int(darkPlayerSymbol.description),
            let lightPlayerSymbol = line.popFirst(),
            let lightPlayerNumber = Int(lightPlayerSymbol.description)
            else {
                throw FileIOError.read(path: path, cause: nil)
        }
        darkPlayer = Player(rawValue: darkPlayerNumber) ?? .manual
        lightPlayer = Player(rawValue: lightPlayerNumber) ?? .manual

        do { // board
            guard lines.count == board.height else {
                throw FileIOError.read(path: path, cause: nil)
            }
            
            let disks = lines.map { line in line.compactMap { Disk?(symbol: "\($0)") } }
            
            guard disks.allSatisfy({ $0.count == board.width }) else {
                
                throw FileIOError.read(path: path, cause: nil)
            }
            
            zip(0..., disks).forEach { y, diskLine in
                
                zip(0..., diskLine).forEach { x, disk in
                    
                    board.setDisk(disk, at: (x, y), animated: false)
                }
            }
        }
        
        updateCounts()
    }
    
    enum FileIOError: Error {
        case write(path: String, cause: Error?)
        case read(path: String, cause: Error?)
    }
}

// MARK: Additional types

extension ReversiEngine {
    enum Player: Int {
        case manual = 0
        case computer = 1
    }
}

private final class Canceller {
    private(set) var isCancelled: Bool = false
    private let body: (() -> Void)?
    
    init(_ body: (() -> Void)?) {
        self.body = body
    }
    
    func cancel() {
        if isCancelled { return }
        isCancelled = true
        body?()
    }
}

private struct DiskPlacementError: Error {
    let disk: Disk
    let x: Int
    let y: Int
}


extension Optional where Wrapped == Disk {
    fileprivate init?<S: StringProtocol>(symbol: S) {
        switch symbol {
        case "x":
            self = .some(.dark)
        case "o":
            self = .some(.light)
        case "-":
            self = .none
        default:
            return nil
        }
    }
    
    fileprivate var symbol: String {
        switch self {
        case .some(.dark):
            return "x"
        case .some(.light):
            return "o"
        case .none:
            return "-"
        }
    }
}
