//
//  SearchView.swift
//  iPlay
//
//  Created by Shiv on 07/02/26.
//

import SwiftUI
import VLCMediaLibraryKit
import Combine

struct SearchView: View {
    @StateObject private var mediaLibrary: MediaLibraryService = .shared
    @Binding var selectedTab: TabBar
    @Binding var dismiss: Bool
    
    @State private var txtSearch: String = ""
    @FocusState private var textFieldActive: Bool
    
    private var filteredMedias: [VLCMLMedia] {
        if selectedTab == .music {
            return mediaLibrary.audioMedias.filter { media in
                media.title.localizedCaseInsensitiveContains(txtSearch)
            }
        } else if selectedTab == .video {
            return mediaLibrary.videoMedias.filter { media in
                media.title.localizedCaseInsensitiveContains(txtSearch)
            }
        }
        return []
    }
    
    @State private var shareMedia: IdentifiableMedia?
    @State private var infoMedia: IdentifiableMedia?
    
    var body: some View {
        ZStack {
            BlurView(style: .dark)
                .ignoresSafeArea()
            switch selectedTab {
            case .music:
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack {
                        ForEach(filteredMedias, id: \.id) { media in
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
                            .padding(5)
                            .background(RoundedRectangle(cornerRadius: 10)
                                .fill(.ultraThinMaterial))
                            .onTapGesture {
                                guard let index = mediaLibrary.audioMedias.firstIndex(where: { $0.id == media.id }) else { return }
                                MediaPlayerManager.shared.setupAndPlay(mlMedias: mediaLibrary.audioMedias, playIndex: index, playbackType: .audio)
//                                isShowAudioPlayer.toggle()
                            }
                        }
                    }
                    .padding()
                }
            case .video:
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack {
                        ForEach(filteredMedias, id: \.id) { media in
                            VideoItemView(video: media) { (menuType, item) in
                                switch menuType {
                                case .share:
                                    self.shareMedia = IdentifiableMedia(media: item)
                                case .info:
                                    self.infoMedia = IdentifiableMedia(media: item)
                                case .delete:
                                    Task {
                                        await mediaLibrary.deleteMedia([item])
                                    }
                                }
                            }
                            .frame(height: 90)
                            .onTapGesture {
                                guard let index = filteredMedias.firstIndex(where: { $0.id == media.id }) else { return }
                                MediaPlayerManager.shared.setupAndPlay(mlMedias: filteredMedias, playIndex: index, playbackType: .video)
                                withAnimation(.linear(duration: 0.25)) {
//                                    isShowVideoPlayer.toggle()
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            case .me:
                EmptyView()
            case .edit:
                EmptyView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .top) {
            HStack(spacing: 16) {
                Button {
                    dismiss.toggle()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .regular, design: .default))
                        .foregroundStyle(.gray.opacity(0.5))
                        .frame(width: 35, height: 35)
                        .background(Capsule().fill(.ultraThinMaterial))
                }
                Capsule().fill(.ultraThinMaterial)
                    .frame(height: 40)
                    .overlay {
                        HStack {
                            TextField("Search audio, video...", text: $txtSearch)
                                .font(.system(size: 16, weight: .regular, design: .default))
                                .focused($textFieldActive)
                                .padding(.leading, 10)
                            Button {
                                txtSearch.removeAll()
                            } label: {
                                Image(systemName: txtSearch.isEmpty ? "magnifyingglass" : "xmark")
                                    .font(.system(size: 16, weight: .regular, design: .default))
                                    .foregroundStyle(txtSearch.isEmpty ? Color.gray.opacity(0.5).gradient : Color.theme.gradient)
                                    .frame(width: 30, height: 30)
                                    .background(Capsule().fill(Color("#FFFFFF").opacity(0.00001)))
                            }
                            .disabled(txtSearch.isEmpty)
                        }
                        .padding(.horizontal, 5)
                    }
                    .overlay {
                        Capsule()
                            .stroke(.gray.opacity(0.25), lineWidth: 1)
                    }
            }
            .frame(maxWidth: .infinity, maxHeight: 50)
            .padding(.horizontal, 16)
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
//    SearchView(selectedTab: .constant(.music), dismiss: .constant(false))
    ContentView()
}
