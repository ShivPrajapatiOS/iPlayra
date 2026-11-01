//
//  AllSongView.swift
//  iPlay
//
//  Created by Shiv on 01/12/25.
//

import SwiftUI
import VLCMediaLibraryKit
import VLCKit
import Combine

struct AllSongView: View {
    @StateObject private var appState: StateManager = .shared
    @StateObject var mediaLibrary: MediaLibraryService = .shared
        
    
    @State private var shareMedia: IdentifiableMedia?
    @State private var infoMedia: IdentifiableMedia?
    
    var body: some View {
        ZStack {
            VStack {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack {
                        ForEach(mediaLibrary.audioMedias, id: \.id) { media in
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
                                guard let index = mediaLibrary.audioMedias.firstIndex(where: { $0.id == media.id }) else { return }
                                MediaPlayerManager.shared.setupAndPlay(mlMedias: mediaLibrary.audioMedias, playIndex: index, playbackType: .audio)
                                appState.isShowAudioPlayer = true
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .sheet(item: $shareMedia, content: { item in
            ShareSheetView(items: [item.media.mainFile()!.mrl])
                .presentationDetents([.medium])
        })
        .sheet(item: $infoMedia, content: { item in
            MediaInfoDetailView(media: item.media)
                .presentationDetents([.medium])
        })
    }
}


#Preview {
    AllSongView()
}
