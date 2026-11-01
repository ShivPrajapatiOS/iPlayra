//
//  VideoTabView.swift
//  iPlay
//
//  Created by Shiv on 31/08/25.
//

import SwiftUI
import UniformTypeIdentifiers
import UIKit
import VLCMediaLibraryKit
import VLCKit

struct VideoTabView: View {
    @StateObject private var mediaLibrary: MediaLibraryService = .shared
    
    @Binding var isShowVideoPlayer: Bool
    @Binding var isShowSearch: Bool
    
    @State private var shareMedia: IdentifiableMedia?
    @State private var infoMedia: IdentifiableMedia?
    
    @State private var selectedSortBy: SortByType = .date
    
    @State private var isGridView: Bool = false
    @Namespace private var animation
    
    var gridColumns: [GridItem] {
        [GridItem(.flexible(), spacing: 15), GridItem(.flexible(), spacing: 15)]
    }
    
    var body: some View {
        GeometryReader { geoProxy in
            ZStack {
                BlurView(style: .dark).blendMode(.plusDarker).ignoresSafeArea()
                VStack {
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack {
                            if isGridView {
                                LazyVGrid(columns: gridColumns, spacing: 20) {
                                    itemsList
                                }
                                .padding(.horizontal)
                            } else {
                                LazyVStack(spacing: 15) {
                                    itemsList
                                }
                                .padding(.horizontal)
                            }
                        }
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
                        Button {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.9, blendDuration: 0)) {
                                isGridView.toggle()
                            }
                        } label: {
                            Image(systemName: isGridView ? "rectangle.grid.1x2" : "square.grid.2x2")
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
                            Image(systemName: "line.3.horizontal.decrease")
                        }
                    }
                    .tint(Color("#FFFFFF"))
                    .padding(.horizontal, 5)
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
            .onChange(of: selectedSortBy) { _, newValue in
//                mediaLibrary.filterVideos(newValue)
            }
        }
    }
    
    var itemsList: some View {
        ForEach(mediaLibrary.videoMedias, id: \.id) { media in
            Group {
                if isGridView {
                    VideoItemGridView(video: media)
                        .matchedGeometryEffect(id: media.id, in: animation)
                        .frame(height: 135)
                } else {
                    VideoItemView(video: media) { (menuType, item) in
                        handleMenuAction(menuType, item: item)
                    }
                    .matchedGeometryEffect(id: media.id, in: animation)
                    .frame(height: 90)
                }
            }
            .onTapGesture {
                handleTap(media: media)
            }
        }
    }
    
    private func handleTap(media: VLCMLMedia) {
        guard let index = mediaLibrary.videoMedias.firstIndex(where: { $0.id == media.id }) else { return }
        MediaPlayerManager.shared.setupAndPlay(mlMedias: mediaLibrary.videoMedias, playIndex: index, playbackType: .video)
        if !isShowVideoPlayer {
            withAnimation(.linear(duration: 0.25)) { isShowVideoPlayer.toggle() }
        }
    }
    
    private func handleMenuAction(_ type: VideoMenuType, item: VLCMLMedia) {
        switch type {
        case .share: self.shareMedia = IdentifiableMedia(media: item)
        case .info: self.infoMedia = IdentifiableMedia(media: item)
        case .delete: Task { await mediaLibrary.deleteMedia([item]) }
        }
    }
}

// MARK: - MediaThumbnailView
struct MediaThumbnailView: View {
    @StateObject private var loadManager = MediaThumbnailManager()
    let media: VLCMLMedia
    let size: CGSize
    
    var body: some View {
        Group {
            if let image = loadManager.thumbnail {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .cornerRadius(6)
            } else {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color("202020"))
                        .overlay(
                            ProgressView().progressViewStyle(.circular)
                                .tint(.white.opacity(0.1))
                        )
            }
        }
        .frame(maxWidth: size.width, maxHeight: size.height)
        .clipped()
        .cornerRadius(6)
        .onChange(of: media, { oldValue, newValue in
            loadManager.loadThumbnail(for: newValue)
        })
        .onAppear {
            loadManager.loadThumbnail(for: media)
        }
        .onDisappear {
            loadManager.cancelAndClear()
        }
    }
}



#Preview {
//    VideoTabView(isShowVideoPlayer: .constant(false), isShowSearch: .constant(false))
    ContentView()
}

struct FloatingButtonMenu: View {
    @State private var isExpanded: Bool = false
    
    let options: [FileImportType]
    var tapAction: (_ type: FileImportType) -> Void = { type in }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Rectangle()
                .fill(isExpanded ? Color("202020").opacity(0.001) : .clear)
                .onTapGesture {
                    if isExpanded {
                        withAnimation(.spring()) {
                            isExpanded = false
                        }
                    }
                }
            VStack(alignment: .trailing, spacing: 10) {
                if isExpanded {
                    ForEach(options, id: \.self) { type in
                        Button(action: {
                            print("\(type.icon) tapped!")
                            tapAction(type)
                            withAnimation(.spring()) {
                                isExpanded = false
                            }
                        }) {
                            Image(systemName: type.icon)
                                .font(.system(size: 15, weight: .light, design: .default))
                                .padding(15)
                                .background(type.color)
                                .foregroundStyle(.white)
                                .clipShape(Circle())
                                .shadow(radius: 5)
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                
                Button(action: {
                    withAnimation(.spring()) {
                        isExpanded.toggle()
                    }
                }) {
                    Capsule().fill(isExpanded ? Color.theme.gradient.opacity(0.25) : Color.theme.gradient.opacity(1))
                        .frame(width: 50, height: 50)
                        .shadow(radius: 5)
                        .overlay {
                            Image(systemName: isExpanded ? "xmark" : "plus")
                                .font(.system(size: 20, weight: .regular, design: .default))
                                .rotationEffect(.degrees(isExpanded ? 180 : 0))
                                .foregroundStyle(.white)
                        }
                }
            }
            .padding(.trailing, 20)
        }
    }
}


struct IPlayLogoView: View {
    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            VStack(spacing: 8) {
                Image("ic_splash")
                    .resizable()
                    .frame(width: 15, height: 15)
                Capsule()
                    .fill(.theme.gradient)
                    .frame(width: 7, height: 25)
                    .offset(y: -7)
            }
            Text("Play")
                .font(.system(size: 35, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
        }
    }
}

// Custom Shape for the Play Triangle
struct PlayTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
