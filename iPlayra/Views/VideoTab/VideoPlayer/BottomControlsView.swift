//
//  BottomControlsView.swift
//  iPlay
//
//  Created by Shiv on 07/03/26.
//

import SwiftUI
import VLCMediaLibraryKit
import VLCKit

// MARK: - HeaderView
struct TopControlsView: View {
    @StateObject private var player: MediaPlayerManager = .shared
    let safeArea: EdgeInsets
    @Binding var showPlayerControls: Bool
    @Binding var showVideoPlayer: Bool
    @Binding var isShowHDR: Bool
    @Binding var isShowSubtitle: Bool
    @Binding var isShowAudioTrack: Bool
    @Binding var isShowMoreSettings: Bool
    
    var backAction: (() -> Void)?
    
    var body: some View {
        HStack(spacing: 10) {
            Button {
                backAction?()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .regular, design: .default))
                    .frame(maxWidth: 35, maxHeight: 35)
                    .background {
                        RoundedRectangle(cornerRadius: 5).fill(.ultraThinMaterial)
                    }
            }
            MarqueeTextView(text: player.currentMLMedia?.title ?? "Unknown", leadingBuffer: 10)
                .frame(height: 30)
                .frame(minWidth: 0, maxWidth: .infinity)
                .font(.system(size: 17, weight: .bold, design: .default))
                .lineLimit(1)
                .clipped()
            Spacer(minLength: 10)
            Button {
                withAnimation {
                    isShowHDR.toggle()
                }
            } label: {
                Text("HDR")
                    .foregroundStyle(LinearGradient(colors: [.theme, .purple, .blue], startPoint: .bottomLeading, endPoint: .topTrailing))
                    .font(.system(size: 15, weight: .bold, design: .default))
                    .frame(maxWidth: 35, maxHeight: 35)
                    .background {
                        RoundedRectangle(cornerRadius: 5).fill(.ultraThinMaterial)
                    }
            }
            Button {
                withAnimation {
                    isShowSubtitle.toggle()
                }
            } label: {
                Image(systemName: "list.bullet.rectangle")
                    .font(.system(size: 20, weight: .thin, design: .default))
                    .frame(maxWidth: 35, maxHeight: 35)
                    .background {
                        RoundedRectangle(cornerRadius: 5).fill(.ultraThinMaterial)
                    }
            }
            Button {
                withAnimation {
                    isShowAudioTrack.toggle()
                }
            } label: {
                Image(systemName: "music.note.list")
                    .font(.system(size: 20, weight: .thin, design: .default))
                    .frame(maxWidth: 35, maxHeight: 35)
                    .background {
                        RoundedRectangle(cornerRadius: 5).fill(.ultraThinMaterial)
                    }
            }
            
            Button {
                withAnimation {
                    isShowMoreSettings.toggle()
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 20, weight: .thin, design: .default))
                    .frame(maxWidth: 35, maxHeight: 35)
                    .background {
                        RoundedRectangle(cornerRadius: 5).fill(.ultraThinMaterial)
                    }
            }
            
            
        }
        .padding(.horizontal, 10)
        .foregroundStyle(.white.gradient)
        .frame(maxWidth: .infinity, maxHeight: 50)
        .offset(y: showPlayerControls ? 0 : -(50 + safeArea.top))
        .animation(.easeInOut, value: showPlayerControls)
        .opacity(showPlayerControls ? 1 : 0)
    }
}

