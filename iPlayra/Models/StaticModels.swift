//
//  StaticModels.swift
//  iPlay
//
//  Created by Shiv on 07/09/25.
//

import SwiftUI
import Foundation
import VLCMediaLibraryKit

// MARK: - Player Decoder Model
//enum DecoderType: String, CaseIterable, Hashable {
//    case hwDecoder = "HW Decoder", swDecoder = "SW Decoder"
//    
//    var codacOptions: [Any] {
//        switch self {
//        case .hwDecoder:
//            return [
//                // 🚀 HW Decoder (VideoToolbox)
//                "--codec=videotoolbox",
//                "--network-caching=2000",
//                "--live-caching=2000",
//                "--file-caching=1000",
//                "--clock-synchro=0",
//                "--skip-frames",
//                "--vout=opengles",
//                "-vvv",
//            ]
//            
//        case .swDecoder:
//            return [
//                // 🛠️ SW Decoder (AVCodec)
//                "--codec=avcodec",
//                "--avcodec-fast",
//                "--avcodec-threads=4",
//                "--network-caching=2000",
//                "--live-caching=2000",
//                "--file-caching=1000",
//                "--clock-synchro=0",
//                "--skip-frames",
//                "--vout=opengles",
//                "-vvv",
//            ]
//        }
//    }
//}

enum DecoderType: String, CaseIterable, Hashable {
    case hwDecoder = "HW Decoder"
    case swDecoder = "SW Decoder"
    
    // Ye method [AnyHashable: Any] return karega jo seedha addOptions me jayega
    var codecOptions: [AnyHashable: Any] {
        // --- Common Options (Dono ke liye same) ---
        var options: [AnyHashable: Any] = [
            "network-caching": 2000,
            "live-caching": 1000,
            "file-caching": 3000,
            ":rtsp-tcp": true,           // TCP connection for stability
            ":rtp-timeout": 10000,
            "clock-jitter": 500,         // High-res files ke liye thoda jitter buffer
            "drop-late-frames": true,    // Lag rokne ke liye
            "skip-frames": true          // Sync banaye rakhne ke liye
        ]
        
        // --- Specific Decoder Options ---
        switch self {
        case .hwDecoder:
            options[":codec"] = "videotoolbox"  // Hardware acceleration
            options[":hwdec"] = "videotoolbox"
            
        case .swDecoder:
            options[":codec"] = "avcodec"       // Software decoding
            options["avcodec-threads"] = 4      // 4K/8K ke liye CPU power
            options["avcodec-fast"] = true      // Fast decoding mode
            options[":vcodec"] = "h264"         // Specific codec hint
        }
        
        return options
    }
}

// MARK: - PlayBack Speed Model
enum PlayBackSpeed: Float, CaseIterable, Hashable {
    case superSlow = 0.25, slow = 0.5, normal = 1.0, fast = 2.0, superFast = 3.0, superPower = 4.0
}

enum FileImportType: String, CaseIterable, Hashable {
    case fileManager, gallery, wifi
    
    var icon: String {
        switch self {
        case .fileManager:
            return "folder.badge.plus.fill"
        case .gallery:
            return "rectangle.stack.badge.play.fill"
        case .wifi:
            return "tv.badge.wifi"
        }
    }
    
    var color: Color {
        switch self {
        case .fileManager:
            return .blue
        case .gallery:
            return .orange
        case .wifi:
            return .red
        }
    }
}

// MARK: - FilterType Model
enum SortByType: String, Hashable, CaseIterable {
    case date, name, size, length
}

enum CellMenuButtonActionType: String {
    case delete, info, share, play
}

enum MusicTopTab: String, CaseIterable, Hashable {
    case allSongs, albums, artists, genres, playlists
    
    var title: String {
        switch self {
        case .allSongs: return "kAllSongs"
        case .albums: return "kAlbum"
        case .artists: return "kArtist"
        case .genres: return "kGenres"
        case .playlists: return "kPlaylist"
        }
    }
}

enum SettingTabType: String, CaseIterable, Hashable {
    case general, video, audio, download, subscription, privacyPolicy, about
    var title: String {
        switch self {
        case .general: return "kGeneral"
        case .video: return "Video"
        case .audio: return "kAudio"
        case .download: return "kDownload"
        case .subscription: return "Subscription"
        case .privacyPolicy: return "kPrivacyPolicy"
        case .about: return "kAbout"
        }
    }
    
    var subTitle: String {
        switch self {
        case .general: return "kLanguageHistory"
        case .video: return "kVideoPlayerControlsSettingsOptions"
        case .audio: return "kAudioPlayerControlsSettingsOptions"
        case .download: return "kFileUrlAndStorage"
        case .subscription: return "kSubscriptionDetails"
        case .privacyPolicy: return "kAppDataPermissionsSafeAndSecure"
        case .about: return "kAppVersionAndCopyright"
        }
    }
    
    var icon: String {
        switch self {
        case .general: return "iphone.smartbatterycase.gen2"
        case .video: return "play.circle"
        case .audio: return "headphones"
        case .download: return "square.and.arrow.down"
        case .subscription: return "crown.fill"
        case .privacyPolicy: return "hand.raised"
        case .about: return "info.circle"
        }
    }
}

// MARK: - Aspect Ratio Model
enum AspectRatio: String, Hashable, CaseIterable {
    case fullScreen = "device"
    case original = ""
    case sixteenNine = "16:9"         // Widescreen (Default for HD videos)
    case fourThree = "4:3"           // Standard definition video (Old TVs)
    case oneOne = "1:1"              // Square video (Instagram-style)
    case twentyOneNine = "21:9"      // Cinematic widescreen
    case nineSixteen = "9:16"        // Vertical video (TikTok, Instagram Reels)
    case threeTwo = "3:2"            // Photography format (DSLR style)
    case twoPointThirtyFiveOne = "2.35:1" // CinemaScope (Theater-style)
    case fiveFour = "5:4" // Standard square format
    
    var size: CGSize {
        switch self {
        case .fullScreen:
            return .init(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        case .original:
            return .zero
        case .sixteenNine:
            return .init(width: 16, height: 9)
        case .fourThree:
            return .init(width: 20, height: 15)
        case .oneOne:
            return .init(width: 20, height: 20)
        case .twentyOneNine:
            return .init(width: 21, height: 9)
        case .nineSixteen:
            return .init(width: 15, height: 20)
        case .threeTwo:
            return .init(width: 21, height: 14)
        case .twoPointThirtyFiveOne:
            return .init(width: 21.15, height: 9)
        case .fiveFour:
            return .init(width: 20, height: 16)
        }
    }
}


struct GlobalStorage {
    @AppStorage("APP_LAUNCH_COUNTER") static var appLaunchCount: Int = 0
    @AppStorage("INTRO_SEEN") static var hasIntroSheen: Int = 0
    @AppStorage("DECODER_TYPE") static var decoderType: DecoderType = .swDecoder
}

extension VLCMLMedia: @retroactive Identifiable {
    public var id: String {
        if let mrl = self.mainFile()?.mrl {
            return mrl.description
        } else {
            return "\(ObjectIdentifier(self).hashValue)"
        }
    }
}

struct IdentifiableMedia: Identifiable, Equatable {
    let id: String
    let media: VLCMLMedia

    init(media: VLCMLMedia) {
        self.media = media
        self.id = media.identifier().description
    }

    static func == (lhs: IdentifiableMedia, rhs: IdentifiableMedia) -> Bool {
        return lhs.id == rhs.id
    }
}
