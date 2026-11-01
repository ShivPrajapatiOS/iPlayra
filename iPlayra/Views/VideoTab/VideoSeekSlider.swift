//
//  VideoSeekSlider.swift
//  iPlay
//
//  Created by Shiv on 06/03/26.
//

import SwiftUI

struct VideoSeekSlider: View {
    @Binding var progress: Float
    
    var minValue: CGFloat = 0
    var maxValue: CGFloat = 1
    
    let barHeight: CGFloat = 2
    let knobSize: CGFloat = 20
    
    let hitAreaSize: CGFloat = 40
    
    var onSeeking: ((Float, Bool, CGFloat) -> Void)? = nil
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
                    
                    // 3. Invisible Hit Area
                    Circle()
                        .fill(isSeeking ? .theme.opacity(0.25) : .clear)
                        .animation(.bouncy(duration: 0.25), value: isSeeking)
                        .frame(width: hitAreaSize, height: hitAreaSize)
                        .contentShape(Circle())
                        .position(x: knobX, y: geometry.size.height / 2)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    isSeeking = true
                                    let clampedX = max(knobSize / 2, min(value.location.x, trackWidth - knobSize / 2))
                                    let newNormalized = (clampedX - knobSize / 2) / knobMovementRange
                                    
                                    progress = Float(minValue + (newNormalized * (maxValue - minValue)))
                                    
                                    onSeeking?(progress, true, clampedX)
                                }
                                .onEnded { value in
                                    isSeeking = false
                                    let clampedX = max(knobSize / 2, min(value.location.x, trackWidth - knobSize / 2))
                                    onSeeking?(progress, false, clampedX)
                                }
                        )
                    
                    // 4. Actual Knob
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

struct VideoSeekSliderWithLivePriview: View {
    
    @State private var videoProgress: Float = 0.0
    @State private var thumbOffset: CGFloat = 0.0
    @State private var showPreview: Bool = false
    
    let previewWidth: CGFloat = 120

    var body: some View {
        VStack {
            GeometryReader { outerGeometry in
                let totalWidth = outerGeometry.size.width
                
                ZStack(alignment: .topLeading) {
                    if showPreview {
                        VStack(spacing: 5) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.red)
                                .frame(width: previewWidth, height: 70)
                                .overlay(Text("Preview").foregroundColor(.white))
                            
                            Image(systemName: "arrowtriangle.down.fill")
                                .font(.caption)
                                .offset(x: thumbOffset - clampedOffset(in: totalWidth))
                        }
                        .frame(width: previewWidth)
                        .offset(x: clampedOffset(in: totalWidth) - (previewWidth / 2))
                        .transition(.opacity)
                    }
                }
            }
            .padding(.horizontal, 20)
            .frame(height: 150)
            VideoSeekSlider(progress: $videoProgress) { (newProgress, dragging, offset) in
                self.thumbOffset = offset
                withAnimation(.easeInOut(duration: 0.1)) {
                    self.showPreview = dragging
                }
            }
            .frame(height: 30)
        }
    }

    private func clampedOffset(in totalWidth: CGFloat) -> CGFloat {
        let halfPreview = previewWidth / 2
        return max(halfPreview, min(thumbOffset, totalWidth - halfPreview))
    }
}

#Preview {
    VideoSeekSlider(progress: .constant(0.5))
}
