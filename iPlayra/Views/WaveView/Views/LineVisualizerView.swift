//
//  LineVisualizerView.swift
//  iPlay
//
//  Created by Shiv on 06/11/25.
//

import SwiftUI

struct LineVisualizerView: View {
 
    @State private var drawingHeight = true
 
    var animation: Animation {
        return .linear(duration: 0.5).repeatForever()
    }
 
    var body: some View {
        VStack(alignment: .leading) {
            HStack(spacing: 2.5) {
                bar(low: 0.4)
                    .animation(animation.speed(1.5), value: drawingHeight)
                bar(low: 0.3)
                    .animation(animation.speed(1.2), value: drawingHeight)
                bar(low: 0.5)
                    .animation(animation.speed(1.0), value: drawingHeight)
                bar(low: 0.3)
                    .animation(animation.speed(1.7), value: drawingHeight)
//                bar(low: 0.5)
//                    .animation(animation.speed(1.0), value: drawingHeight)
            }
            .frame(width: 25)
            .onAppear{
                drawingHeight.toggle()
            }
        }
    }
 
    func bar(low: CGFloat = 0.0, high: CGFloat = 1.0) -> some View {
        RoundedRectangle(cornerRadius: .infinity)
            .fill(.theme.gradient)
            .frame(height: (drawingHeight ? high : low) * 25)
            .frame(height: 25, alignment: .bottom)
    }
}

// MARK: - 3D Morphing Dot Sphere Wave Animation

// 1. Dot Data Model
struct Dot: Identifiable {
    let id = UUID()
    var randomX: Double = Double.random(in: 0...1)
    var randomY: Double = Double.random(in: 0...1)
    var randomZ: Double = Double.random(in: 0...1)
}

struct MorphingSphereView: View {
    // 2. State Variables
    let size: CGSize
    @State private var dots: [Dot] = (0..<500).map { _ in Dot() }
    @State private var morphAmount: Double = 100.0
    
    let colors: [Color] = [.purple, .blue, .cyan, .green, .yellow, .orange, .red]
    let fadeDuration: Double = 2.0
    let waitDuration: Double = 0.5

    var body: some View {
        ZStack {
            TimelineView(.animation) { timeline in
                let time = timeline.date.timeIntervalSinceReferenceDate
                
                // Morphing Logic (0 to 100 and back)
                let totalCycle = fadeDuration + waitDuration
                // Color Logic
                let baseColorIndex = Int(floor(time / totalCycle)) % colors.count
                let currentColor = colors[baseColorIndex]
                
                let count = dots.count
                
                Canvas { context, size in
                    let center = CGPoint(x: size.width / 2, y: size.height / 2)
                    
                    // Har dot ke liye position calculate karna
                    for i in 0..<count {
                        let tMorph = morphAmount / 100.0
                        
                        // Fibonacci Sphere Math
                        let goldenAngle = Double.pi * (3 - sqrt(5))
                        let y = 1 - (Double(i) / Double(count - 1)) * 2
                        let radiusAtY = sqrt(1 - y * y)
                        let theta = goldenAngle * Double(i) + (time * 0.2) // Rotation add ki gayi hai
                        
                        let sphereX = radiusAtY * cos(theta)
                        let sphereZ = radiusAtY * sin(theta)
                        
                        // Interpolation (Chaos se Sphere tak)
                        let x = interpolate(from: dots[i].randomX, to: sphereX, t: tMorph)
                        let yPos = interpolate(from: dots[i].randomY, to: y, t: tMorph)
                        let z = interpolate(from: dots[i].randomZ, to: sphereZ, t: tMorph)
                        
                        let chaosScale: Double = interpolate(from: self.size.width, to: self.size.width / 2, t: tMorph)
                        
                        let finalX = center.x + CGFloat(x * chaosScale)
                        let finalY = center.y + CGFloat(yPos * chaosScale)
                        
                        // 3D Depth effect ke liye size change karna
                        let dotSize = CGFloat(interpolate(from: 1.0, to: 3.5, t: (z + 1) / 2))
                        let opacity = interpolate(from: 0.3, to: 1.0, t: (z + 1) / 2)
                        
                        let rect = CGRect(x: finalX, y: finalY, width: dotSize, height: dotSize)
                        context.opacity = opacity
                        context.fill(Path(ellipseIn: rect), with: .color(currentColor))
                    }
                }
            }
        }
        .ignoresSafeArea()
        .onChange(of: MediaPlayerManager.shared.power, { oldValue, newValue in
            print(newValue)
//            withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                morphAmount = (newValue * 200)
//            }
        })
//        .onAppear {
//            withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
//                morphAmount = 100.0
//            }
//        }
    }
    
    // Helper function for smooth transition
    func interpolate(from: Double, to: Double, t: Double) -> Double {
        return from + (to - from) * t
    }
}

#Preview {
    MorphingSphereView(size: .zero)
}
