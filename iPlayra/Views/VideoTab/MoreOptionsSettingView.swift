//
//  MoreSettingsView.swift
//  iPlay
//
//  Created by Shiv on 05/10/25.
//

import SwiftUI
import VLCKit

enum RepeatModeType: String, CaseIterable {
    case repeatCurrentItem, repeatAllItems, doNotRepeat, shuffle
    var icon: String {
        switch self {
        case .repeatAllItems: return "repeat"
        case .repeatCurrentItem: return "repeat.1"
        case .doNotRepeat: return "music.note.list"
        case .shuffle: return "shuffle"
        }
    }
}

enum MoreSettingsOption: String, Hashable, CaseIterable {
    case mirror, screenShot, timer, bookmark, favorite, about
    
    var title: String {
        switch self {
        case .mirror: return "Mirror"
        case .screenShot: return "Screen Shot"
        case .timer: return "Timer"
        case .bookmark: return "Bookmark"
        case .favorite: return "Favorite"
        case .about: return "About"
        }
    }
    
    var icon: String {
        switch self {
        case .mirror: return "trapezoid.and.line.horizontal"
        case .screenShot: return "arrow.turn.up.forward.iphone"
        case .timer: return "clock"
        case .bookmark: return "bookmark"
        case .favorite: return "star"
        case .about: return "info.circle"
        }
    }
}

enum VideoPlayerMoreAboutSetting: String, Hashable, CaseIterable {
    case editPlayer, tutorials, fileInfo, feedback
    
    var title: String {
        switch self {
        case .editPlayer: return "Edit Player"
        case .tutorials: return "Tutorials"
        case .fileInfo: return "File Info"
        case .feedback: return "Feedback"
        }
    }
    
    var icon: String {
        switch self {
        case .editPlayer: return "square.and.pencil"
        case .tutorials: return "book"
        case .fileInfo: return "info.circle"
        case .feedback: return "bubble.left.and.text.bubble.right"
        }
    }
}

struct MoreOptionsSettingView: View {
    @Binding var isPresented: Bool
    var playerType: PlayerType = .video
    @State private var currentOrientation: UIDeviceOrientation = UIDevice.current.orientation
        
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: isPortrait(geometry: geometry) ? .bottom : .leading) {
                Color.black.opacity(0.0001).ignoresSafeArea()
                    .onTapGesture {
                        isPresented.toggle()
                    }
                ZStack {
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 10) {
                            Text("Playback speed")
                                .font(.system(size: 13, weight: .light, design: .default))
                                .foregroundStyle(.gray.gradient)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 20)
                            PlaybackSpeedLimitTabView()
                                .padding(.horizontal, 20)
                                .padding(.bottom, 20)
                            Text("Repeat Mode")
                                .font(.system(size: 13, weight: .light, design: .default))
                                .foregroundStyle(.gray.gradient)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 20)
                            if playerType == .video {
                                RepeatModeView()
                                .padding(.horizontal, 20)
                                .padding(.bottom, 20)
                            }
                            Text("Playback Decoder")
                                .font(.system(size: 13, weight: .light, design: .default))
                                .foregroundStyle(.gray.gradient)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 20)
                            PlaybackDecoderTabView()
                                .padding(.horizontal, 20)
                            if playerType == .video {
                                VStack {
                                    Text("More")
                                        .font(.system(size: 13, weight: .light, design: .default))
                                        .foregroundStyle(.gray.gradient)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    VideoPlayerMoreAboutView { tapType in
                                        switch tapType {
                                        case .editPlayer:
                                            print("Edit Player")
                                        case .tutorials:
                                            print("Tutorials")
                                        case .fileInfo:
                                            print("File Info")
                                        case .feedback:
                                            print("Feedback")
                                        }
                                    }
                                }
                                .frame(height: 100)
                                .padding(20)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .safeAreaInset(edge: .top) {
                        HStack {
                            Button {
                                withAnimation(.bouncy) {
                                    isPresented.toggle()
                                }
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 18, weight: .regular, design: .default))
                                    .foregroundStyle(.gray.gradient)
                                    .frame(width: 35, height: 35)
                                    .background(Capsule().fill(.ultraThinMaterial))
                            }
                            .padding(10)
                            Spacer(minLength: 0)
                        }
                    }
                }
                .frame(width: isPortrait(geometry: geometry) ? geometry.size.width : geometry.size.width / 2, height: isPortrait(geometry: geometry) ? geometry.size.height / 2 : geometry.size.height)
                .background(BlurView(style: .dark).cornerRadius(20).ignoresSafeArea())
                .animation(.linear, value: currentOrientation)
            }
        }
    }
    func isPortrait(geometry: GeometryProxy) -> Bool {
        return geometry.size.height > geometry.size.width
    }
}

struct VideoPlayerMoreAboutView: View {
    var tapAcction: ((VideoPlayerMoreAboutSetting) -> Void)?
    
