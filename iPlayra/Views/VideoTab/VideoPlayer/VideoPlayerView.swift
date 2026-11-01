//
//  VideoPlayerView.swift
//  iPlay
//
//  Created by Shiv on 01/09/25.
//

import Foundation
import SwiftUI
import Combine
import TipKit
import VLCMediaLibraryKit
import VLCKit
import AVKit
import MarqueeLabel

struct VideoPlayerView: View {
    @Binding var showVideoPlayer: Bool
    @State private var isShowEqualizer: Bool = false
    @State private var isShowPlaylist: Bool = false
    @State private var isShowMoreSettings: Bool = false
    @State private var isShowAudioTrack: Bool = false
    @State private var isShowHDR: Bool = false
    @State private var isShowSubtitle: Bool = false
    @State private var isMirrored: Bool = false


    @State private var isLock: Bool = false
    @State private var aspectRatio: AspectRatio = .original
        
    @State private var showPlayerControls: Bool = true
    @State private var timeoutTask: DispatchWorkItem?
    
    @State private var currentBrightness: CGFloat = UIScreen.main.brightness
    @State private var currentVolume: CGFloat = UIScreen.main.brightness
    
    @State private var showOverlay: Bool = false
    @State private var overlayText: String = ""
    @State private var isVolume: Bool = true
    
    // Drag starting values
    @State private var startBrightness: CGFloat = 0.5
    @State private var startVolume: CGFloat = 0.5
    let sensitivity: CGFloat = 500.0   // 500 px drag = full range change
    
    
    // Zoom properies
    @State private var currentScale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var isInteracting: Bool = false
    
    @State private var isZoomPreview: Bool = false
    
    // Limits
    let minZoom: CGFloat = 0.5  // 50%
    let maxZoom: CGFloat = 6.0  // 600%
    
    // Preview Constants
    let previewWidth: CGFloat = 150
    let previewHeight: CGFloat = 85
    
    
    @State private var thumbOffset: CGFloat = 0.0
    @State private var showPreview: Bool = false
        
