//
//  TipModels.swift
//  iPlay
//
//  Created by Shiv on 24/10/25.
//

import Foundation
import SwiftUI
import TipKit

struct HDRTip: Tip {
    var title: Text {
        Text("HDR Change")
            .foregroundStyle(.teal)
    }
    var message: Text? {
        Text("HDR is a visual enhancement that simulates the appearance of high dynamic range images.")
    }
    
    var image: Image? {
        Image(systemName: "sparkles")
    }
}

struct AISubTitleTranslationTip: Tip {
    var title: Text {
        Text("AI subtitle translation")
            .foregroundStyle(.teal)
    }
    
    var message: Text? {
        Text("AI-powered subtitle translation is not available yet. Stay tuned for updates!")
    }
    
    var image: Image? {
        Image(systemName: "envelope.front.rtl")
    }
}
