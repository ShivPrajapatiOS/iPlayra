//
//  SubTitleView.swift
//  iPlay
//
//  Created by Shiv on 12/10/25.
//

import SwiftUI
import TipKit

struct SubTitleView: View {
    @StateObject private var mediaPlayer: MediaPlayerManager = .shared
    @State private var currentOrientation: UIDeviceOrientation = UIDevice.current.orientation
    @Binding var isPresented: Bool
    
    @State private var subtitles: [SubtitleTrack] = []
    @State private var currentIndex: Int32 = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: isPortrait(geometry: geometry) ? .bottom : .leading) {
                Color.black.opacity(0.0001).ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.bouncy) {
                            isPresented.toggle()
                        }
                    }
                ZStack {
                    VStack {
                        ScrollView(.vertical, showsIndicators: false) {
                            LazyVStack {
                                ForEach(subtitles, id: \.id) { subTitle in
                                    Rectangle()
                                        .fill(.black.opacity(0.0001))
                                        .frame(height: 35)
                                        .overlay(alignment: .leading) {
                                            HStack {
                                                Image(systemName: mediaPlayer.currentSubtitleIndex == subTitle.index ? "largecircle.fill.circle" : "circle")
                                                    .foregroundStyle(.theme)
                                                    .font(.system(size: 15, weight: .thin, design: .default))
                                                Text(subTitle.name)
                                                    .font(.system(size: 15, weight: .thin, design: .default))
                                            }
                                        }
                                        .onTapGesture {
                                            mediaPlayer.setSubtitleTrack(subTitle.index)
                                        }
                                }
                                Rectangle()
                                    .fill(.clear)
                                    .frame(height: 50)
                                    .overlay(alignment: .leading) {
                                        HStack {
                                            Text("AI subtitle translation")
                                        }
                                        .foregroundStyle(.gray)
                                    }
                                    .popoverTip(AISubTitleTranslationTip())
                            }
                            .padding(.horizontal)
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
                            Text("Sub Titles")
                                .font(.system(size: 18, weight: .semibold, design: .default))
                                .foregroundStyle(.white)
                            Spacer(minLength: 0)
                        }
                        .padding(10)
                    }
                }
                .frame(width: isPortrait(geometry: geometry) ? geometry.size.width : geometry.size.width / 2, height: isPortrait(geometry: geometry) ? geometry.size.height / 2 : geometry.size.height)
                .background(BlurView(style: .dark).cornerRadius(20).ignoresSafeArea())
                .animation(.linear, value: currentOrientation)
            }
            .frame(maxWidth: geometry.size.width, maxHeight: geometry.size.height, alignment: .bottom)
            .task {
                let subtitles = await mediaPlayer.getSubtitleTracks()
                self.subtitles = subtitles
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            self.currentOrientation = UIDevice.current.orientation
        }
    }
    
    func isPortrait(geometry: GeometryProxy) -> Bool {
        return geometry.size.height > geometry.size.width
    }
}


#Preview {
    SubTitleView(isPresented: .constant(false))
}