    var body: some View {
        ZStack {
            LazyHStack(spacing: 30) {
                ForEach(VideoPlayerMoreAboutSetting.allCases, id: \.rawValue) { type in
                    VStack {
                        Button {
                            tapAcction?(type)
                        } label: {
                            Image(systemName: type.icon)
                                .foregroundStyle(Color("#ffffff").gradient)
                                .font(.system(size: 16, weight: .light, design: .default))
                                .frame(width: 35, height: 35)
                                .background {
                                    Capsule().fill(.clear)
                                        .overlay {
                                            Capsule().stroke(.gray.gradient, lineWidth: 1)
                                        }
                                }
                        }
                        Text(type.title)
                            .foregroundStyle(Color("#ffffff").gradient)
                            .font(.system(size: 12, weight: .regular, design: .default))
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    MoreOptionsSettingView(isPresented: .constant(false))
}

struct PlaybackSpeedLimitTabView: View {
    @State private var speedLimit: Float = 0.25
    
    @Namespace private var animation
    
    var body: some View {
        ZStack {
            Capsule().fill(.ultraThinMaterial)
                .frame(height: 35)
                .overlay {
                    Capsule().stroke(.gray.gradient.opacity(0.25), lineWidth: 1)
                }
                .overlay {
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack {
                            ForEach(PlayBackSpeed.allCases, id: \.rawValue) { speed in
                                Text("\(String(format: "%.1f", speed.rawValue))x")
                                    .font(.system(size: 14, weight: .medium, design: .default))
                                    .frame(maxHeight: .infinity)
                                    .frame(width: 70)
                                    .background {
                                        if speedLimit == speed.rawValue {
                                            Capsule().fill(.theme.gradient)
                                                .matchedGeometryEffect(id: "SPEED", in: animation)
                                        }
                                    }
                                    .onTapGesture {
                                        withAnimation(.bouncy) {
                                            speedLimit = speed.rawValue
                                        }
                                        MediaPlayerManager.shared.playbackRate = speed.rawValue
                                    }
                            }
                        }
                        .padding(1)
                    }
                    .cornerRadius(.infinity)
                    .scrollPosition(id: .init(get: {
                        return speedLimit
                    }, set: { _ in
                        
                    }), anchor: .center)
                }
        }
        .onAppear {
            speedLimit = MediaPlayerManager.shared.playbackRate
        }
    }
}

struct PlaybackDecoderTabView: View {
    @State private var decoderType: DecoderType = .swDecoder
    
    @Namespace private var animation
    
    var body: some View {
        ZStack {
            Capsule().fill(.ultraThinMaterial)
                .frame(height: 40)
                .overlay {
                    Capsule()
                        .stroke(.gray.gradient.opacity(0.25), lineWidth: 1)
                }
                .overlay {
                    HStack {
                        ForEach(DecoderType.allCases, id: \.self) { type in
                                Text(type.rawValue)
                                .font(.system(size: 14, weight: .medium, design: .default))
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background {
                                    if type == decoderType {
                                        Capsule().fill(.theme.gradient)
                                            .matchedGeometryEffect(id: "DECODER", in: animation)
                                    }
                                }
                                .onTapGesture {
                                    withAnimation(.bouncy) {
                                        decoderType = type
                                        MediaPlayerManager.shared.decoderType = type
                                    }
                                }
                        }
                    }
                    .padding(1)
                }
        }
        .onAppear {
            decoderType = MediaPlayerManager.shared.decoderType
        }
    }
}

struct RepeatModeView: View {
    
    @State private var selectedRepeatMode: RepeatModeType = .doNotRepeat
    
    @Namespace private var animation
    
    var body: some View {
        HStack {
            ForEach(RepeatModeType.allCases, id: \.rawValue) { repeatMode in
                Image(systemName: repeatMode.icon)
                    .font(.system(size: 16, weight: .medium, design: .default))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background {
                        if selectedRepeatMode == repeatMode {
                            Capsule().fill(.theme.gradient)
                                .matchedGeometryEffect(id: "REPEAT_MODE", in: animation)
                        }
                    }
                    .onTapGesture {
                        withAnimation(.bouncy) {
                            selectedRepeatMode = repeatMode
                        }
                        switch selectedRepeatMode {
                        case .repeatCurrentItem:
                            MediaPlayerManager.shared.isShuffle = false
                            MediaPlayerManager.shared.repeatMode = .repeatCurrentItem
                        case .repeatAllItems:
                            MediaPlayerManager.shared.isShuffle = false
                            MediaPlayerManager.shared.repeatMode = .repeatAllItems
                        case .doNotRepeat:
                            MediaPlayerManager.shared.isShuffle = false
                            MediaPlayerManager.shared.repeatMode = .doNotRepeat
                        case .shuffle:
                            MediaPlayerManager.shared.isShuffle = true
                        }
                    }
                    
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 35)
        .background(Capsule().fill(.ultraThinMaterial))
        .onAppear {
            if MediaPlayerManager.shared.isShuffle {
                selectedRepeatMode = .shuffle
            } else {
                switch MediaPlayerManager.shared.repeatMode {
                case .doNotRepeat:
                    selectedRepeatMode = .doNotRepeat
                case .repeatAllItems:
                    selectedRepeatMode = .repeatAllItems
                case .repeatCurrentItem:
                    selectedRepeatMode = .repeatCurrentItem
                default:
                    break;
                }
            }
        }
    }
}
