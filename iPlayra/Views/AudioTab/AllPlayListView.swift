//
//  AllPlayListView.swift
//  iPlay
//
//  Created by Shiv on 03/12/25.
//

import SwiftUI
import VLCMediaLibraryKit

enum PlayListMenuType: String, CaseIterable {
    case play, rename, delete
}

struct AllPlayListView: View {
    @StateObject private var appState: StateManager = .shared
    @StateObject var mediaLibrary: MediaLibraryService = .shared
    
    @State private var showRenamePlaylistAlert: Bool = false
    @State private var txtRenamePlaylist: String = ""
    @State private var renamePlaylist: VLCMLPlaylist? = nil
    
    var body: some View {
        ZStack {
            ScrollView(.vertical) {
                LazyVStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 10) {
                        NavigationLink {
                            FavoriteView()
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "suit.heart.fill")
                                    .font(.system(size: 35, weight: .regular, design: .default))
                                    .foregroundStyle(LinearGradient(colors: [.theme, .purple], startPoint: .bottomLeading, endPoint: .topTrailing))
                                    .frame(maxWidth: 60, maxHeight: .infinity)
                                    .background(Color("#5C5C5C").opacity(0.25))
                                    .cornerRadius(5)
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("kFavorite".localized())
                                        .font(.system(size: 16, weight: .regular, design: .default))
                                        .foregroundStyle(Color("#FFFFFF"))
                                    Text("\(mediaLibrary.audioMedias.filter { $0.isFavorite() }.count) \("kSongs".localized())")
                                        .font(.system(size: 12, weight: .light, design: .default))
                                        .foregroundStyle(Color("#5C5C5C"))
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        Button {
                            print("Play")
                        } label: {
                            Image(systemName: "play.fill")
                                .font(.system(size: 18, weight: .black, design: .default))
                                .frame(width: 40, height: 40)
                                .foregroundStyle(.theme.gradient)
                        }
                    }
                    .frame(height: 60)
                    ForEach(mediaLibrary.playlists, id: \.name) { playlist in
                        NavigationLink {
                            PlaylistAudioView(playlistIds: playlist.identifier())
                        } label: {
                            PlayListItemView(playlist: playlist, menuAction: { (menu, playList) in
                                switch menu {
                                case .play:
                                    guard let index = playlist.media?.firstIndex(where: { $0.identifier() == playlist.identifier() }) else { return }
                                    MediaPlayerManager.shared.setupAndPlay(mlMedias: playlist.media ?? [], playIndex: index, playbackType: .audio)
                                    appState.isShowAudioPlayer = true
                                case .rename:
                                    renamePlaylist = playlist
                                    txtRenamePlaylist = playlist.name
                                    showRenamePlaylistAlert.toggle()
                                case .delete:
                                    Task {
                                        await mediaLibrary.deletePlaylist(playlist.identifier())
                                    }
                                }
                            })
                            .frame(height: 60)
                        }
                    }
                }
                .padding(.bottom, 65)
                .padding(.horizontal, 16)
            }
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
                        withAnimation {
                            mediaLibrary.isLoading = true
                            Task {
                                renamePlaylist?.updateName(txtRenamePlaylist)
                                try? await Task.sleep(nanoseconds: 1_000_000_000)
                                showRenamePlaylistAlert = false
                                txtRenamePlaylist = ""
                            }
                        }
                    } label: {
                        Text("kDone".localized())
                    }
                }
            }
        }, message: {
            Text("")
        })
    }
}

struct PlayListItemView: View {
    let playlist: VLCMLPlaylist
    @State var isPlaying: VLCMLPlaylist? = nil

    var menuAction: ((PlayListMenuType, VLCMLPlaylist) -> Void)? = nil
    
    var body: some View {
        ZStack {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 5).fill(.ultraThinMaterial)
                    .frame(width: 60, height: 60)
                    .overlay(content: {
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(.gray.opacity(0.2), lineWidth: 1)
                    })
                    .overlay {
                        Image(systemName: "music.note.list")
                            .font(.system(size: 30, weight: .light, design: .default))
                            .foregroundStyle(LinearGradient(colors: [.theme, .pink, .purple], startPoint: .bottomLeading, endPoint: .topTrailing))
                    }
                    .overlay {
                        if isPlaying == playlist {
                            ZStack {
                                BlurView(style: .dark)
                                    .opacity(0.5)
                                    .cornerRadius(5)
                                LineVisualizerView()
                            }
                        }
                    }
                VStack(alignment: .leading, spacing: 6) {
                    Text(playlist.name)
                        .font(.system(size: 16, weight: .regular, design: .default))
                        .foregroundStyle(.white)
                    Text("\(playlist.nbMedia()) \("kSongs".localized())")
                        .font(.system(size: 12, weight: .light, design: .default))
                        .foregroundStyle(.gray)
                }
                Spacer(minLength: 0)
                Menu {
                    if playlist.media != nil {
                        Button {
                            menuAction?(.play, playlist)
                        } label: {
                            Label("Play".localized(), systemImage: "play.fill")
                        }
                    }
                    
                    Button {
                        menuAction?(.rename, playlist)
                    } label: {
                        Label("Rename".localized(), systemImage: "square.and.pencil")
                    }
                    
                    Button(role: .destructive) {
                        menuAction?(.delete, playlist)
                    } label: {
                        Label("Delete".localized(), systemImage: "trash")
                    }

                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(.theme.gradient)
                        .frame(width: 35, height: 20)
                        .background(Capsule().fill(.ultraThinMaterial))
                }

            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .onAppear(perform: {
            isPlaying = checkPlayingList()
        })
        .onReceive(MediaPlayerManager.shared.event) { obje in
            switch obje {
            case .currentMedia(_, _):
                isPlaying = checkPlayingList()
            default: break;
            }
        }
    }
    
    private func checkPlayingList() -> VLCMLPlaylist? {
        if MediaPlayerManager.shared.originalMedias.isEmpty {
            return nil
        } else {
            let set1 = Set(playlist.media?.map { $0.identifier() } ?? [])
            let set2 = Set(MediaPlayerManager.shared.originalMedias.map { $0.identifier() })
            if set1 == set2 {
                return playlist
            } else {
                return nil
            }
        }
    }
}

#Preview {
    AllPlayListView()
//    PlayListItemView()
}