    var backAction: (() -> Void)?
    
    
    var body: some View {
        GeometryReader { geo in
            Color.clear.ignoresSafeArea()
            ZStack(alignment: .bottomTrailing) {
                Color.clear.ignoresSafeArea()
                ZStack {
                    Color.black.ignoresSafeArea()
                    VideoLayerView()
                        .scaleEffect(currentScale)
                        .clipShape(RoundedRectangle(cornerRadius: 0))
                        .ignoresSafeArea()
                        .scaleEffect(x: isMirrored ? -1 : 1, y: 1)
                        .overlay {
                                DobuleTapSeekView(showPlayerControls: $showPlayerControls)
                        }
                        .overlay(alignment: .top) {
                                TopControlsView(safeArea: geo.safeAreaInsets, showPlayerControls: $showPlayerControls, showVideoPlayer: $showVideoPlayer, isShowHDR: $isShowHDR, isShowSubtitle: $isShowSubtitle, isShowAudioTrack: $isShowAudioTrack, isShowMoreSettings: $isShowMoreSettings, backAction: backAction)
                        }
                        .overlay {
                                MiddleControlsView(safeArea: geo.safeAreaInsets, showPlayerControls: $showPlayerControls, isLock: $isLock, isShowEqualizer: $isShowEqualizer)
                        }
                        .overlay(alignment: .bottom) {
                                VStack {
                                    VideoSeekPriview(thumbOffset: $thumbOffset, showPreview: $showPreview)
                                    .frame(height: 70)
                                    BottomControlsView(safeArea: geo.safeAreaInsets, showPlayerControls: $showPlayerControls, isShowPlaylist: $isShowPlaylist, aspectRatio: $aspectRatio, thumbOffset: $thumbOffset, showPreview: $showPreview) {
                                        timeoutControls()
                                    }
                                }
                        }
                    
                    
                    if showOverlay {
                        ZStack {
                            VStack(spacing: 10) {
                                Image(systemName: isVolume ? "speaker.wave.2" : "sun.max.fill")
                                    .font(.system(size: 16, weight: .thin, design: .default))
                                Text(overlayText)
                                    .font(.system(size: 16, weight: .thin, design: .default))
                            }
                            .frame(width: 100, height: 100)
                            .foregroundStyle(.white.gradient)
                            .background(.ultraThinMaterial)
                            .cornerRadius(15)
                        }
                        .onAppear {
                            currentBrightness = UIScreen.main.brightness
                            startBrightness = UIScreen.main.brightness
                        }
                    }
                                    
                        if isZoomPreview {
                            VStack {
                                HStack {
                                    Spacer()
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(.ultraThinMaterial)
                                            .frame(width: previewWidth, height: previewHeight)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 4)
                                                    .stroke(Color.white, lineWidth: 1)
                                            )
                                        let indicatorWidth = previewWidth / currentScale
                                        let indicatorHeight = previewHeight / currentScale
                                        
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(.theme.opacity(0.25))
                                            .overlay(content: {
                                                RoundedRectangle(cornerRadius: 4)
                                                    .stroke(.theme, lineWidth: 1)
                                            })
                                            .frame(
                                                width: min(indicatorWidth, previewWidth),
                                                height: min(indicatorHeight, previewHeight)
                                            )
                                    }
                                    .padding(.top, 50)
                                    .padding(.trailing, 20)
                                    .transition(.move(edge: .trailing).combined(with: .opacity))
                                }
                                Spacer()
                            }
                        } else {
                            if currentScale != 1 {
                                VStack {
                                    HStack {
                                        Button(action: {
                                            currentScale = 1
                                        }, label: {
                                            Text("Reset Zoom")
                                                .foregroundStyle(.white)
                                                .font(.system(size: 12, weight: .semibold, design: .default))
                                                .padding(.vertical, 8)
                                                .padding(.horizontal, 12)
                                                .background {
                                                    Capsule().fill(.theme.gradient.opacity(0.25))
                                                        .overlay {
                                                            Capsule()
                                                                .stroke(.theme.gradient, lineWidth: 1)
                                                        }
                                                }
    //                                            .
                                        })
                                        .padding(.top, 50)
                                        .padding(.leading, 20)
                                        Spacer()
                                    }
                                    Spacer()
                                }
                            }
                        }
                    
                    if isShowSubtitle {
                        SubTitleView(isPresented: $isShowSubtitle)
                            .transition(.move(edge: .bottom).combined(with: .move(edge: .bottom)))
                    }
                    
                    if isShowHDR {
                        HDREffectView(isPresented: $isShowHDR)
                            .transition(.move(edge: .bottom))
                            .transition(.move(edge: .bottom).combined(with: .move(edge: .bottom)))
                    }
                    
                    if isShowEqualizer {
                        EqualizerView(isPresented: $isShowEqualizer)
                            .transition(.move(edge: .bottom).combined(with: .move(edge: .bottom)))
                    }
                    
                    if isShowPlaylist {
                        PlaybackVideoQueueView(isPresented: $isShowPlaylist)
                            .transition(.move(edge: .bottom).combined(with: .move(edge: .bottom)))
                    }
                    
                    if isShowAudioTrack {
                        AudioTrackView(isPresented: $isShowAudioTrack)
                        .transition(.move(edge: .bottom).combined(with: .move(edge: .bottom)))
                    }
                    
                    if isShowMoreSettings {
                        MoreOptionsSettingView(isPresented: $isShowMoreSettings)
                        .transition(.move(edge: .bottom).combined(with: .move(edge: .bottom)))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: true)
                .background(content: {
                    Color.background.ignoresSafeArea()
                })
                .onTapGesture(count: 1) {
                    tapGestureCallback()
                }
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let isLeftSide = value.startLocation.x < geo.size.width / 2
                            let offset = -(value.translation.height / sensitivity) // smooth offset
                            
                            if isLeftSide {
                                currentBrightness = (startBrightness + offset).clamped(to: 0...1)
                                UIScreen.main.brightness = currentBrightness
                                overlayText = "\(Int(currentBrightness * 100))%"
                                isVolume = false
                            } else {
                                currentVolume = (startVolume + offset).clamped(to: 0...1)
                                overlayText = "\(Int(currentVolume * 100))%"
                                isVolume = true
                            }
                            
                            showOverlay = true
                        }
                        .onEnded { _ in
                            // Save last values for next drag
                            startBrightness = currentBrightness
                            startVolume = currentVolume
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                showOverlay = false
                            }
                        }
                )
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            if !isZoomPreview {
                                isZoomPreview = true
                            }
                            isInteracting = true
                            // Naya scale calculate karke limit ke andar clamp karein
                            let newScale = lastScale * value
                            currentScale = min(max(newScale, minZoom), maxZoom)
                        }
                        .onEnded { _ in
                            lastScale = currentScale
                            withAnimation(.spring()) {
                                isInteracting = false
                            }
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                isZoomPreview = false
                            }
                            withAnimation(.easeInOut(duration: 0.25).delay(1)) {
                                isZoomPreview = false
                            }
                        }
                )
            }
        }
        .statusBarHidden()
        .onAppear(perform: {
            AppDelegate.orientationLock = .all
            UIViewController.attemptRotationToDeviceOrientation()
            self.timeoutControls()
        })
    }
    
    private func tapGestureCallback() {
        withAnimation(.linear(duration: 0.35)) {
            showPlayerControls.toggle()
        }
        if MediaPlayerManager.shared.state == .playing {
            timeoutControls()
        }
    }
    
    private func timeoutControls() {
        if let timeoutTask {
            timeoutTask.cancel()
        }
        timeoutTask = .init(block: {
            withAnimation(.easeInOut(duration: 0.35)) {
                showPlayerControls = false
            }
        })
        
        if let timeoutTask {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: timeoutTask)
        }
    }
}


#Preview {
    VideoPlayerView(showVideoPlayer: .constant(false))
}
