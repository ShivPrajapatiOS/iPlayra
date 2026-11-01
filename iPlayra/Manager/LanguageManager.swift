//
//  LanguageManager.swift
//  iPlay
//
//  Created by Shiv on 16/10/25.
//

import SwiftUI
import Combine

struct AppLanguage: Identifiable {
    let id = UUID()
    let code: String
    let name: String
}

class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    let availableLanguages: [AppLanguage] = [
        AppLanguage(code: "en", name: "English"),
        AppLanguage(code: "hi", name: "Hindi"),
        AppLanguage(code: "ja", name: "Japanese"),
        AppLanguage(code: "es", name: "Spanish"),
        AppLanguage(code: "gu", name: "Gujarati"),
        AppLanguage(code: "pa", name: "Punjabi"),
        AppLanguage(code: "zh-Hans", name: "Chinese Simplified"),
        AppLanguage(code: "fr", name: "French"),
        AppLanguage(code: "ru", name: "Russian"),
        AppLanguage(code: "ko", name: "Korean")
    ]

    @AppStorage("AppLanguage") var currentLanguage: String = "en" {
        didSet {
            Bundle.setLanguage(currentLanguage)
            objectWillChange.send()
        }
    }

    private init() {
        Bundle.setLanguage(currentLanguage)
    }
}


private var bundleKey: UInt8 = 0

class LocalizedBundle: Bundle, @unchecked Sendable {
    override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        guard let bundle = objc_getAssociatedObject(self, &bundleKey) as? Bundle else {
            return super.localizedString(forKey: key, value: value, table: tableName)
        }
        return bundle.localizedString(forKey: key, value: value, table: tableName)
    }
}

extension Bundle {
    static func setLanguage(_ language: String) {
        defer { object_setClass(Bundle.main, LocalizedBundle.self) }
        let path = Bundle.main.path(forResource: language, ofType: "lproj") ?? ""
        let value = path.isEmpty ? nil : Bundle(path: path)
        objc_setAssociatedObject(Bundle.main, &bundleKey, value, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}

extension String {
    func localized() -> String {
        NSLocalizedString(self, comment: "")
    }
}
