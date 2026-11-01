//
//  AudioPlayerView.swift
//  iPlay
//
//  Created by Shiv on 06/09/25.
//

import SwiftUI
import Combine
import VLCMediaLibraryKit
import VLCKit

// MARK: - AudioPlayerView
struct AudioPlayerView: View {
    @ObservedObject private var vmLyrics: LyricsViewModel = .init()
    @Binding var isShowPlayer: Bool
    @State private var isShowEqualizer: Bool = false
    @State private var isShareSheet: Bool = false
    @State private var isMoreOptions: Bool = false
    @State private var isShowPlaylist: Bool = false
    @State private var isBookmark: Bool = false
    @State private var isShowLyrics: Bool = false
    @State private var hearts: [LikeAnimationView] = []
    
    var callBack: ((Bool) -> Void)? = nil
        
    var body: some View {
        GeometryReader { geoProxy in
            ZStack {
                VStack {
                    VisualizerView()
                        .frame(width: geoProxy.size.width * 0.65, height: geoProxy.size.width * 0.65)
                        .padding(.top, 15)
                    TitleView(isShowLyrics: $isShowLyrics, hearts: $hearts)
                    Spacer()
                    PlaybackControlView(isShowPlaylist: $isShowPlaylist, isBookmark: $isBookmark)
                }
                ForEach(hearts) { heart in
                    heart
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaInset(edge: .top) {
                HStack(spacing: 10) {
                    Button {
                        isShowPlayer.toggle()
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 22, weight: .regular, design: .default))
                            .frame(width: 35, height: 35)
                            .background {
                                RoundedRectangle(cornerRadius: 5).fill(.ultraThinMaterial)
                            }
                    }
                    Spacer(minLength: 10)
                    HStack(spacing: 20) {
                        Button {
                            withAnimation {
                                isShowEqualizer.toggle()
                            }
                        } label: {
                            Image(systemName: "slider.vertical.3")
                                .font(.system(size: 22, weight: .thin, design: .default))
                                .frame(width: 35, height: 35)
                                .background {
                                    RoundedRectangle(cornerRadius: 5).fill(.ultraThinMaterial)
                                }
                        }
                        AirPlayButton()
                            .frame(width: 35, height: 35)
                            .background {
                                RoundedRectangle(cornerRadius: 5).fill(.ultraThinMaterial)
                            }
                        Button {
                            withAnimation {
                                isShareSheet.toggle()
                            }
                        } label: {
                            Image(systemName: "square.and.arrow.down")
                                .font(.system(size: 22, weight: .thin, design: .default))
                                .frame(width: 35, height: 35)
                                .background {
                                    RoundedRectangle(cornerRadius: 5).fill(.ultraThinMaterial)
                                }
                        }
                        
                        Button {
                            withAnimation {
                                isMoreOptions.toggle()
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.system(size: 22, weight: .thin, design: .default))
                                .frame(width: 35, height: 35)
                                .background {
                                    RoundedRectangle(cornerRadius: 5).fill(.ultraThinMaterial)
                                }
                        }
                    }
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity, maxHeight: 50)
            }
            .background {
                BackgroundColorView()
                    .cornerRadius(UIScreen.main.cornerRadius)
                    .ignoresSafeArea()
            }
            .onAppear(perform: {
                callBack?(false)
            })
            .sheet(isPresented: $isShareSheet) {
                ShareSheetView(items: [MediaPlayerManager.shared.currentVlcMedia.url!])
                    .ignoresSafeArea()
                    .presentationDetents([.medium])
                    .presentationBackground(.clear)
            }
            .sheet(isPresented: $isShowPlaylist, content: {
                PlaybackAudioQueueView()
                    .presentationDetents([.medium])
                    .presentationBackground(.clear)
            })
            ZStack {
                if isShowLyrics {
                    LyricsSearchView(dismiss: $isShowLyrics, vmLyrics: vmLyrics)
                        .transition(.opacity.combined(with: .blurReplace))
                }
            }
            
            ZStack {
                if isShowEqualizer {
                    EqualizerView(isPresented: $isShowEqualizer)
                        .transition(.move(edge: .bottom).combined(with: .move(edge: .bottom)))
                }
            }
            
            if isMoreOptions {
                MoreOptionsSettingView(isPresented: $isMoreOptions, playerType: .audio)
                    .transition(.move(edge: .bottom).combined(with: .move(edge: .bottom)))
            }
        }
        .statusBarHidden()
    }
}


