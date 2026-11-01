//
//  VerticalSliderView.swift
//  iPlay
//
//  Created by Shiv on 17/09/25.
//

import SwiftUI
import VLCKit

// MARK: - Vertical Slider View
struct VerticalSlider: View {
    @Binding var progress: Float
    
    var minValue: CGFloat = 0
    var maxValue: CGFloat = 1

    let barWidth: CGFloat = 10
    let knobSize: CGFloat = 20

    var onSeeking: ((Float, Bool) -> Void)? = nil
    @State private var isSeeking: Bool = false

    var body: some View {
        ZStack {
            Color.clear.ignoresSafeArea()
            GeometryReader { geometry in
                let trackHeight = geometry.size.height
                let knobMovementRange = trackHeight - knobSize
                
                let normalizedProgress = (CGFloat(progress) - minValue) / (maxValue - minValue)
                
                let knobY = (trackHeight - knobSize / 2) - (knobMovementRange * normalizedProgress)
                
                let filledTrackHeight = trackHeight - knobY
                
                ZStack {
                    RoundedRectangle(cornerRadius: .infinity)
                        .fill(.ultraThinMaterial)
                        .frame(width: isSeeking ? knobSize :  barWidth, height: trackHeight)
                        .position(x: geometry.size.width / 2, y: trackHeight / 2)
                        .animation(.easeInOut, value: isSeeking)

                    RoundedRectangle(cornerRadius: .infinity)
                        .fill(.theme.gradient)
                        .frame(width: isSeeking ? ((knobSize + barWidth) / 2) :  barWidth, height: filledTrackHeight)
                        .position(
                            x: geometry.size.width / 2,
                            y: trackHeight - filledTrackHeight / 2
                        )
                        .animation(.easeInOut, value: isSeeking)
                    Circle()
                        .fill(.white)
                        .frame(width: knobSize, height: knobSize)
                        .position(x: geometry.size.width / 2, y: knobY)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    isSeeking = true
                                    let clampedY = max(knobSize / 2, min(value.location.y, trackHeight - knobSize / 2))
                                    let newNormalized = 1 - ((clampedY - knobSize / 2) / knobMovementRange)
                                    progress = Float(minValue + (newNormalized * (maxValue - minValue)))
                                    onSeeking?(progress, true)
                                }
                                .onEnded { _ in
                                    isSeeking = false
                                    onSeeking?(progress, false)
                                }
                        )
                }
            }
            .frame(width: knobSize)
        }
    }
}

#Preview {
    VerticalSlider(progress: .constant(0.5))
}

// MARK: - Horizontal Slider View
struct HorizontalSlider: View {
    @Binding var progress: Float
    
    var minValue: CGFloat = 0
    var maxValue: CGFloat = 1

    let barHeight: CGFloat = 2
    let knobSize: CGFloat = 20
    
    // नया constant: Tap/Drag करने के लिए बड़ा size
    let hitAreaSize: CGFloat = 40

    var onSeeking: ((Float, Bool) -> Void)? = nil
    @State private var isSeeking: Bool = false

    var body: some View {
        ZStack {
            Color.clear
            GeometryReader { geometry in
                let trackWidth = geometry.size.width
                let knobMovementRange = trackWidth - knobSize
                 
                let normalizedProgress = (CGFloat(progress) - minValue) / (maxValue - minValue)
                 
                let knobX = (knobSize / 2) + (knobMovementRange * normalizedProgress)
                 
                let filledTrackWidth = knobX
                 
                ZStack {
                    // 1. Track Bar (Background)
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.gray.opacity(0.5))
                        .frame(width: trackWidth, height: isSeeking ? 7 : barHeight)
                        .animation(.easeInOut(duration: 0.5), value: isSeeking)
                        .position(x: trackWidth / 2, y: geometry.size.height / 2)

                    // 2. Track Bar (Filled)
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.theme)
                        .frame(width: filledTrackWidth, height: isSeeking ? 5 : barHeight)
                        .animation(.easeInOut(duration: 0.5), value: isSeeking)
                        .position(
                            x: filledTrackWidth / 2,
                            y: geometry.size.height / 2
                        )
                     
                    // 3. Invisible Hit Area (Gestures के लिए)
                    Circle()
                        .fill(isSeeking ? .theme.opacity(0.25) : .clear) // इसे पारदर्शी रखें
                        .animation(.bouncy(duration: 0.25), value: isSeeking)
                        .frame(width: hitAreaSize, height: hitAreaSize) // बड़ा size
                        .contentShape(Circle()) // Tap area को shape के अनुसार सेट करें
                        .position(x: knobX, y: geometry.size.height / 2)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    // Drag location को clamped करें
                                    isSeeking = true
                                    let clampedX = max(knobSize / 2, min(value.location.x, trackWidth - knobSize / 2))
                                    let newNormalized = (clampedX - knobSize / 2) / knobMovementRange
                                    
                                    // progress को अपडेट करें
                                    progress = Float(minValue + (newNormalized * (maxValue - minValue)))
                                    onSeeking?(progress, true)
                                }
                                .onEnded { _ in
                                    isSeeking = false
                                    onSeeking?(progress, false)
                                }
                        )

