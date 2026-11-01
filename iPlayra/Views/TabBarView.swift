//
//  TabBarView.swift
//  iPlay
//
//  Created by Shiv on 18/10/25.
//

import SwiftUI
import VLCKit
import UniformTypeIdentifiers

// MARK: - App TabBar Model
enum TabBar: String, CaseIterable, Hashable {
    case video, music, edit, me
    
    var title: String {
        switch self {
        case .video: return "kVideo"
        case .music: return "kMusic"
        case .edit: return "kEdit"
        case .me: return "kMe"
        }
    }
    
    var icon: String {
        switch self {
        case .video: return "play.rectangle.on.rectangle.fill"
        case .music: return "music.note"
        case .edit: return "pencil"
        case .me: return "person.fill"
        }
    }
}

struct TabBarView: View {
    @StateObject private var appState: StateManager = .shared
    @StateObject var languageManager: LocalizationManager = .shared

    @Binding var selectedTab: TabBar
    @Binding var showVideoPlayer: Bool
    
    @State private var isFilePickerPresented: Bool = false
    @State private var isGalleryPickerPresented: Bool = false
    @State private var isWiFiPickerPresented: Bool = false
    @State private var isShowSearch: Bool = false
    @State private var isExploreSearch: Bool = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(TabBar.allCases, id: \.self) { tab in
                NavigationStack {
                    tabContent(for: tab)
                }
                .tabItem {
                    Label(tab.title.localized(), systemImage: tab.icon)
                }
                .tag(tab)
                .tint(Color.theme)
            }
        }
        .miniPlayer(isShowPlayer: $appState.isShowAudioPlayer)
        .overlay(alignment: .bottomTrailing) {
            FloatingButtonMenu(options: [.fileManager, .gallery, .wifi]) { type in
                switch type {
                case .fileManager: isFilePickerPresented = true
                case .gallery: isGalleryPickerPresented = true
                case .wifi: isWiFiPickerPresented = true
                }
            }
            .padding(.bottom, 80)   // mini player/tab bar se upar
        }
        .fullScreenCover(isPresented: $appState.isShowAudioPlayer) {
            AudioPlayerView(isShowPlayer: $appState.isShowAudioPlayer, callBack: { isHide in
                showVideoPlayer = false
            })
            .presentationBackground(.clear)
        }
        .fileImporter(isPresented: $isFilePickerPresented, allowedContentTypes: UTType.audioTypes + UTType.videoTypes, allowsMultipleSelection: true, onCompletion: { result in
            switch result {
            case .success(let urls):
                Task {
                    for url in urls {
                        do {
                            _ = try await MediaLibraryService.shared.copyMediaToAppDirectoryAndAddToLibrary(from: url)
                        } catch {
                            print("Failed to import file: \(error.localizedDescription)")
                        }
                    }
                }
            case .failure(let error):
                print(error.localizedDescription)
            }
        })
        .fullScreenCover(isPresented: $isGalleryPickerPresented) {
            GalleryVideoPickerView(isPresented: $isGalleryPickerPresented) { urls in
                Task {
                    for url in urls {
                        do {
                            _ = try await MediaLibraryService.shared.copyMediaToAppDirectoryAndAddToLibrary(from: url)
                        } catch {
                            print("Failed to import file: \(error.localizedDescription)")
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $isWiFiPickerPresented) {
            WebServerView { url in
                Task {
                    do {
                        _ = try await MediaLibraryService.shared.copyMediaToAppDirectoryAndAddToLibrary(from: url)
                    } catch {
                        print("Failed to import file: \(error.localizedDescription)")
                    }
                }
            }
        }
        ZStack {
            if isShowSearch {
                SearchView(selectedTab: $selectedTab, dismiss: $isShowSearch)
                    .transition(.opacity.animation(.easeInOut))
            }
        }
    }
    
    @ViewBuilder
    private func tabContent(for tab: TabBar) -> some View {
        switch tab {
        case .video: VideoTabView(isShowVideoPlayer: $showVideoPlayer, isShowSearch: $isShowSearch)
        case .music: MusicTabView(isShowSearch: $isShowSearch)
        case .edit:  EditTabView()
        case .me:    MeTabView()
        }
    }
}

#Preview {
//    TabBarView(selectedTab: .constant(.music), showVideoPlayer: .constant(false))
    ContentView()
}
