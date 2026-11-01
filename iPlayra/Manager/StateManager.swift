//
//  StateManager.swift
//  iPlayra
//
//  Created by Shiv on 28/10/26.
//

import SwiftUI
import Combine

class StateManager: ObservableObject {
    static let shared: StateManager = .init()
    
    @AppStorage("isIntro") var isIntro: Bool = true
    @AppStorage("hasPurchased") var hasPurchased: Bool = false
    
    @Published var isSplash: Bool = true
    @Published var isShowAudioPlayer: Bool = false
    @Published var showFullPlayer = false
    @Published var isShowPurchase: Bool = false
}
