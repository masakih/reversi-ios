//
//  Alert.swift
//  Reversi
//
//  Created by Hori,Masaki on 2020/05/16.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

#if os(iOS)
import UIKit
#elseif os(macOS)
import Cocoa
#endif

public class Alert {
    
    let title: String
    let message: String
    
    init(title: String, message: String) {
        
        self.title = title
        self.message = message
    }
    
    private var actions: [AlertAction] = []
    
    func addAction(_ action: AlertAction) {
        
        actions.append(action)
    }
    
    #if os(iOS)
    func show(for owner: UIViewController) {
        
        let alertController = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        
        actions.map { action in
            
            UIAlertAction(
                title: action.title,
                style: UIAlertAction.Style(rawValue: action.style.rawValue)!) { _ in
                    
                    action.handler?(action)
            }
        }
        .forEach { action in
            
            alertController.addAction(action)
        }
        
        owner.present(alertController, animated: true)
        
    }
    #elseif os(macOS)
    func show(for owner: NSViewController) {
        
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        actions.forEach { action in
            
            alert.addButton(withTitle: action.title)
        }
        alert.beginSheetModal(for: owner.view.window!) { res in
                        
            let index: Int
            switch res {
            
            case .alertFirstButtonReturn: index = 0
            case .alertSecondButtonReturn: index = 1
            case .alertThirdButtonReturn: index = 2
                
            default: fatalError()
            }
            
            guard self.actions.count > index else { fatalError() }
            
            let action = self.actions[index]
            action.handler?(action)
        }
    }
    #endif
}

struct AlertAction {
    
    enum Style: Int {
           
           case `default` = 0
           
           case calcel = 1
           
           case destructive = 2
       }
    
    let title: String
    let style: Style
    var enabled: Bool = true
    let handler: ((AlertAction) -> Void)?
}
