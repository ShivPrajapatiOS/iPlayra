//
//  PlaybackVideoQueueView.swift
//  iPlay
//
//  Created by Shiv on 12/10/25.
//

import SwiftUI
import UniformTypeIdentifiers
import VLCMediaLibraryKit

struct PlaybackVideoQueueView: View {
    @State private var playbackVideos: [VLCMLMedia] = []
    @State private var currentOrientation: UIDeviceOrientation = UIDevice.current.orientation
    @Binding var isPresented: Bool
    
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
                            LazyVStack(spacing: 0) {
                                ForEach(Array(playbackVideos.enumerated()), id: \.offset) { (index, media) in
                                    VideoItemView(isPlayback: true, video: media, removeAction: { removeMedia in
                                        MediaPlayerManager.shared.removeFromPlaylist(index: index)
                                    })
                                    .frame(height: 75)
                                    .padding(5)
                                    .background(RoundedRectangle(cornerRadius: 10).fill(.ultraThinMaterial.opacity(0.001)))
                                    .onDrag({
                                        return NSItemProvider(object: "\(index)" as NSItemProviderWriting)
                                    })
                                    .onDrop(of: [.text], delegate: VideoDropDelegate(
                                        destinationIndex: index,
                                        playbackVideos: $playbackVideos
                                    ))
                                    .padding(.horizontal)
                                    .onTapGesture {
                                        MediaPlayerManager.shared.playFromPlaylist(index: index)
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .safeAreaInset(edge: .top) {
                        HStack(spacing: 10) {
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
                            Text("Playback Queue")
                                .font(.system(size: 18, weight: .semibold, design: .default))
                                .foregroundStyle(.white)
                            Spacer()
                        }
                        .padding(10)
                    }
                }
                .frame(width: isPortrait(geometry: geometry) ? geometry.size.width : geometry.size.width / 2, height: isPortrait(geometry: geometry) ? geometry.size.height / 2 : geometry.size.height)
                .background(BlurView(style: .dark).cornerRadius(20).ignoresSafeArea())
                .animation(.linear, value: currentOrientation)
            }
            .frame(maxWidth: geometry.size.width, maxHeight: geometry.size.height, alignment: .bottom)
            .onAppear(perform: {
                playbackVideos = MediaPlayerManager.shared.originalMedias
            })
        }
    }
    
    func isPortrait(geometry: GeometryProxy) -> Bool {
        return geometry.size.height > geometry.size.width
    }
}

#Preview {
    PlaybackVideoQueueView(isPresented: .constant(false))
}


struct VideoDropDelegate: DropDelegate {
    let destinationIndex: Int
    @Binding var playbackVideos: [VLCMLMedia]
    
    func performDrop(info: DropInfo) -> Bool {
        // Drag kiye gaye item ka index nikalna
        guard let itemProvider = info.itemProviders(for: [.text]).first else { return false }
        
        itemProvider.loadObject(ofClass: NSString.self) { (string, error) in
            if let sourceString = string as? String, let sourceIndex = Int(sourceString) {
                
                // Sirf tab move karein jab index alag ho
                if sourceIndex != destinationIndex {
                    DispatchQueue.main.async {
                        moveMedia(from: sourceIndex, to: destinationIndex)
                    }
                }
            }
        }
        return true
    }
    
    // Core Logic: VLC aur UI dono update karna
    private func moveMedia(from source: Int, to destination: Int) {
        let mediaToMove = playbackVideos[source]
        
        // 1. MediaPlayerManager logic
        // Pehle purana delete karein
        MediaPlayerManager.shared.removeFromPlaylist(index: source)
        // Phir naye index par insert karein
        MediaPlayerManager.shared.originalMedias.insert(mediaToMove, at: Int(UInt32(destination)))
        
        // 2. Local State update (UI refresh ke liye)
        withAnimation(.spring()) {
            playbackVideos.remove(at: source)
            playbackVideos.insert(mediaToMove, at: destination)
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
}
