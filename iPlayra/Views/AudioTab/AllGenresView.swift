//
//  AllGenresView.swift
//  iPlay
//
//  Created by Shiv on 03/12/25.
//

import SwiftUI
import VLCMediaLibraryKit
import Combine

struct AllGenresView: View {
    @StateObject private var appState: StateManager = .shared
    @StateObject private var mediaLibrary: MediaLibraryService = .shared
    
    @State private var shareMedia: IdentifiableMedia?
    @State private var infoMedia: IdentifiableMedia?
    
    var body: some View {
        ZStack {
            if !mediaLibrary.genres.isEmpty {
                ScrollView(.vertical) {
                    LazyVStack {
                        ForEach(mediaLibrary.genres, id: \.name) { genre in
                            VStack {
                                Text(genre.name)
                                    .font(.system(size: 15, weight: .medium, design: .default))
                                    .foregroundStyle(.theme.gradient)
                                    .padding(.horizontal, 15)
                                    .frame(maxWidth: .infinity, minHeight: 35, alignment: .leading)
                                    .background {
                                        RoundedRectangle(cornerRadius: .zero).fill(.ultraThinMaterial)
                                    }
                                VStack {
                                    ForEach(genre.tracks() ?? [], id: \.id) { media in
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
                                            guard let index = genre.tracks()?.firstIndex(of: media) else { return }
                                            MediaPlayerManager.shared.setupAndPlay(mlMedias: genre.tracks() ?? [], playIndex: index)
                                            appState.isShowAudioPlayer = true
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.bottom, 65)
                }
            } else {
                ContentUnavailableView("No Songs", systemImage: "music.note.slash", description: Text("kNotFoundDataYet".localized()))
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
    AllGenresView()
}
