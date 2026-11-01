//
//  LyricsView.swift
//  iPlay
//
//  Created by Shiv on 04/02/26.
//

import SwiftUI
import Translation
import VLCMediaLibraryKit

struct LyricsSearchView: View {
    @Binding var dismiss: Bool
    @ObservedObject var vmLyrics: LyricsViewModel
    
    @State private var isSyncedLyrics: Bool = true
    @State private var txtSearch: String = ""
    @FocusState private var textFieldActive: Bool
    
    var body: some View {
        ZStack {
            BlurView(style: .dark)
                .ignoresSafeArea()
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(vmLyrics.lyrics, id: \.id) { track in
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.ultraThinMaterial)
                            .frame(height: 70)
                            .overlay(alignment: .leading) {
                                HStack {
                                    Image(systemName: "music.note.list")
                                        .font(.system(size: 18, weight: .light, design: .default))
                                        .foregroundStyle(.theme)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(track.name ?? "Unknown")
                                            .font(.system(size: 16, weight: .medium, design: .default))
                                            .foregroundStyle(.white)
                                        VStack(alignment: .leading, spacing: 3) {
                                            HStack {
                                                Text(track.duration?.toDisplayTime() ?? "0:00")
                                                    .font(.system(size: 12, weight: .light, design: .default))
                                                    .foregroundStyle(.white)
                                                    .padding(.horizontal, 7)
                                                    .padding(.vertical, 1.5)
                                                    .background(RoundedRectangle(cornerRadius: 4).fill(.theme.opacity(0.25)))
                                                if track.syncedLyrics != nil {
                                                    Text("Synced")
                                                        .font(.system(size: 12, weight: .light, design: .default))
                                                        .foregroundStyle(.white)
                                                        .padding(.horizontal, 7)
                                                        .padding(.vertical, 1.5)
                                                        .background(RoundedRectangle(cornerRadius: 4).fill(.green.opacity(0.25)))
                                                }
                                                if track.plainLyrics != nil {
                                                    Text("Plain")
                                                        .font(.system(size: 12, weight: .light, design: .default))
                                                        .foregroundStyle(.white)
                                                        .padding(.horizontal, 7)
                                                        .padding(.vertical, 1.5)
                                                        .background(RoundedRectangle(cornerRadius: 4).fill(.yellow.opacity(0.25)))
                                                }
                                                if track.instrumental ?? false {
                                                    Text("Instrumental")
                                                        .font(.system(size: 12, weight: .light, design: .default))
                                                        .foregroundStyle(.white)
                                                        .padding(.horizontal, 7)
                                                        .padding(.vertical, 1.5)
                                                        .background(RoundedRectangle(cornerRadius: 4).fill(.gray.opacity(0.25)))
                                                }
                                            }
                                            Text("Artists: \(track.artistName)")
                                                .font(.system(size: 12, weight: .light, design: .default))
                                        }
                                    }
                                    Spacer(minLength: 0)
                                    Button {
                                        vmLyrics.isLoading = true
                                        if let syncedLyrics = track.syncedLyrics {
                                            vmLyrics.syncedLyricLines = syncedLyrics.parseSynced()
                                            isSyncedLyrics = true
                                        } else if let plainLyrics = track.plainLyrics {
                                            vmLyrics.plainLyric = plainLyrics.parsePlain()
                                            isSyncedLyrics = false
                                        } else {
                                            print("Lyrics not available for this track")
                                        }
                                        Task {
                                            try? await Task.sleep(nanoseconds: 2_000_000_000)
                                            vmLyrics.isLoading = false
                                        }
                                    } label: {
                                        Image(systemName: "eye")
                                            .font(.system(size: 18, weight: .light, design: .default))
                                            .foregroundStyle(.white)
                                            .frame(width: 35, height: 35)
                                            .background(Capsule().fill(.theme.opacity(0.001)))
                                    }
                                    
                                }
                                .padding(.horizontal, 10)
                            }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
            }
            if let error = vmLyrics.errorMessage {
                Text(error)
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundStyle(.gray.opacity(0.5))
            }
            ZStack {
                if !vmLyrics.syncedLyricLines.isEmpty || !vmLyrics.plainLyric.isEmpty {
                    Color.background.ignoresSafeArea()
                    if isSyncedLyrics {
                        if vmLyrics.syncedLyricLines.isEmpty {
                            Text("Synced Lyrics not available this track")
                                .font(.system(size: 16, weight: .regular, design: .default))
                                .foregroundStyle(.gray.opacity(0.5))
                        }
                    } else {
                        if vmLyrics.plainLyric.isEmpty {
                            Text("Synced Lyrics not available this track")
                                .font(.system(size: 16, weight: .regular, design: .default))
                                .foregroundStyle(.gray.opacity(0.5))
                        }
                    }
                    if !isSyncedLyrics {
                        ScrollView(.vertical, showsIndicators: false) {
                            LazyVStack {
                                ForEach(vmLyrics.plainLyric, id: \.self) { plainLine in
                                    Text(plainLine)
                                        .font(.system(size: 16, weight: .regular, design: .default))
                                        .foregroundStyle(.white)
                                }
                            }
                        }
                    } else {
                        LyricsView(syncedLyricLines: vmLyrics.syncedLyricLines) {
                            vmLyrics.plainLyric.removeAll()
                            vmLyrics.syncedLyricLines.removeAll()
                            vmLyrics.lyrics.removeAll()
                            txtSearch.removeAll()
                            let title = MediaPlayerManager.shared.currentMLMedia?.title.cleanSongTitle() ?? ""
                            txtSearch = title
                            lyricsAPICalling(txtSearch)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .top) {
            HStack {
                Button {
                    if vmLyrics.plainLyric.isEmpty && vmLyrics.syncedLyricLines.isEmpty {
                        dismiss.toggle()
                    } else {
                        vmLyrics.plainLyric.removeAll()
                        vmLyrics.syncedLyricLines.removeAll()
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .regular, design: .default))
                        .foregroundStyle(.gray.opacity(0.5))
                        .frame(width: 35, height: 35)
                        .background(Capsule().fill(.gray.opacity(0.25)))
                }
                Capsule().fill(.ultraThinMaterial)
                    .frame(height: 40)
                    .overlay {
                        HStack {
                            TextField("Search for lyrics", text: $txtSearch)
                                .focused($textFieldActive)
                                .padding(.leading, 10)
                            Button {
                                lyricsAPICalling(txtSearch)
                            } label: {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 15, weight: .regular, design: .default))
                                    .foregroundStyle(txtSearch.isEmpty ? Color.gray.opacity(0.5).gradient : Color.theme.gradient)
                                    .frame(width: 30, height: 30)
                                    .background(Capsule().fill(.ultraThinMaterial))
                            }
                            .disabled(txtSearch.isEmpty)
                        }
                        .padding(.horizontal, 5)
                    }
                    .overlay {
                        Capsule().fill(.clear)
                            .stroke(.gray.opacity(0.25), lineWidth: 1)
                    }
                    .opacity(vmLyrics.syncedLyricLines.isEmpty && vmLyrics.plainLyric.isEmpty ? 1 : 0)
                if !vmLyrics.syncedLyricLines.isEmpty || !vmLyrics.plainLyric.isEmpty {
                    Button {
                        withAnimation(.bouncy) {
                            isSyncedLyrics.toggle()
                        }
                    } label: {
                        Text(isSyncedLyrics ? "Synced" : "Plain")
                            .lineLimit(1)
                            .frame(height: 30)
                            .font(.system(size: 15, weight: .regular, design: .default))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 15)
                            .background(Capsule().fill(isSyncedLyrics ? .green.opacity(0.25) : .yellow.opacity(0.25)).overlay(content: {
                                Capsule().fill(.clear).stroke(isSyncedLyrics ? .green : .yellow, lineWidth: 1)
                            }))
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: 50)
            .padding(.horizontal, 16)
        }
        .onAppear {
            if vmLyrics.lyrics.isEmpty {
                let title = MediaPlayerManager.shared.currentMLMedia?.title.cleanSongTitle() ?? ""
                txtSearch = title
                lyricsAPICalling(txtSearch)
            }
        }
    }
    