                    // 4. Actual Knob (Visuals के लिए)
                    Circle()
                        .fill(Color.white)
                        .frame(width: knobSize, height: knobSize)
                        // .position() अब ज़रूरी नहीं, क्योंकि इसे Overlay/ZStack में रखें
                        .position(x: knobX, y: geometry.size.height / 2)
                }
            }
            // 전체 फ्रेम की ऊंचाई knobSize के बजाय hitAreaSize पर सेट करें
            .frame(height: hitAreaSize)
        }
    }
}

struct HorizontalBookmarkSlider: View {
    @StateObject private var player: MediaPlayerManager = .shared
    @Binding var progress: Float
    
    var minValue: CGFloat = 0
    var maxValue: CGFloat = 1
    
    var bookmarks: [Int64] = []

    let barHeight: CGFloat = 2
    let knobSize: CGFloat = 20
    
    // नया constant: Tap/Drag करने के लिए बड़ा size
    let hitAreaSize: CGFloat = 40

    var onSeeking: ((Float, Bool) -> Void)? = nil
    var boomarkAction: ((Float) -> Void)? = nil
    @State private var isSeeking: Bool = false
    
    var body: some View {
        ZStack {
            Color.clear
            GeometryReader { geometry in
                let trackWidth = geometry.size.width
                let knobMovementRange = trackWidth - knobSize
                 
                let normalizedProgress = (CGFloat(progress) - minValue) / (maxValue - minValue)
                 
                let knobX = (knobSize / 2) + (knobMovementRange * normalizedProgress)
                 
                let filledTrackWidth = knobX
                 
                ZStack {
                    // 1. Track Bar (Background)
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.gray.opacity(0.5))
                        .frame(width: trackWidth, height: isSeeking ? 7 : barHeight)
                        .animation(.easeInOut(duration: 0.5), value: isSeeking)
                        .position(x: trackWidth / 2, y: geometry.size.height / 2)

                    // 2. Track Bar (Filled)
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.theme)
                        .frame(width: filledTrackWidth, height: isSeeking ? 5 : barHeight)
                        .animation(.easeInOut(duration: 0.5), value: isSeeking)
                        .position(
                            x: filledTrackWidth / 2,
                            y: geometry.size.height / 2
                        )
                    
                    ForEach(bookmarks, id: \.self) { time in
                        let bProgress = CGFloat(time) / CGFloat(Int64(player.totalDuration.intValue))
                        let bX = (knobSize / 2) + (knobMovementRange * bProgress)
                        Image(systemName: "bookmark.fill")
                            .font(.system(size: 15, weight: .thin, design: .default))
                            .foregroundStyle(.yellow.gradient)
                            .frame(width: hitAreaSize, height: hitAreaSize)
                            .contentShape(Circle())
                            .onTapGesture {
                                boomarkAction?(Float(bProgress))
                            }
                            .position(x: bX, y: (geometry.size.height / 2) - 7.5)
                    }
                     
                    Circle()
                        .fill(isSeeking ? .theme.opacity(0.25) : .clear)
                        .animation(.bouncy(duration: 0.25), value: isSeeking)
                        .frame(width: hitAreaSize, height: hitAreaSize)
                        .contentShape(Circle())
                        .position(x: knobX, y: geometry.size.height / 2)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    // Drag location को clamped करें
                                    isSeeking = true
                                    let clampedX = max(knobSize / 2, min(value.location.x, trackWidth - knobSize / 2))
                                    let newNormalized = (clampedX - knobSize / 2) / knobMovementRange
                                    
                                    // progress को अपडेट करें
                                    progress = Float(minValue + (newNormalized * (maxValue - minValue)))
                                    onSeeking?(progress, true)
                                }
                                .onEnded { _ in
                                    isSeeking = false
                                    onSeeking?(progress, false)
                                }
                        )

