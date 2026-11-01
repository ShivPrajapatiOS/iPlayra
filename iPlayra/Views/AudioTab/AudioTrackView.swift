//
//  AudioTrackView.swift
//  iPlay
//
//  Created by Shiv on 15/09/25.
//

import SwiftUI

struct AudioTrackView: View {
    @Binding var isPresented: Bool
    @StateObject private var mediaPlayer: MediaPlayerManager = .shared
    @State var audioTrack: [AudioTrackModel] = []
    @State var selectedTrackIndex: (trackIndex: Int32, delay: Int) = (0, 0)
    
    @State private var currentOrientation: UIDeviceOrientation = UIDevice.current.orientation
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: isPortrait(geometry: geometry) ? .bottom : .leading) {
                Color.black.opacity(0.0001).ignoresSafeArea()
                    .onTapGesture {
                        isPresented.toggle()
                    }
                ZStack {
                    VStack {
                        ScrollView(.vertical, showsIndicators: false) {
                            LazyVStack(alignment: .leading, spacing: 5) {
                                ForEach(Array((self.audioTrack).enumerated()), id: \.offset) { (index, track) in
                                    Button {
                                        selectedTrackIndex.trackIndex = track.index
                                        mediaPlayer.audioTrackPlay(track: track, delay: selectedTrackIndex.delay)
                                    } label: {
                                        HStack {
                                            Image(systemName: selectedTrackIndex.trackIndex == track.index ? "circle.inset.filled" : "circle")
                                                .foregroundStyle(.theme)
                                            Text(track.track)
                                                .font(.system(size: 15, weight: .regular, design: .default))
                                                .foregroundStyle(.white)
                                        }
                                        .frame(height: 30)
                                        .padding(.horizontal, 20)
                                    }
                                }
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
                            Text("Audio Tracks")
                                .font(.system(size: 18, weight: .semibold, design: .default))
                                .foregroundStyle(.white)
                            Spacer(minLength: 0)
                            HStack(spacing: 10) {
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(.theme.opacity(0.25))
                                    .frame(maxWidth: 25, maxHeight: 25)
                                    .overlay {
                                        Image(systemName: "plus")
                                            .font(.system(size: 18, weight: .medium, design: .default))
                                            .foregroundStyle(.theme)
                                            .cornerRadius(5)
                                    }
                                    .onTapGesture {
                                        if selectedTrackIndex.delay < 50 {
                                            selectedTrackIndex.delay += 1
                                        }
                                    }
                                Text("\(selectedTrackIndex.delay)s")
                                    .frame(maxWidth: 30)
                                    .foregroundStyle(.white)
                                    .font(.system(size: 14, weight: .medium, design: .default))
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(.theme.opacity(0.25))
                                    .frame(maxWidth: 25, maxHeight: 25)
                                    .overlay {
                                        Image(systemName: "minus")
                                            .font(.system(size: 18, weight: .medium, design: .default))
                                            .foregroundStyle(.theme)
                                            .cornerRadius(5)
                                    }
                                    .onTapGesture {
                                        if selectedTrackIndex.delay >= 1 {
                                            selectedTrackIndex.delay -= 1
                                        }
                                    }
                            }
                            .padding(.trailing)
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
                audioTrack = await self.mediaPlayer.getAudioTracks()
                selectedTrackIndex = mediaPlayer.currentAudioTrack
                audioTrack.forEach { track in
                    print(track.index, track.track)
                }
            }
        }
    }
    func isPortrait(geometry: GeometryProxy) -> Bool {
        return geometry.size.height > geometry.size.width
    }
}

#Preview {
    AudioTrackView(isPresented: .constant(false))
}