    private func lyricsAPICalling(_ search: String) {
        Task {
            GlobalLoader.shared.show()
            vmLyrics.isLoading = true
            do {
                let response = try await vmLyrics.performSearch(for: search)
                vmLyrics.lyrics = response
                vmLyrics.isLoading = false
                vmLyrics.errorMessage = nil
                GlobalLoader.shared.hide()
            } catch {
                vmLyrics.errorMessage = error.localizedDescription
                vmLyrics.isLoading = false
                vmLyrics.lyrics = []
                GlobalLoader.shared.hide()
            }
        }
    }
}

struct LyricsView: View {
    @StateObject private var player: MediaPlayerManager = .shared
    var syncedLyricLines: [LyricLine]
    private var activeLineId: UUID? {
        return syncedLyricLines.last(where: { $0.startMiliseconds <= player.miliseconds })?.id
    }
    
    var playbackEndedAction: (() -> Void)?
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 25) {
                    ForEach(syncedLyricLines, id: \.id) { line in
                        let isActive = (line.id == activeLineId)
                        
                        HStack {
                            Text(line.startTime.toDisplayTime())
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.3))
                                .frame(width: 45, alignment: .leading)
                            
                            Text(line.text)
                                .font(.system(size: isActive ? 20 : 18, weight: isActive ? .semibold : .medium, design: .rounded))
                                .foregroundStyle(isActive ? .white : .white.opacity(0.4))
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isActive)
                        }
                        .id(line.id)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, (UIScreen.main.bounds.height * 0.5))
            }
            .onChange(of: activeLineId) { (oldId, newId) in
                if let id = newId {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        proxy.scrollTo(id, anchor: .center)
                    }
                }
            }
        }
        .onChange(of: MediaPlayerManager.shared.currentMLMedia, { oldValue, newValue in
                playbackEndedAction?()
        })
    }
}

#Preview {
    LyricsSearchView(dismiss: .constant(false), vmLyrics: LyricsViewModel())
}
