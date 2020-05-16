//
//  Color.swift
//  Reversi
//
//  Created by Hori,Masaki on 2020/05/16.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

#if os(iOS)

import UIKit

public typealias Color = UIColor

#elseif os(macOS)

import Cocoa

public typealias Color = NSColor

#endif

