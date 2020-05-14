import UIKit

import Combine

class ViewController: UIViewController {
    @IBOutlet private var boardView: BoardView!
    
    @IBOutlet private var messageDiskView: DiskView!
    @IBOutlet private var messageLabel: UILabel!
    @IBOutlet private var messageDiskSizeConstraint: NSLayoutConstraint!
    /// Storyboard 上で設定されたサイズを保管します。
    /// 引き分けの際は `messageDiskView` の表示が必要ないため、
    /// `messageDiskSizeConstraint.constant` を `0` に設定します。
    /// その後、新しいゲームが開始されたときに `messageDiskSize` を
    /// 元のサイズで表示する必要があり、
    /// その際に `messageDiskSize` に保管された値を使います。
    private var messageDiskSize: CGFloat!
    
    @IBOutlet private var playerControls: [UISegmentedControl]!
    @IBOutlet private var countLabels: [UILabel]!
    @IBOutlet private var playerActivityIndicators: [UIActivityIndicatorView]!
    
    
    private var reversiEngine: ReversiEngine!
    private var calcel: Set<AnyCancellable> = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        messageDiskSize = messageDiskSizeConstraint.constant
        
        reversiEngine = ReversiEngine(boardView)
        
        reversiEngine.$counts
            .receive(on: DispatchQueue.main)
            .map{ counts in (String(counts.0), String(counts.1)) }
            .sink { counts in
                (self.countLabels[0].text, self.countLabels[1].text) = counts
        }
        .store(in: &calcel)
        
        reversiEngine.$blackPlayer
            .receive(on: DispatchQueue.main)
            .map { blackPlayer in blackPlayer.rawValue }
            .sink { blackPlayer in
                self.playerControls[0].selectedSegmentIndex = blackPlayer
        }
        .store(in: &calcel)
        
        reversiEngine.$whitePlayer
            .receive(on: DispatchQueue.main)
            .map { whitePlayer in whitePlayer.rawValue }
            .sink { whitePlayer in
                self.playerControls[1].selectedSegmentIndex = whitePlayer
        }
        .store(in: &calcel)
        
        reversiEngine.$turn
            .receive(on: DispatchQueue.main)
            .sink { turn in
                switch turn {
                case .some(let side):
                    self.messageDiskSizeConstraint.constant = self.messageDiskSize
                    self.messageDiskView.disk = side
                    self.messageLabel.text = "'s turn"
                case .none:
                    if let winner = self.reversiEngine.sideWithMoreDisks() {
                        self.messageDiskSizeConstraint.constant = self.messageDiskSize
                        self.messageDiskView.disk = winner
                        self.messageLabel.text = " won"
                    } else {
                        self.messageDiskSizeConstraint.constant = 0
                        self.messageLabel.text = "Tied"
                    }
                }
        }
        .store(in: &calcel)
        
        reversiEngine.delegate = self
        
        reversiEngine.start()
    }
    
    private var viewHasAppeared: Bool = false
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if viewHasAppeared { return }
        viewHasAppeared = true
        reversiEngine.waitForPlayer()
    }
}


// MARK: Inputs

extension ViewController {
    /// リセットボタンが押された場合に呼ばれるハンドラーです。
    /// アラートを表示して、ゲームを初期化して良いか確認し、
    /// "OK" が選択された場合ゲームを初期化します。
    @IBAction func pressResetButton(_ sender: UIButton) {
        let alertController = UIAlertController(
            title: "Confirmation",
            message: "Do you really want to reset the game?",
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in })
        alertController.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in

            self?.reversiEngine.reset()
        })
        present(alertController, animated: true)
    }
    
    /// プレイヤーのモードが変更された場合に呼ばれるハンドラーです。
    @IBAction func changePlayerControlSegment(_ sender: UISegmentedControl) {
        
        let side: Disk = Disk(index: playerControls.firstIndex(of: sender)!)
        
        
        switch side {
        case .dark: reversiEngine.blackPlayer = ReversiEngine.Player(rawValue: sender.selectedSegmentIndex)!
        case .light: reversiEngine.whitePlayer = ReversiEngine.Player(rawValue: sender.selectedSegmentIndex)!
        }
    }
}


extension ViewController: ReversiEngineDelegate {
    
    func beginComputerThinking(_ reversi: ReversiEngine, turn: Disk) {
        
        playerActivityIndicators[turn.index].startAnimating()
    }
    
    func endComputerThinking(_ reversi: ReversiEngine, turn: Disk) {
        
        playerActivityIndicators[turn.index].stopAnimating()
    }
    
    func willPass(_ reversi: ReversiEngine, turn: Disk, completion: @escaping () -> Void) {
        
        let alertController = UIAlertController(
            title: "Pass",
            message: "Cannot place a disk.",
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: "Dismiss", style: .default) { _ in
                        
            completion()
        })
        present(alertController, animated: true)
    }
}


// MARK: File-private extensions

extension Disk {
    init(index: Int) {
        for side in Disk.sides {
            if index == side.index {
                self = side
                return
            }
        }
        preconditionFailure("Illegal index: \(index)")
    }
    
    var index: Int {
        switch self {
        case .dark: return 0
        case .light: return 1
        }
    }
}