struct BottomControlsView: View {
    @StateObject private var player: MediaPlayerManager = .shared
    let safeArea: EdgeInsets
    @Binding var showPlayerControls: Bool
    @Binding var isShowPlaylist: Bool
    @Binding var aspectRatio: AspectRatio
    @Binding var thumbOffset: CGFloat
    @Binding var showPreview: Bool
    @State private var isDragging: Bool = false

    
    var timeoutControlsAction: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 0) {
                HStack {
                    Text(player.currentDuration.description)
                    Spacer(minLength: 0)
                    Text(player.totalDuration.description)
                }
                .foregroundStyle(.white.gradient)
                .font(.system(size: 10, weight: .thin, design: .default))
                VideoSeekSlider(progress: $player.position, minValue: 0, maxValue: 1) { (progress, dragging, offset) in
                    thumbOffset = offset
                    isDragging = dragging
                    withAnimation(.easeInOut(duration: 0.1)) {
                        self.showPreview = dragging
                    }
                    self.player.seek(to: Double(progress), isTracking: dragging)
                    if dragging {
                        showPlayerControls = dragging
                    } else {
                        timeoutControlsAction?()
                    }
                }
                .frame(height: 35)
                .onChange(of: player.position) { (_, newValue) in
                    if isDragging {
                        player.generatePreview(position: Double(newValue))
                    }
                }
            }
            .padding(.horizontal, 6)
            HStack(spacing: 10) {
                Button {
                    player.playPause()
                } label: {
                    Image(systemName: player.state == .playing ? "pause.fill" : "play.fill")
                        .font(.system(size: 45, weight: .thin, design: .default))
                        .frame(maxWidth: 50, maxHeight: 50)
                }
                
                Button {
                    player.previousPlay()
                } label: {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 25, weight: .thin, design: .default))
                        .frame(maxWidth: 40, maxHeight: 40)
                }
                Button {
                    player.nextPlay()
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 25, weight: .thin, design: .default))
                        .frame(maxWidth: 40, maxHeight: 40)
                }
                Spacer()
                Button {
                    switch aspectRatio {
                    case .fullScreen:
                        aspectRatio = .original
                    case .original:
                        aspectRatio = .sixteenNine
                    case .sixteenNine:
                        aspectRatio = .fourThree
                    case .fourThree:
                        aspectRatio = .oneOne
                    case .oneOne:
                        aspectRatio = .twentyOneNine
                    case .twentyOneNine:
                        aspectRatio = .nineSixteen
                    case .nineSixteen:
                        aspectRatio = .threeTwo
                    case .threeTwo:
                        aspectRatio = .twoPointThirtyFiveOne
                    case .twoPointThirtyFiveOne:
                        aspectRatio = .fiveFour
                    case .fiveFour:
                        aspectRatio = .fullScreen
                    }
                    player.setAspectRatio(aspectRatio)
                } label: {
                    ZStack {
                        Group(content: {
                            switch aspectRatio {
                            case .fullScreen:
                                Image(systemName: "arrow.up.right.and.arrow.down.left.rectangle")
                                    .foregroundStyle(.theme.gradient)
                                    .font(.system(size: 20, weight: .thin, design: .default))
                            case .original:
                                Image(systemName: "arrow.up.right.and.arrow.down.left.rectangle")
                                    .foregroundStyle(.white)
                                    .font(.system(size: 20, weight: .thin, design: .default))
                            case .sixteenNine:
                                Text(aspectRatio.rawValue)
                                    .frame(width: 24, height: 17)
                            case .fourThree:
                                Text(aspectRatio.rawValue)
                                    .frame(width: 24, height: 23)
                            case .oneOne:
                                Text(aspectRatio.rawValue)
                                    .frame(width: 22, height: 24)
                            case .twentyOneNine:
                                Text(aspectRatio.rawValue)
                                    .frame(width: 24, height: 12)
                            case .nineSixteen:
                                Text(aspectRatio.rawValue)
                                    .frame(width: 17, height: 24)
                            case .threeTwo:
                                Text(aspectRatio.rawValue)
                                    .frame(width: 24, height: 20)
                            case .twoPointThirtyFiveOne:
                                Text(aspectRatio.rawValue)
                                    .frame(width: 23.35, height: 20)
                            case .fiveFour:
                                Text(aspectRatio.rawValue)
                                    .frame(width: 20, height: 20)
                            }
                        })
                        .font(.system(size: 8, weight: .thin, design: .default))
                        .background {
                            if aspectRatio != .original && aspectRatio != .fullScreen {
                                Rectangle().fill(.theme.gradient.opacity(0.25))
                                    .overlay {
                                        Rectangle().stroke(.theme.gradient, lineWidth: 1)
                                    }
                            }
                        }
                    }
                    .frame(maxWidth: 35, maxHeight: 35)
                    .background {
                        RoundedRectangle(cornerRadius: 5).fill(.ultraThinMaterial)
                    }
                }
                Button {
                    withAnimation(.linear) {
                        isShowPlaylist.toggle()
                    }
                } label: {
                    Image(systemName: "list.and.film")
                        .font(.system(size: 20, weight: .thin, design: .default))
                        .frame(maxWidth: 35, maxHeight: 35)
                        .background {
                            RoundedRectangle(cornerRadius: 5).fill(.ultraThinMaterial)
                        }
                }
                Button {
//                    player.togglePiP()
//                    if AppDelegate.orientationLock == .all {
//                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
//                            windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
//                        }
//                        AppDelegate.orientationLock = .portrait
//                        UIViewController.attemptRotationToDeviceOrientation()
//                    }
                    withAnimation(.spring(response: 0.7, dampingFraction: 0.9)) {
                        player.isPiPActive ? player.stopPiP() : player.startPiP()
                    }
                } label: {
                    Image(systemName: "rectangle.on.rectangle")
                        .font(.system(size: 20, weight: .thin, design: .default))
                        .frame(maxWidth: 35, maxHeight: 35)
                        .background {
                            RoundedRectangle(cornerRadius: 5).fill(.ultraThinMaterial)
                        }
                }
                .disabled(!player.isPiPReady)
            }
        }
        .foregroundStyle(.white.gradient)
        .padding(.horizontal, 10)
        .offset(y: showPlayerControls ? 0 : (110 + safeArea.bottom))
        .animation(.easeInOut, value: showPlayerControls)
        .opacity(showPlayerControls ? 1 : 0)
    }
}

