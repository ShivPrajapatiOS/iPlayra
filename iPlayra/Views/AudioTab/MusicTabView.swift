//
//  MusicTabView.swift
//  iPlay
//
//  Created by Shiv on 31/08/25.
//

import SwiftUI
import VLCKit
import VLCMediaLibraryKit

struct MusicTabView: View {
    @StateObject private var mediaLibrary: MediaLibraryService = .shared
    @State private var selectedTab: MusicTopTab = .allSongs
    
    @Namespace private var animation
    
    @State private var isShowQueuePlaylist: Bool = false
    
    @Binding var isShowSearch: Bool
    
    @State private var selectedSortBy: SortByType = .date
    
    @State private var isShowCreatePlaylistAlert: Bool = false
    @State private var txtPlaylistName: String = ""
        
    var body: some View {
        ZStack {
            BlurView(style: .dark).blendMode(.plusDarker).ignoresSafeArea()
            Group {
                switch selectedTab {
                case .allSongs:
                    AllSongView()
                case .albums:
                    AllAlbumView()
                case .artists:
                    AllArtistView()
                case .genres:
                    AllGenresView()
                case .playlists:
                    AllPlayListView()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .toolbar(content: {
            if #available(iOS 26.0, *) {
                ToolbarItem(placement: .navigationBarLeading) {
                    IPlayLogoView()
                        .frame(width: 100)
                }
                .sharedBackgroundVisibility(.hidden)
            } else {
                ToolbarItem(placement: .navigationBarLeading) {
                    IPlayLogoView()
                        .frame(width: 100)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                HStack {
                    Button {
                        isShowSearch.toggle()
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }
                    Menu {
                        Text("Sort by")
                        Divider()
                        Picker("Sort by", selection: $selectedSortBy) {
                            Text("Date").tag(SortByType.date)
                            Text("Name").tag(SortByType.name)
                            Text("Length").tag(SortByType.length)
                            Text("Size").tag(SortByType.size)
                        }
                        .pickerStyle(.inline)
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                }
                .tint(Color("#FFFFFF"))
                .padding(.horizontal, 5)
            }
        })
        .safeAreaInset(edge: .top) {
            VStack(spacing: 0) {
                ScrollView(.horizontal) {
                    if #available(iOS 26.0, *) {
                        GlassEffectContainer(spacing: 10) {
                            HStack(spacing: 10) {
                                ForEach(MusicTopTab.allCases, id: \.self) { tab in
                                    let isSelected = selectedTab == tab
                                    
                                    Text(tab.title.localized())
                                        .font(.system(size: 16, weight: .medium))
                                        .padding(.horizontal, 20)
                                        .frame(height: 30)
                                        .foregroundStyle(isSelected ? .white : .gray)
                                        .glassEffect(
                                            isSelected
                                            ? .regular.tint(Color.theme).interactive()
                                            : .regular.interactive(),
                                            in: .capsule
                                        )
                                        .glassEffectID(tab, in: animation)
                                        .contentShape(.capsule)
                                        .onTapGesture {
                                            withAnimation(.snappy) {
                                                selectedTab = tab
                                            }
                                        }
                                }
                            }
                            .scrollTargetLayout()   // 👈 scrollPosition ke liye zaroori
                            .padding(.horizontal, 16)
                        }
                    } else {
                        LazyHStack(spacing: 10) {
                            ForEach(MusicTopTab.allCases, id: \.self) { tab in
                                Text(tab.title.localized())
                                    .font(.system(size: 16, weight: .medium))
                                    .padding(.horizontal, 20)
                                    .frame(height: 30)
                                    .foregroundStyle(selectedTab == tab ? .white : .gray)
                                    .background {
                                        Group {
                                            if selectedTab == tab {
                                                Capsule()
                                                    .fill(.theme.gradient)
                                                    .matchedGeometryEffect(id: "ACTIVETAD", in: animation)
                                                
                                            } else {
                                                Capsule()
                                                    .fill(.ultraThinMaterial)
                                                    .overlay(content: {
                                                        Capsule().stroke(.gray, lineWidth: 0.2)
                                                    })
                                            }
                                        }
                                    }
                                    .contentShape(.capsule)
                                    .onTapGesture {
                                        withAnimation(.snappy) {
                                            selectedTab = tab
                                        }
                                    }
                            }
                        }
                        .scrollTargetLayout()
                        .padding(.horizontal, 16)
                    }
                }
                .scrollIndicators(.hidden)
                .scrollPosition(id: Binding(
                    get: { selectedTab },
                    set: { if let new = $0 { selectedTab = new } }
                ), anchor: .center)
                .frame(height: 45)
                if selectedTab == .playlists {
                    HStack {
                        Text("\("kPlaylist".localized())\(mediaLibrary.playlists.count > 0 ? " (\(mediaLibrary.playlists.count + 1))" : "")")
                            .font(.system(size: 18, weight: .semibold, design: .default))
                        Spacer(minLength: 0)
                        Button {
                            isShowCreatePlaylistAlert.toggle()
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .light, design: .default))
                                .frame(width: 35, height: 35)
                                .background(content: {
                                    Capsule()
                                        .fill(.ultraThinMaterial)
                                        .overlay {
                                            Capsule()
                                                .stroke(Color("#5C5C5C").opacity(0.25), lineWidth: 1)
                                        }
                                })
                        }

                    }
                    .frame(maxWidth: .infinity, minHeight: 60)
                    .font(.system(size: 16, weight: .regular, design: .default))
                    .foregroundStyle(Color("#ffffff"))
                    .padding(.horizontal, 16)
                    .overlay(alignment: .top) {
                        Color("#5C5C5C").opacity(0.25)
                            .frame(height: 1)
                    }
                }
            }
        }
        .alert("kCreatePlaylist".localized(), isPresented: $isShowCreatePlaylistAlert, actions: {
            VStack {
                TextField("kEnterPlaylistName".localized(), text: $txtPlaylistName)
                HStack {
                    Button {
                        isShowCreatePlaylistAlert = false
                        txtPlaylistName = ""
                    } label: {
                        Text("kCancel".localized())
                    }
                    Button {
                        withAnimation {
                            mediaLibrary.isLoading = true
                            Task {
                                await mediaLibrary.createNewPlaylist(txtPlaylistName)
                                isShowCreatePlaylistAlert = false
                                txtPlaylistName = ""
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
        .onChange(of: selectedSortBy) { _, newValue in
//            mediaLibrary.filterAudios(newValue, audioListType: selectedTab)
        }
    }
}

#Preview {
//    MusicTabView(isShowPlayer: .constant(false), isShowSearch: .constant(false))
    ContentView()
//    AudioMiniPlayerView(isShowPlayer: .constant(false), isShowQueuePlaylist: .constant(false))
}
