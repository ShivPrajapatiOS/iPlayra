//
//  AllAlbumView.swift
//  iPlay
//
//  Created by Shiv on 03/12/25.
//

import SwiftUI
import VLCMediaLibraryKit

struct AllAlbumView: View {
    @StateObject private var appState: StateManager = .shared
    @StateObject var mediaLibrary: MediaLibraryService = .shared
        
    @State private var currentPlaybackAlbum: VLCMLAlbum? = nil
    
    var groupedAlbums: [String: [VLCMLAlbum]] {
        Dictionary(grouping: mediaLibrary.allAudioAlbums) { album in
            String(album.title.prefix(1)).uppercased()
        }
    }
    
    var body: some View {
        ZStack {
            if !mediaLibrary.allAudioAlbums.isEmpty {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(groupedAlbums.keys.sorted(), id: \.self) { key in
                            VStack(alignment: .leading, spacing: 8) {
                                let headerTitle = key.isEmpty ? "#" : key
                                sectionHeader(headerTitle)
                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                    ForEach(groupedAlbums[key] ?? [], id: \.self) { album in
                                        NavigationLink {
                                            AlbumTrackView(album: .constant(album))
                                        } label: {
                                            albumCell(album)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.bottom, 12)
                            }
                        }
                    }
                }
            } else {
                ContentUnavailableView("No Songs", systemImage: "music.note.slash", description: Text("kNotFoundDataYet".localized()))
            }
        }
        .onAppear(perform: {
            currentPlaybackAlbum = MediaPlayerManager.shared.currentMLMedia?.album
        })
    }
    
    // MARK: Section Header (A, B, C...)
    @ViewBuilder
    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 18, weight: .bold, design: .default))
                .foregroundStyle(.theme)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .background(Color.background)
    }
    
    // MARK: Album Cell
    @ViewBuilder
    private func albumCell(_ album: VLCMLAlbum) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack {
                WebImageView(iconSize: 75, url: album.artworkMRL(of: .thumbnail))
                    .frame(width: (UIScreen.main.bounds.width / 2) - 24, height: (UIScreen.main.bounds.width / 2) - 24)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .overlay(alignment: .trailing) {
                VStack {
                    Button {
                        print("More")
                    } label: {
                        Capsule().fill(.ultraThinMaterial)
                            .frame(width: 35, height: 15)
                            .overlay {
                                Image(systemName: "ellipsis")
                                    .font(.system(size: 20, weight: .bold, design: .default))
                                    .foregroundStyle(.white)
                            }
                    }
                    Spacer(minLength: 0)
                    Button {
                        MediaPlayerManager.shared.setupAndPlay(mlMedias: album.tracks ?? [], playIndex: 0)
                        appState.isShowAudioPlayer = true
                    } label: {
                        Capsule().fill(.theme.gradient)
                            .frame(width: 35, height: 35)
                            .overlay {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 15, weight: .light, design: .default))
                                    .foregroundStyle(.white)
                            }
                    }
                }
                .padding(10)
            }
            .overlay(alignment: .bottomLeading) {
                if currentPlaybackAlbum?.identifier() == album.identifier() {
                    LineVisualizerView()
                        .padding(10)
                }
            }
            
            VStack(alignment: .leading, spacing: 3) {
                let title = album.title == "" ? "Unknown" : album.title
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .default))
                    .foregroundStyle(currentPlaybackAlbum?.identifier() == album.identifier() ? .theme : .white)
                    .lineLimit(1)
                let artistName = album.albumArtist?.name == "" ? "Unknown" : album.albumArtist?.name ?? "Unknown"
                Text(artistName)
                    .font(.system(size: 12, weight: .light, design: .default))
                    .foregroundStyle(currentPlaybackAlbum?.identifier() == album.identifier() ? .theme : .gray)
                    .lineLimit(1)
            }
        }
    }
}

#Preview {
    AllAlbumView()
}