// MARK: - VisualizerView
struct VisualizerView: View {
    @StateObject private var player: MediaPlayerManager = .shared
    var body: some View {
        GeometryReader { geoProxy in
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial.blendMode(.darken))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay {
                        switch player.selectedVisualizerType {
                        case .img:
                            WebImageView(iconSize:75, url: player.currentMLMedia?.thumbnail())
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                        case .wave:
                            // SiriWave Section (High Frequency Update)
                            SiriWaveView()
                                .power(power: player.power)
                                .supportLineColor(color: .theme)

                        case .line:
                            EmptyView()
                        case .circle:
                            MorphingSphereView(size: geoProxy.size)
                        }
                    }
                    .overlay(content: {
                        if player.selectedVisualizerType != .img {
                            BorderAnimationVisualizerView(audioPower: player.power, colors: player.colors)
                        }
                    })
                    .onTapGesture {
                        withAnimation(.smooth) {
                            cycleVisualizer()
                        }
                    }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    private func cycleVisualizer() {
        switch player.selectedVisualizerType {
        case .img: player.selectedVisualizerType = .line
        case .line: player.selectedVisualizerType = .wave
        case .wave: player.selectedVisualizerType = .circle
        case .circle: player.selectedVisualizerType = .img
        }
    }
}

// MARK: - TitleView
struct TitleView: View {
    @StateObject private var player: MediaPlayerManager = .shared
    @Binding var isShowLyrics: Bool
    @Binding var hearts: [LikeAnimationView]

    var body: some View {
            VStack(alignment: .center, spacing: 5) {
                MarqueeTextView(text: player.currentMLMedia?.title ?? "Unknown", leadingBuffer: 50)
                    .frame(height: 30)
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .font(.system(size: 20, weight: .bold, design: .default))
                    .lineLimit(1)
                    .padding(.horizontal, 35)
                    .clipped()
                HStack {
                    Button {
                        isShowLyrics.toggle()
                    } label: {
                        Image(systemName: "music.mic")
                            .foregroundStyle(.white)
                            .font(.system(size: 30, weight: .light, design: .default))
                            .frame(width: 35, height: 35)
                    }
                    Text(player.currentMLMedia?.artist?.name ?? "Unknown Artist")
                        .font(.system(size: 12, weight: .light, design: .default))
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, maxHeight: 50, alignment: .top)
                    
                    Button {
                        if player.currentMLMedia?.isFavorite() ?? false {
                            player.currentMLMedia?.setFavorite(false)
                        } else {
                            addHeart()
                            player.currentMLMedia?.setFavorite(true)
                        }
                        MediaLibraryService.shared.objectWillChange.send()
                    } label: {
                        Image(systemName: player.currentMLMedia?.isFavorite() == true ? "heart.fill" : "heart")
                            .foregroundStyle(player.currentMLMedia?.isFavorite() == true ? .red : .white)
                            .font(.system(size: 30, weight: .light, design: .default))
                            .frame(width: 35, height: 35)
                    }
                    
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .foregroundStyle(.white)
            .padding(5)
            .padding(.horizontal, 15)
    }
    
    func addHeart() {
        let newHeart = LikeAnimationView(duration: 0.75)
        hearts.append(newHeart)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
            hearts.removeAll { $0.id == newHeart.id }
        }
    }
}

// MARK: - PlaybackControlView
struct PlaybackControlView: View {
    @StateObject private var player: MediaPlayerManager = .shared
    
    @Binding var isShowPlaylist: Bool
    @Binding var isBookmark: Bool
    