                    Circle()
                        .fill(Color.white)
                        .frame(width: knobSize, height: knobSize)
                        .position(x: knobX, y: geometry.size.height / 2)
                }
            }
            .frame(height: hitAreaSize)
        }
    }
}

struct WebPageView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var isShowBottmSheet: Bool
    @Binding var isShowPrivacyPolicy: Bool
    var pageName: String
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack {
                HStack {
                    Button {
                        if isShowBottmSheet {
                            isShowPrivacyPolicy.toggle()
                        } else {
                            dismiss()
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 25, weight: .light, design: .default))
                            .padding(.init(top: 10, leading: 0, bottom: 10, trailing: 10))
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 50, alignment: .leading)
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                WebPageLoadView(pageName: pageName)
                    .background(.black)
            }
        }
    }
}

// MARK: - Circle Progress View
struct CircularProgressView: View {
    @Binding var progress: Float
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(.clear, lineWidth: 15)
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(
                    Color.theme.gradient,
                    style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeOut, value: progress)
        }
    }
}


//import MediaPlayer
//struct ViewVideoPlayer: View {
//    @State private var currentBrightness: CGFloat = UIScreen.main.brightness   // system brightness se start
//    @State private var currentVolume: CGFloat = 0.5                            // system volume start
//    
//    @State private var showOverlay: Bool = false
//    @State private var overlayText: String = ""
//    
//    @State private var startBrightness: CGFloat = UIScreen.main.brightness
//    @State private var startVolume: CGFloat = 0.5
//    
//    let sensitivity: CGFloat = 500.0   // jitna bada utna smooth
//    
//    // Hidden MPVolumeView
//    private let volumeView = MPVolumeView(frame: .zero)
//    
//    var body: some View {
//        GeometryReader { geometry in
//            ZStack {
//                Color.black.ignoresSafeArea()
//                
//                if showOverlay {
//                    Text(overlayText)
//                        .font(.system(size: 20, weight: .bold, design: .default))
//                        .foregroundStyle(.white)
//                        .padding()
//                        .background(Color.black.opacity(0.7))
//                        .clipShape(RoundedRectangle(cornerRadius: 10))
//                }
//            }
//            .gesture(
//                DragGesture()
//                    .onChanged { value in
//                        let isLeftSide = value.startLocation.x < geometry.size.width / 2
//                        let offset = -(value.translation.height / sensitivity)
//                        
//                        if isLeftSide {
//                            // Brightness adjust
//                            currentBrightness = (startBrightness + offset).clamped(to: 0...1)
//                            UIScreen.main.brightness = currentBrightness
//                            overlayText = "Brightness \(Int(currentBrightness * 100))%"
//                        } else {
//                            // Volume adjust
//                            currentVolume = (startVolume + offset).clamped(to: 0...1)
//                            setSystemVolume(currentVolume)
//                            overlayText = "Volume \(Int(currentVolume * 100))%"
//                        }
//                        
//                        showOverlay = true
//                    }
//                    .onEnded { _ in
//                        startBrightness = currentBrightness
//                        startVolume = currentVolume
//                        
//                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//                            showOverlay = false
//                        }
//                    }
//            )
//            .onAppear {
//                // Add hidden volume view (to control system volume)
//                UIApplication.shared.windows.first?.rootViewController?.view.addSubview(volumeView)
//                volumeView.isHidden = true
//                
//                // Get current system volume
//                if let slider = volumeSlider {
//                    currentVolume = CGFloat(slider.value)
//                    startVolume = CGFloat(slider.value)
//                }
//            }
//        }
//    }
//    
//    // Access MPVolumeView's UISlider
//    private var volumeSlider: UISlider? {
//        for subview in volumeView.subviews {
//            if let slider = subview as? UISlider {
//                return slider
//            }
//        }
//        return nil
//    }
//    
//    private func setSystemVolume(_ value: CGFloat) {
//        volumeSlider?.setValue(Float(value), animated: false)
//        volumeSlider?.sendActions(for: .valueChanged)
//    }
//}

// Clamp helper
extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}


struct CustomLinearProgressView: View {
    @Binding var progress: Float
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .frame(height: 2.5)
                    .foregroundStyle(Color.gray.opacity(0.3))
                Capsule()
                    .frame(width: geo.size.width * CGFloat(progress), height: 2.5)
                    .foregroundStyle(.theme)
                    .animation(.easeInOut, value: progress)
            }
        }
        .frame(height: 1)
    }
}
