//
//  DobuleTapSeekView.swift
//  iPlay
//
//  Created by Shiv on 07/03/26.
//

import SwiftUI

struct DobuleTapSeekView: View {
    @StateObject private var player: MediaPlayerManager = .shared
    @Binding var showPlayerControls: Bool
    
    var body: some View {
        HStack(spacing: 75) {
            DoubleTapSeek {
                if showPlayerControls {
                    showPlayerControls = false
                }
                player.jumpBackward(sec: 10)
            }
            DoubleTapSeek(isForward: true) {
                if showPlayerControls {
                    showPlayerControls = false
                }
                player.jumpForward(sec: 10)
            }
        }
    }
}

struct DoubleTapSeek: View {
    var isForward: Bool = false
    var onTap: () -> ()
    @State private var isTapped: Bool = false
    @State private var showArrows: [Bool] = [false, false, false]
    var color: [Color] = [.white.opacity(0), .white.opacity(0.025), .white.opacity(0.05), .white.opacity(0.1), .white.opacity(0.15)]
    var body: some View {
        Rectangle()
            .fill(.clear)
            .overlay {
                Circle()
                    .fill(LinearGradient(colors: isForward ? color.reversed() : color, startPoint: .leading, endPoint: .trailing))
                    .scaleEffect(2, anchor: isForward ? .leading : .trailing)
            }
            .opacity(isTapped ? 1 : 0)
            .overlay {
                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        ForEach((0...2).reversed(), id: \.self) { index in
                            Image(systemName: "arrowtriangle.backward.fill")
                                .foregroundStyle(.theme.gradient)
                                .font(.system(size: 20, weight: .thin, design: .default))
                                .opacity(showArrows[index] ? 1 : 0.2)
                        }
                    }
                    .rotationEffect(.init(degrees: isForward ? 180 : 0))
                    Text("10 Sec")
                        .font(.system(size: 15, weight: .regular, design: .default))
                }
                .foregroundStyle(.white.gradient)
                .opacity(isTapped ? 1 : 0)
            }
            .contentShape(Rectangle())
            .onTapGesture(count: 2) {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isTapped = true
                    showArrows[0] = true
                }
                withAnimation(.easeInOut(duration: 0.2).delay(0.2)) {
                    showArrows[0] = false
                    showArrows[1] = true
                }
                withAnimation(.easeInOut(duration: 0.2).delay(0.35)) {
                    showArrows[1] = false
                    showArrows[2] = true
                }
                withAnimation(.easeInOut(duration: 0.2).delay(0.5)) {
                    showArrows[2] = false
                    isTapped = false
                }
                onTap()
            }
    }
}

#Preview {
    DobuleTapSeekView(showPlayerControls: .constant(false))
}
