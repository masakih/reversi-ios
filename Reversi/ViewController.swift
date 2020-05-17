import UIKit

import Combine

class ViewController: UIViewController, ReversiViewControllerProtocol {
    @IBOutlet private(set) var boardView: BoardView!
    
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
    
    
    var reversiEngine: ReversiEngine!
    var calcel: Set<AnyCancellable> = []
    
    var counts: (Int, Int) {
        
        get {
            
            (
                countLabels[0].text.flatMap(Int.init) ?? 0,
                countLabels[1].text.flatMap(Int.init) ?? 0
            )
        }
        set {
            countLabels[0].text = String(newValue.0)
            countLabels[1].text = String(newValue.1)
        }
    }
    
    var darkPlayer: ReversiEngine.Player {
        
        get {
            playerControls[0].selectedSegmentIndex == 0 ? .manual : .computer
        }
        set {
            playerControls[0].selectedSegmentIndex = newValue.rawValue
        }
    }
    
    var lightPlayer: ReversiEngine.Player {
        
        get {
            playerControls[1].selectedSegmentIndex == 0 ? .manual : .computer
        }
        set {
            playerControls[1].selectedSegmentIndex = newValue.rawValue
        }
    }
    
    var turn: Disk? {
        
        get { messageDiskView.disk }
        set {
            
            switch newValue {
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
    }
    
    func side(for switcher: PlatformSwitcher) -> Disk {
        
        Disk(index: playerControls.firstIndex(of: switcher)!)
    }
    
    func setUp() {
        
        messageDiskSize = messageDiskSizeConstraint.constant
    }
    
    func startThinking(turn: Disk) {
        
        playerActivityIndicators[turn.index].startAnimating()
    }
    
    func endThinking(turn: Disk) {
        
        playerActivityIndicators[turn.index].stopAnimating()
    }
    
    private var viewHasAppeared: Bool = false
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if viewHasAppeared { return }
        viewHasAppeared = true
        reversiEngine.resume()
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
