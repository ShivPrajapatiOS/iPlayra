//
//  ArtistTrackView.swift
//  iPlay
//
//  Created by Shiv on 16/09/25.
//

import SwiftUI
import Combine
import VLCMediaLibraryKit
import VLCKit

struct ArtistTrackView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var appState: StateManager = .shared
    @StateObject var mediaLibrary: MediaLibraryService = .shared
    @Binding var artist: VLCMLArtist
    @State private var selectedMediaForShare: IdentifiableMedia?
    @State private var selectedMediaForInfo: IdentifiableMedia?
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.background.ignoresSafeArea()
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 10) {
                    ForEach(artist.tracks() ?? [], id: \.id) { media in
                        AudioItemView(media: media) { menuType, mediaItem in
                            switch menuType {
                            case .share:
                                selectedMediaForShare = IdentifiableMedia(media: mediaItem)
                            case .info:
                                selectedMediaForInfo = IdentifiableMedia(media: mediaItem)
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
                            guard let index = artist.tracks()?.firstIndex(where: { $0.id == media.id }) else { return }
                            MediaPlayerManager.shared.setupAndPlay(mlMedias: artist.tracks() ?? [], playIndex: index, playbackType: .audio)
                            appState.isShowAudioPlayer = true
                            }
                            .sheet(item: $selectedMediaForShare) { item in
                                ShareSheetView(items: [item.media.mainFile()!.mrl])
                                    .presentationDetents([.medium])
                            }
                            .sheet(item: $selectedMediaForInfo) { item in
                                MediaInfoDetailView(media: item.media)
                                    .presentationDetents([.medium])
                            }
                    }
                }
                .padding()
            }
        }
        .navigationBarBackButtonHidden()
        .navigationBarTitleDisplayMode(.large)
        .navigationTitle(artist.name.isEmpty ? "Unknown" : artist.name)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar(content: {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .regular, design: .default))
                        .frame(width: 35, height: 35)
                        .foregroundStyle(.white)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        MediaPlayerManager.shared.setupAndPlay(mlMedias: artist.tracks() ?? [], playIndex: 0, playbackType: .audio)
                        appState.isShowAudioPlayer = true
                    } label: {
                        Label("\("kPlay".localized()) \("kAlbum".localized())", systemImage: "play.fill")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .rotationEffect(.degrees(90))
                        .font(.system(size: 16, weight: .regular, design: .default))
                        .frame(width: 35, height: 35)
                        .foregroundStyle(.white)
                }
                .menuStyle(.button)
            }
        })
    }
}

//#Preview {
//    ArtistTrackView(album: .constant(nil))
//}

