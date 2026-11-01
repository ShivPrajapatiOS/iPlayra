//
//  AudioMiniPlayerView.swift
//  iPlayra
//
//  Created by Shiv on 27/10/26.
//

import SwiftUI
import VLCKit
import VLCMediaLibraryKit

enum MiniPlayerStyle { case floating, accessory }

struct AudioMiniPlayerView: View {
    @StateObject private var player: MediaPlayerManager = .shared
    @Binding var isShowPlayer: Bool
    @Binding var isShowQueuePlaylist: Bool
    var style: MiniPlayerStyle = .floating
    
    var body: some View {
//        if player.isPlayerType == .audio && player.state != .stopped {
            HStack(spacing: 10) {
                Capsule().fill(.ultraThinMaterial)
                    .frame(width: 45, height: 45)
                    .overlay {
                        WebImageView(iconSize: 20, url: player.currentMLMedia?.thumbnail())
                            .clipShape(Capsule())
                    }
                    .overlay {
                        CircularProgressView(progress: $player.position)
                    }
                VStack(alignment: .leading) {
                    Text(player.currentMLMedia?.title ?? "Unknown")
                        .font(.system(size: 16, weight: .regular, design: .default))
                    Text(player.currentMLMedia?.artist?.name ?? "Unknown")
                        .font(.system(size: 12, weight: .light, design: .default))
                        .foregroundStyle(.gray.gradient)
                }
                .lineLimit(1)
                
                Spacer(minLength: 0)
                HStack(spacing: 20) {
                    Button {
                        player.playPause()
                    } label: {
                        Image(systemName: player.state == .playing ? "pause" : "play.fill")
                            .font(.system(size: 22, weight: .regular, design: .default))
                            .foregroundStyle(.white.gradient)
                            .frame(width: 40, height: 40)
                            .background(Capsule().fill(.ultraThinMaterial))
                    }
                    
                    Button {
                        withAnimation(.bouncy.speed(0.5)) {
                            player.stop()
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .regular, design: .default))
                            .foregroundStyle(.gray.gradient)
                            .frame(width: 40, height: 40)
                            .background(Capsule().fill(.ultraThinMaterial))
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: 55, alignment: .leading)
            .padding(.horizontal, 5)
            .background {
                // accessory ka apna glass background hota hai
                if style == .floating {
                    Capsule().fill(.ultraThinMaterial)
                        .overlay { Capsule().stroke(.gray.opacity(0.25), lineWidth: 1) }
                }
            }
            .contentShape(.rect)
            .onTapGesture { isShowPlayer.toggle() }
            .padding(style == .floating ? EdgeInsets(top: 5, leading: 5, bottom: 0, trailing: 5) : EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8))
//        }
    }
}

#Preview {
    AudioMiniPlayerView(isShowPlayer: .constant(true), isShowQueuePlaylist: .constant(true))
//    ContentView()
}


struct MiniPlayerModifier: ViewModifier {
    @ObservedObject private var player: MediaPlayerManager = .shared
    @Binding var isShowPlayer: Bool

    private var isActive: Bool {
        player.isPlayerType == .audio && player.state != .stopped
    }

    func body(content: Content) -> some View {
        if #available(iOS 26.1, *) {
            // Native bottom accessory: tab bar ke upar, push hone par bhi rehta hai
            content.tabViewBottomAccessory(isEnabled: isActive) {
                AudioMiniPlayerView(isShowPlayer: $isShowPlayer,
                                    isShowQueuePlaylist: .constant(false),
                                    style: .accessory)
            }
        } else {
            // iOS 17 - 26.0: tab bar ke upar overlay
            content.overlay(alignment: .bottom) {
                AudioMiniPlayerView(isShowPlayer: $isShowPlayer,
                                    isShowQueuePlaylist: .constant(false),
                                    style: .floating)
                    .padding(.bottom, 49)   // standard tab bar height
            }
        }
    }
}

extension View {
    func miniPlayer(isShowPlayer: Binding<Bool>) -> some View {
        modifier(MiniPlayerModifier(isShowPlayer: isShowPlayer))
    }
}