struct MiddleControlsView: View {
    @StateObject private var player: MediaPlayerManager = .shared
    let safeArea: EdgeInsets
    @Binding var showPlayerControls: Bool
    @Binding var isLock: Bool
    @Binding var isShowEqualizer: Bool
    
    var body: some View {
        VStack(spacing: 50) {
            HStack {
                Button {
                    withAnimation {
                        player.isMuted()
                    }
                } label: {
                    Image(systemName: "speaker.slash")
                        .foregroundStyle(player.isMute ? Color.theme.gradient : Color.white.gradient)
                        .font(.system(size: 20, weight: .thin, design: .default))
                        .frame(maxWidth: 35, maxHeight: 35)
                        .background {
                            RoundedRectangle(cornerRadius: 5).fill(.ultraThinMaterial)
                        }
                }
                .offset(x: showPlayerControls ? 0 : -(35 + safeArea.trailing))
                .animation(.easeInOut, value: showPlayerControls)
                Spacer(minLength: 0)
                Button {
                    AppDelegate.orientationLock = (AppDelegate.orientationLock == .portrait) ? .all : .portrait
                    UIViewController.attemptRotationToDeviceOrientation()
                } label: {
                    Image(systemName: "rectangle.landscape.rotate")
                        .foregroundStyle(.white.gradient)
                        .font(.system(size: 20, weight: .thin, design: .default))
                        .frame(maxWidth: 35, maxHeight: 35)
                        .background {
                            RoundedRectangle(cornerRadius: 5).fill(.ultraThinMaterial)
                        }
                }
                .offset(x: showPlayerControls ? 0 : (35 + safeArea.trailing))
                .animation(.easeInOut, value: showPlayerControls)
            }
            HStack {
                Button {
                    withAnimation(.linear) {
                        isLock.toggle()
                    }
                } label: {
                    Image(systemName: isLock ? "lock" : "lock.open")
                        .foregroundStyle(isLock ? Color.theme.gradient : Color.white.gradient)
                        .font(.system(size: 20, weight: .thin, design: .default))
                        .frame(maxWidth: 35, maxHeight: 35)
                        .background {
                            RoundedRectangle(cornerRadius: 5).fill(.ultraThinMaterial)
                        }
                }
                .offset(x: showPlayerControls ? 0 : -(35 + safeArea.trailing))
                .animation(.easeInOut, value: showPlayerControls)
                Spacer(minLength: 50)
                Button {
                    withAnimation(.linear) {
                        self.isShowEqualizer.toggle()
                    }
                } label: {
                    Image(systemName: "slider.vertical.3")
                        .foregroundStyle(.white.gradient)
                        .font(.system(size: 20, weight: .thin, design: .default))
                        .frame(maxWidth: 35, maxHeight: 35)
                        .background {
                            RoundedRectangle(cornerRadius: 5).fill(.ultraThinMaterial)
                        }
                }
                .offset(x: showPlayerControls ? 0 : (35 + safeArea.trailing))
                .animation(.easeInOut, value: showPlayerControls)
            }
        }
        .padding(.horizontal, 15)
        .opacity(showPlayerControls ? 1 : 0)
    }
}

#Preview {
    VideoPlayerView(showVideoPlayer: .constant(false))
}
