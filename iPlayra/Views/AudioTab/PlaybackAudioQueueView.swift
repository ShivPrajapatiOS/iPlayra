//
//  PlaybackAudioQueueView.swift
//  iPlay
//
//  Created by Shiv on 22/02/26.
//

import SwiftUI
import VLCMediaLibraryKit
import VLCKit
import Combine

struct PlaybackAudioQueueView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var mediaLibrary: MediaLibraryService = .shared
    @State private var playbackMedias: [VLCMLMedia] = []
    
    @State private var shareMedia: IdentifiableMedia?
    @State private var infoMedia: IdentifiableMedia?
    
    @State private var currentOrientation: UIDeviceOrientation = UIDevice.current.orientation
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: isPortrait(geometry: geometry) ? .bottom : .leading) {
                Color.black.opacity(0.0001).ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.bouncy) {
                            dismiss()
                        }
                    }
                ZStack {
                    VStack {
                        ScrollView(.vertical, showsIndicators: false) {
                            LazyVStack(alignment: .leading, spacing: 15) {
                                ForEach($playbackMedias, id: \.id) { $media in
                                    AudioItemView(media: media) { menuType, mediaItem in
                                        switch menuType {
                                        case .share:
                                            shareMedia = IdentifiableMedia(media: mediaItem)
                                        case .info:
                                            infoMedia = IdentifiableMedia(media: mediaItem)
                                        case .favorite:
                                            if mediaItem.isFavorite() {
                                                mediaItem.setFavorite(false)
                                            } else {
                                                mediaItem.setFavorite(true)
                                            }
                                            mediaLibrary.objectWillChange.send()
                                        case .delete:
                                            Task {
                                                await mediaLibrary.deleteMedia([mediaItem])
                                            }
                                        }
                                    }
                                    .onTapGesture {
                                        guard let index = MediaPlayerManager.shared.originalMedias.firstIndex(where: { $0.id == media.id }) else { return }
                                        MediaPlayerManager.shared.playFromPlaylist(index: index)
                                    }
                                    .sheet(item: $shareMedia, content: { item in
                                        ShareSheetView(items: [item.media.mainFile()!.mrl!])
                                            .presentationDetents([.medium])
                                    })
                                    .sheet(item: $infoMedia, content: { item in
                                        MediaInfoDetailView(media: item.media)
                                            .presentationDetents([.medium])
                                    })
                                }
                            }
                            .padding(15)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .safeAreaInset(edge: .top) {
                        HStack(spacing: 10) {
                            Button {
                                withAnimation(.bouncy) {
                                    dismiss()
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
                .frame(width: geometry.size.width, height: geometry.size.height)
                .background(BlurView(style: .dark).cornerRadius(20).ignoresSafeArea())
                .animation(.linear, value: currentOrientation)
            }
            .onAppear(perform: {
                playbackMedias = MediaPlayerManager.shared.originalMedias
            })
        }
    }
    
    func isPortrait(geometry: GeometryProxy) -> Bool {
        return geometry.size.height > geometry.size.width
    }
}

//#Preview {
//    PlaybackAudioQueueView()
//}
