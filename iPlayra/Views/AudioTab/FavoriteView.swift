//
//  FavoriteView.swift
//  iPlay
//
//  Created by Shiv on 28/10/25.
//

import SwiftUI
import VLCMediaLibraryKit
import VLCKit

struct FavoriteView: View {
    @StateObject private var appState: StateManager = .shared
    @StateObject private var mediaLibrary: MediaLibraryService = .shared
    @State private var favoriteMedias: [VLCMLMedia] = []
    
    @State private var shareMedia: IdentifiableMedia?
    @State private var infoMedia: IdentifiableMedia?
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.background.ignoresSafeArea()
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack {
                    ForEach(favoriteMedias, id: \.id) { media in
                        AudioItemView(isFavorite: true, media: media)
                        .onTapGesture {
                            guard let index = favoriteMedias.firstIndex(where: { $0.id == media.id }) else { return }
                            MediaPlayerManager.shared.setupAndPlay(mlMedias: favoriteMedias, playIndex: index, playbackType: .audio)
                            appState.isShowAudioPlayer = true
                        }
                    }
                }
                .padding()
            }
        }
        .task {
            favoriteMedias = mediaLibrary.audioMedias.filter({ $0.isFavorite() })
        }
        .navigationBarTitleDisplayMode(.large)
        .navigationTitle("Favorite")
        .toolbar(content: {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    if !favoriteMedias.isEmpty {
                        Button {
                            MediaPlayerManager.shared.setupAndPlay(mlMedias: favoriteMedias, playIndex: 0)
                            appState.isShowAudioPlayer = true
                        } label: {
                            Label("kPlay".localized(), systemImage: "play.fill")
                        }
                    }
//                    Button(role: .destructive) {
//                        print("Remove all")
//                    } label: {
//                        Label("kRemoveAll".localized(), systemImage: "trash")
//                    }
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



//#Preview {
//    SongsListView()
//}