    var body: some View {
        VStack {
            VStack {
                HorizontalBookmarkSlider(progress: $player.position, minValue: 0, maxValue: 1, bookmarks: player.currentMLMedia?.bookmarks?.compactMap { $0.time } ?? []) { (progress, isTracking) in
                    player.seek(to: Double(progress), isTracking: isTracking)
                } boomarkAction: { progress in
                    player.seek(to: Double(progress), isTracking: false)
                }
                .frame(height: 30)
                
                HStack {
                    Text(player.currentDuration.description)
                    Spacer()
                    Text(player.totalDuration.description)
                }
                .foregroundStyle(.white)
                .font(.system(size: 10, weight: .medium, design: .default))
            }
            
            VStack(spacing: 30) {
                HStack(spacing: 20) {
                    Button {
                        player.jumpBackward(sec: 10)
                    } label: {
                        Image(systemName: "gobackward.10")
                            .font(.system(size: 18, weight: .thin, design: .default))
                            .frame(maxWidth: 45, maxHeight: .infinity)
                    }
                    
                    Button {
                        player.previousPlay()
                    } label: {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 20, weight: .thin, design: .default))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    Capsule()
                        .stroke(.white.opacity(0.5), lineWidth: 5)
                        .frame(width: 55, height: 55)
                        .overlay {
                            Button {
                                self.player.playPause()
                            } label: {
                                Image(systemName: player.state == .playing ? "pause" : "play.fill")
                                    .font(.system(size: 30, weight: .bold, design: .default))
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                            }
                        }
                    Button {
                        player.nextPlay()
                    } label: {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 20, weight: .thin, design: .default))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    
                    Button {
                        player.jumpForward(sec: 10)
                    } label: {
                        Image(systemName: "goforward.10")
                            .font(.system(size: 18, weight: .thin, design: .default))
                            .frame(maxWidth: 45, maxHeight: .infinity)
                    }
                }
                .frame(height: 60)
                .padding(.horizontal, 35)
                HStack(spacing: 15) {
                    Button {
                        let currentTime = player.currentDuration.intValue
                        player.currentMLMedia?.addBookmark(atTime: Int64(currentTime))
                    } label: {
                        Image(systemName: (player.currentMLMedia?.bookmarks?.isEmpty ?? false) ? "bookmark.fill" : "bookmark")
                            .font(.system(size: 20, weight: .thin, design: .default))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    Button {
                        withAnimation(.bouncy) {
                            switch self.player.repeatMode {
                            case .doNotRepeat:
                                self.player.repeatMode = .repeatAllItems
                            case .repeatAllItems:
                                self.player.repeatMode = .repeatCurrentItem
                            case .repeatCurrentItem:
                                self.player.repeatMode = .doNotRepeat
                            default:
                                break
                            }
                        }
                    } label: {
                        Image(systemName: player.repeatMode == .repeatCurrentItem ? "repeat.1" : "repeat")
                            .font(.system(size: 20, weight: .thin, design: .default))
                            .foregroundStyle(player.repeatMode == .doNotRepeat ? .white : .theme)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    
                    Button {
                        withAnimation(.bouncy) {
                            player.isShuffle.toggle()
                        }
                    } label: {
                        Image(systemName: "shuffle")
                            .font(.system(size: 20, weight: .thin, design: .default))
                            .foregroundStyle(player.isShuffle ? Color.theme.gradient : Color.white.gradient)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    
                    SleepTimerView()
                    Button {
                        withAnimation(.bouncy, {
                            self.isShowPlaylist.toggle()
                        })
                    } label: {
                        Image(systemName: "music.note.list")
                            .font(.system(size: 20, weight: .thin, design: .default))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .frame(height: 45)
                .padding(.horizontal, 5)
            }
            .foregroundStyle(.white)
        }
        .padding(20)
    }
}

// MARK: - BackgroundColorView
struct BackgroundColorView: View {
    @StateObject private var player: MediaPlayerManager = .shared
        
    var body: some View {
        ZStack {
            WebImageView(url: player.currentVlcMedia.metaData.artworkURL)
            .ignoresSafeArea()
            BlurView(style: .systemMaterialDark)
                .ignoresSafeArea()
            LinearGradient(colors: [player.colors.0, player.colors.1.opacity(0.5), player.colors.2], startPoint: .bottomTrailing, endPoint: .topLeading)
                .ignoresSafeArea()
        }
    }
}

struct BorderAnimationVisualizerView: View {
    var audioPower: Double
    let colors: (Color, Color, Color)
    
    @State private var rotation: Double = 360
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.clear)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    colors.2,
                    lineWidth: 1
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .shadow(color: colors.0.opacity(min(audioPower, 1)), radius: 1)
        }
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

struct SleepTimerView: View {
    @StateObject private var player: MediaPlayerManager = .shared

    var body: some View {
        ZStack {
            Group {
                if player.remainingTime.isZero {
                    Menu {
                        Button {
                            MediaPlayerManager.shared.startSleepTimer(minutes: 10)
                        } label: {
                            Label("10 Minutes", systemImage: "stopwatch")
                        }
                        Button {
                            MediaPlayerManager.shared.startSleepTimer(minutes: 20)
                        } label: {
                            Label("20 Minutes", systemImage: "stopwatch")
                        }
                        Button {
                            MediaPlayerManager.shared.startSleepTimer(minutes: 45)
                        } label: {
                            Label("45 Minutes", systemImage: "stopwatch")
                        }
                        
                        Button {
                            MediaPlayerManager.shared.startSleepTimer(minutes: 60)
                        } label: {
                            Label("1 Hour", systemImage: "stopwatch")
                        }
                        
                    } label: {
                        Image(systemName: "stopwatch")
                            .font(.system(size: 20, weight: .thin, design: .default))
                            .foregroundStyle(.white)
                    }
                    
                } else {
                    Button {
                        withAnimation(.bouncy) {
                            
                            MediaPlayerManager.shared.cancelSleepTimer()
                        }
                    } label: {
                        VStack {
                            if player.remainingTime.isZero {
                                Image(systemName: "stopwatch")
                                    .font(.system(size: 20, weight: .thin, design: .default))
                                    .foregroundStyle(.white)
                            } else {
                                Image(systemName: "xmark")
                                    .font(.system(size: 20, weight: .thin, design: .default))
                                    .foregroundStyle(.gray.gradient)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .top) {
                if !player.remainingTime.isZero {
                    Text(player.remainingTime.toDisplayTime())
                        .font(.system(size: 12, weight: .light, design: .default))
                        .monospacedDigit()
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(.theme.opacity(0.25)))
                        .offset(y: -15)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}


#Preview {
    AudioPlayerView(isShowPlayer: .constant(false))
}
