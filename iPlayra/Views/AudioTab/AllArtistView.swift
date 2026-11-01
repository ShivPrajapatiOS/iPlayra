//
//  AllArtistView.swift
//  iPlay
//
//  Created by Shiv on 03/12/25.
//

import SwiftUI
import VLCMediaLibraryKit

struct AllArtistView: View {
    @StateObject private var appState: StateManager = .shared
    @StateObject var mediaLibrary: MediaLibraryService = .shared
    
    @State private var currentPlaybackArtist: VLCMLArtist? = nil
        
    var groupedArtists: [String: [VLCMLArtist]] {
        Dictionary(grouping: mediaLibrary.allAudioArtists) { artist in
            String(artist.name.prefix(1)).uppercased()
        }
    }
    
    var body: some View {
        ZStack {
            if !mediaLibrary.allAudioArtists.isEmpty {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(groupedArtists.keys.sorted(), id: \.self) { key in
                            VStack(alignment: .leading, spacing: 8) {
                                let headerTitle = key.isEmpty ? "#" : key
                                sectionHeader(headerTitle)
                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                    ForEach(groupedArtists[key] ?? [], id: \.self) { artist in
                                        NavigationLink {
                                            ArtistTrackView(artist: .constant(artist))
                                        } label: {
                                            artistCell(artist)
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
        .onAppear {
            currentPlaybackArtist = MediaPlayerManager.shared.currentMLMedia?.artist
        }
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
    
    // MARK: Artist Cell
    @ViewBuilder
    private func artistCell(_ artist: VLCMLArtist) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack {
                WebImageView(iconSize: 75, url: artist.artworkMRL(of: .thumbnail))
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
                        MediaPlayerManager.shared.setupAndPlay(mlMedias: artist.tracks() ?? [], playIndex: 0)
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
                if currentPlaybackArtist?.identifier() == artist.identifier() {
                    LineVisualizerView()
                        .padding(10)
                }
            }
            
            VStack(alignment: .leading, spacing: 3) {
                let title = artist.name == "" ? "Unknown" : artist.name
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .default))
                    .foregroundStyle(currentPlaybackArtist?.identifier() == artist.identifier() ? .theme : .white)
                    .lineLimit(1)
                let artistName = artist.musicBrainzId.isEmpty ? "Unknown" : artist.musicBrainzId
                Text(artistName)
                    .font(.system(size: 12, weight: .light, design: .default))
                    .foregroundStyle(currentPlaybackArtist?.identifier() == artist.identifier() ? .theme : .gray)
                    .lineLimit(1)
            }
        }
    }
}

#Preview {
    AllArtistView()
}
