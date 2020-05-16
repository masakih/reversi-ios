
#if os(iOS)
import UIKit
#elseif os(macOS)
import Cocoa
#endif

private let animationDuration: TimeInterval = 0.25

public class CellView: PlatformControl {
    private let button = PlatformButton(frame: .zero)
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
            button.enableViewAnimation = true
            do { // backgroundImage
                button.setBackgroundImage(
                    Color(named: "CellColor")?.makeImage(CGSize(width: 1, height: 1))
                )
            }
            self.addSubview(button)
        }

        do { // diskView
            diskView.enableViewAnimation = true
            self.addSubview(diskView)
        }

        setNeedsLayout()
    }
    
    private func layoutDiskView() {
        let cellSize = bounds.size
        let diskDiameter = Swift.min(cellSize.width, cellSize.height) * 0.8
        let diskSize: CGSize
        if _disk == nil || diskView.disk == _disk {
            diskSize = CGSize(width: diskDiameter, height: diskDiameter)
        } else {
            diskSize = CGSize(width: 0, height: diskDiameter)
        }
        diskView.frame = CGRect(
            origin: CGPoint(x: (cellSize.width - diskSize.width) / 2, y: (cellSize.height - diskSize.height) / 2),
            size: diskSize
        )
        diskView.alpha = _disk == nil ? 0.0 : 1.0
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
                show { finished in completion?(finished) }
            case (.some, .none):
                show { finished in completion?(finished) }
            case (.some, .some):
                turn(to: disk!) { finished in
                    completion?(finished)
                }
            }
        } else {
            if let diskAfter = diskAfter {
                diskView.disk = diskAfter
            }
            completion?(true)
            setNeedsLayout()
        }
    }
}


// MARK: Animation
#if os(iOS)

extension CellView {
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        button.frame = bounds
        layoutDiskView()
    }
    
    private func show(completionHandler: @escaping (Bool) -> Void) {
        
        UIView.animate(withDuration: animationDuration, delay: 0, options: .curveEaseIn, animations: { [weak self] in
            self?.layoutDiskView()
        }, completion: { finished in
            completionHandler(finished)
        })
    }
    
    private func turn(to disk: Disk, completionHandler: @escaping (Bool) -> Void) {
        
        UIView.animate(withDuration: animationDuration / 2, delay: 0, options: .curveEaseOut, animations: { [weak self] in
            self?.layoutDiskView()
        }, completion: { [weak self] finished in
            guard let self = self else { return }
            if self.diskView.disk == self._disk {
                completionHandler(finished)
            }
            guard let diskAfter = self._disk else {
                completionHandler(finished)
                return
            }
            self.diskView.disk = diskAfter
            UIView.animate(withDuration: animationDuration / 2, animations: { [weak self] in
                self?.layoutDiskView()
            }, completion: { finished in
                completionHandler(finished)
            })
        })
    }
}

#endif

#if os(macOS)

extension CellView {
    
    public override func layout() {
        super.layout()
        
        button.frame = bounds
        layoutDiskView()
    }
    
    private func show(completionHandler: @escaping (Bool) -> Void) {
        
        let cellSize = bounds.size
        let diskDiameter = Swift.min(cellSize.width, cellSize.height) * 0.8
        let diskSize: CGSize
            diskSize = CGSize(width: diskDiameter, height: diskDiameter)
        diskView.animator().frame = CGRect(
            origin: CGPoint(x: (cellSize.width - diskSize.width) / 2, y: (cellSize.height - diskSize.height) / 2),
            size: diskSize
        )
        diskView.animator().alphaValue = 1.0
        
        completionHandler(true)
    }
    
    private func turn(to disk: Disk, completionHandler: @escaping (Bool) -> Void) {
        
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
                
                completionHandler(true)
            }
        }
    }
}
#endif


// MARK: Control Override
#if os(iOS)

extension CellView {
    
    public override func addTarget(_ target: Any?, action: Selector, for controlEvents: UIControl.Event) {
        button.addTarget(target, action: action, for: controlEvents)
    }
    
    public override func removeTarget(_ target: Any?, action: Selector?, for controlEvents: UIControl.Event) {
        button.removeTarget(target, action: action, for: controlEvents)
    }
    
    public override func actions(forTarget target: Any?, forControlEvent controlEvent: UIControl.Event) -> [String]? {
        button.actions(forTarget: target, forControlEvent: controlEvent)
    }
    
    public override var allTargets: Set<AnyHashable> {
        button.allTargets
    }
    
    public override var allControlEvents: UIControl.Event {
        button.allControlEvents
    }
}

#endif

#if os(macOS)

extension CellView {
    
    public override var target: AnyObject? {
        get { button.target }
        set { button.target = newValue }
    }
    
    public override var action: Selector? {
        get { button.action }
        set { button.action = newValue }
    }
}

#endif
