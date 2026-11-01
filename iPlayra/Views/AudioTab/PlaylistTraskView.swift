//
//  PlaylistTraskView.swift
//  iPlay
//
//  Created by Shiv on 25/09/25.
//

import SwiftUI
import VLCMediaLibraryKit
import VLCKit
import Combine

struct PlaylistAudioView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var appState: StateManager = .shared
    @StateObject private var mediaLibrary: MediaLibraryService = .shared
    let playlistIds: VLCMLIdentifier

    @State private var playList: VLCMLPlaylist?
    
    @State private var shareMedia: IdentifiableMedia?
    @State private var infoMedia: IdentifiableMedia?
    
    @State private var showRenamePlaylistAlert: Bool = false
    @State private var txtRenamePlaylist: String = ""
    
    @State private var isShowMediaList: Bool = false
    
    @State private var selectedMediaIDs: Set<VLCMLIdentifier> = []
    
    var body: some View {
        ZStack {
            VStack {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack {
                        ForEach((playList?.media ?? []), id: \.id) { media in
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
                            .frame(height: 60)
                            .onTapGesture {
                                guard let index = playList?.media?.firstIndex(where: { $0.id == media.id }) else { return }
                                MediaPlayerManager.shared.setupAndPlay(mlMedias: playList?.media ?? [], playIndex: index, playbackType: .audio)
                                appState.isShowAudioPlayer = true
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            if playList?.nbMedia() == 0 {
                VStack(spacing: 20) {
                    Text("Audio medias add playlist for plus media ")
                        .font(.system(size: 11, weight: .regular, design: .default))
                        .foregroundStyle(.gray)
                    Button {
                        isShowMediaList.toggle()
                    } label: {
                        HStack {
                            Image(systemName: "plus")
                                Text("Media")
                        }
                        .font(.system(size: 16, weight: .regular, design: .default))
                        .foregroundStyle(Color("#ffffff"))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(RoundedRectangle(cornerRadius: 5).fill(.theme.gradient).overlay(content: {
                            RoundedRectangle(cornerRadius: 5).stroke(.gray.gradient, lineWidth: 0.2)
                        }))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationBarBackButtonHidden(true)
        .safeAreaInset(edge: .top) {
            HStack(spacing: 20) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.backward")
                        .font(.system(size: 18, weight: .regular, design: .default))
                        .foregroundStyle(Color("#ffffff"))
                        .frame(width: 35, height: 35)
                        .background(Capsule().fill(.ultraThinMaterial).overlay(content: {
                            Capsule().stroke(.gray.gradient, lineWidth: 0.2)
                        }))
                }
                Text(playList?.name ?? "Unowned")
                    .font(.system(size: 20, weight: .bold, design: .default))
                    .foregroundStyle(Color("#ffffff"))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(10)
                Menu {
                    Button {
                        withAnimation {
                            isShowMediaList.toggle()
                        }
                    } label: {
                        Label("kAddSongs".localized(), systemImage: "music.note")
                    }
                    Button {
                        txtRenamePlaylist = playList?.name ?? ""
                        showRenamePlaylistAlert.toggle()
                    } label: {
                        Label("kEditDetail".localized(), systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        print("Delete")
                    } label: {
                        Label("Delete".localized(), systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 18, weight: .regular, design: .default))
                        .foregroundStyle(Color("#ffffff"))
                        .frame(width: 35, height: 35)
                        .background(Capsule().fill(.ultraThinMaterial).overlay(content: {
                            Capsule().stroke(.gray.gradient, lineWidth: 0.2)
                        }))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: 50, alignment: .leading)
            .padding(.horizontal)
            .background(BlurView(style: .dark).blendMode(.plusDarker).ignoresSafeArea()
                .overlay(alignment: .bottom, content: {
                    Rectangle().fill(.gray.gradient.opacity(0.25))
                        .frame(height: 1)
                }))
        }
        .alert("Rename Playlist".localized(), isPresented: $showRenamePlaylistAlert, actions: {
            VStack {
                TextField("kEnterPlaylistName".localized(), text: $txtRenamePlaylist)
                HStack {
                    Button {
                        showRenamePlaylistAlert = false
                        txtRenamePlaylist = ""
                    } label: {
                        Text("kCancel".localized())
                    }
                    Button {
                        let newName = txtRenamePlaylist
                        if !newName.isEmpty {
                            playList?.updateName(newName)
                            
                            mediaLibrary.objectWillChange.send()
                            
                            showRenamePlaylistAlert = false
                        }
                    } label: {
                        Text("kDone".localized())
                    }
                }
            }
        }, message: {
            Text("")
        })
        .sheet(item: $shareMedia) { item in
            ShareSheetView(items: [item.media.mainFile()!.mrl!])
                .presentationDetents([.medium])
        }
        .sheet(item: $infoMedia) { item in
            MediaInfoDetailView(media: item.media)
                .presentationDetents([.medium])
        }
        .fullScreenCover(isPresented: $isShowMediaList) {
            ZStack {
                VStack {
                    HStack {
                        Button {
                            isShowMediaList.toggle()
                        } label: {
                            Image(systemName: "chevron.backward")
                                .font(.system(size: 18, weight: .regular, design: .default))
                                .foregroundStyle(Color("#ffffff"))
                                .frame(width: 35, height: 35)
                                .background(Capsule().fill(.ultraThinMaterial).overlay(content: {
                                    Capsule().stroke(.gray.gradient, lineWidth: 0.2)
                                }))
                        }
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: 50, alignment: .leading)
                    .padding(.horizontal)
                    .background(BlurView(style: .dark).blendMode(.plusDarker).ignoresSafeArea()
                        .overlay(alignment: .bottom, content: {
                            Rectangle().fill(.gray.gradient.opacity(0.25))
                                .frame(height: 1)
                        }))
                    .overlay(content: {
                        Text("\("kSelected".localized())(\(selectedMediaIDs.count))")
                            .font(.system(size: 15, weight: .regular, design: .default))
                            .foregroundStyle(.white)
                    })
                    Spacer()
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack {
                            ForEach(Array(mediaLibrary.audioMedias.enumerated()), id: \.offset) { (index, media) in
                                let isMediaSelected = selectedMediaIDs.contains(media.identifier())
                                SelectAudioItemView(media: .constant(media), isSelected: .constant(isMediaSelected)) { media, currentSelectionState in
                                    toggleMediaSelection(media: media, isSelected: currentSelectionState, index: index)
                                }
                            }
                        }
                    }
                }
            }
            .onAppear(perform: {
                self.playList = mediaLibrary.playlists.first(where: { $0.identifier() == playlistIds })
                updateSelectedMediaIDs()
            })
        }
        .onAppear(perform: {
            self.playList = mediaLibrary.playlists.first(where: { $0.identifier() == playlistIds })
        })
    }
    
    private func toggleMediaSelection(media: VLCMLMedia, isSelected: Bool, index: Int) {
                if isSelected {
                    if let indexToRemove = playList?.media?.firstIndex(where: { $0.identifier() == media.identifier() }) {
                        playList?.removeMedia(fromPosition: UInt32(indexToRemove))
                        selectedMediaIDs.remove(media.identifier())
                        print("Removed media: \(media.title)")
                    }
                } else {
                    // Media is not selected, so add it
                    playList?.addMedia(media, atPosition: UInt32(index))
                    selectedMediaIDs.insert(media.identifier())
                    print("Added media: \(media.title)")
                }
        }
    
    private func updateSelectedMediaIDs() {
        self.selectedMediaIDs = Set(playList?.media?.compactMap { $0.identifier() } ?? [])
    }
}

#Preview {
    PlaylistAudioView(playlistIds: .max)
}

struct SelectAudioItemView: View {
    @Binding var media: VLCMLMedia
    @Binding var isSelected: Bool
    
    var selectAction: (_ media: VLCMLMedia, _ isSelected: Bool) -> Void = { _, _ in }
    
    var body: some View {
        ZStack {
            HStack {
                HStack {
                    ZStack {
                        WebImageView(url: media.thumbnail(of: .thumbnail))
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                    }
                    .frame(width: 50, height: 50)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(media.title)
                            .font(.system(size: 16, weight: .regular, design: .default))
                            .lineLimit(1)
                        Text(media.artist?.name ?? "Unknown Artist")
                            .lineLimit(1)
                            .font(.system(size: 12, weight: .light, design: .default))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                Button {
                    withAnimation {
                        selectAction(media, isSelected)
                    }
                } label: {
                    Image(systemName: isSelected ? "minus" : "plus")
                        .symbolEffect(.bounce, value: isSelected)
                        .font(.system(size: 15, weight: .regular, design: .default))
                        .foregroundStyle(Color("#ffffff"))
                        .frame(width: 30, height: 30)
                        .background(Capsule().fill(isSelected ? .gray.opacity(0.5) : .theme.opacity(0.5)).overlay(content: {
                            Capsule().stroke(.gray.gradient, lineWidth: 0.2)
                        }))
                }
                .buttonStyle(.plain)
                
            }
            .frame(maxWidth: .infinity, maxHeight: 60)
            .foregroundStyle(.white)
            .cornerRadius(5)
            .padding(.horizontal, 20)
        }
    }
}
