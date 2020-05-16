
#if os(iOS)
import UIKit
#elseif os(macOS)
import Cocoa
#endif

public class DiskView: PlatformView {
    /// このビューが表示するディスクの色を決定します。
    public var disk: Disk = .dark {
        didSet { setNeedsDisplay() }
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
        backgroundColor = .clear
        isUserInteractionEnabled = false
    }

    override public func draw(_ rect: CGRect) {
        guard let context = CGContext.current else { return }
        context.setFillColor(disk.cgColor)
        context.fillEllipse(in: bounds)
    }
}

extension Disk {
    fileprivate var color: Color {
        switch self {
        case .dark: return Color(named: "DarkColor")!
        case .light: return Color(named: "LightColor")!
        }
    }
    
    fileprivate var cgColor: CGColor {
        color.cgColor
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
