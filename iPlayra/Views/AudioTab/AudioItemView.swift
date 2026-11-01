//
//  AudioItemView.swift
//  iPlay
//
//  Created by Shiv on 04/01/26.
//

import SwiftUI
import VLCKit
import VLCMediaLibraryKit
import SDWebImageSwiftUI
import Combine

enum MenuAudioActionType: String, CaseIterable {
    case share, info, favorite, delete
}

struct AudioItemView: View {
    var isFavorite: Bool = false
    let media: VLCMLMedia
    @State private var currentMedia: VLCMedia = .init()
    
    var menuAction: ((MenuAudioActionType, VLCMLMedia) -> Void)? = nil
    
    var body: some View {
        ZStack {
            SwipeView {
                
                HStack {
                    
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.ultraThinMaterial)
                        .stroke(.gray.opacity(0.5), lineWidth: 1)
                        .overlay {
                            ZStack {
                                WebImageView(url: media.thumbnail())
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                if currentMedia.url == media.mainFile()?.mrl {
                                    LineVisualizerView()
                                }
                            }
                        }
                        .frame(width: 60)
                    VStack(alignment: .leading) {
                        Text(media.title)
                            .font(.system(size: 16, weight: .regular))
                            .foregroundStyle(currentMedia.url == media.mainFile()?.mrl ? Color.theme.gradient : Color.white.gradient)
                            .lineLimit(2)
                        Text(media.artist?.name ?? "Unknown Artist")
                            .font(.caption)
                            .foregroundStyle(currentMedia.url == media.mainFile()?.mrl ? Color.theme.gradient : Color.gray.gradient)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 0)
                    if isFavorite {
                        Button {
                            if media.isFavorite() {
                                media.setFavorite(false)
                            } else {
                                media.setFavorite(true)
                            }
                            MediaLibraryService.shared.objectWillChange.send()
                        } label: {
                            Image(systemName: media.isFavorite() ? "heart.fill" : "heart")
                                .font(.system(size: 25, weight: .light, design: .default))
                                .foregroundStyle(media.isFavorite() ? Color.pink.gradient : Color.white.gradient)
                                .frame(width: 35, height: 20)
                                .symbolEffect(.bounce, value: media.isFavorite())
                        }
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 10).fill(.ultraThinMaterial.opacity(0.05)))
            } leadingActions: { context in
                if !isFavorite {
                    SwipeAction {
                        menuAction?(.info, media)
                    } label: { _ in
                        Image(systemName: "info.circle")
                            .font(.system(size: 20, weight: .light, design: .default))
                            .foregroundStyle(Color.gray.gradient)
                    } background: { _ in
                        Color("#202020")
                    }
                    SwipeAction {
                        menuAction?(.share, media)
                    } label: { _ in
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 20, weight: .light, design: .default))
                            .foregroundStyle(Color("#FFFFFF"))
                    } background: { _ in
                        Color("#202020")
                    }
                    SwipeAction {
                        if media.isFavorite() {
                            media.setFavorite(false)
                        } else {
                            media.setFavorite(true)
                        }
                        MediaLibraryService.shared.objectWillChange.send()
                    } label: { _ in
                        Image(systemName: media.isFavorite() ? "heart.fill" : "heart")
                            .font(.system(size: 25, weight: .light, design: .default))
                            .foregroundStyle(media.isFavorite() ? Color.pink.gradient : Color.white.gradient)
                    } background: { _ in
                        Color("#202020")
                    }
                }
            } trailingActions: { context in
                if !isFavorite {
                    SwipeAction {
                        menuAction?(.delete, media)
                    } label: { _ in
                        Image(systemName: "trash")
                            .font(.system(size: 20, weight: .light, design: .default))
                            .foregroundStyle(Color.red.gradient)
                    } background: { _ in
                        Color("#202020")
                    }
                }
            }
            .swipeMinimumDistance(25)
        }
        .onAppear(perform: {
            currentMedia = MediaPlayerManager.shared.currentVlcMedia
        })
        .onReceive(MediaPlayerManager.shared.event) { obje in
            switch obje {
            case .currentMedia(let media, _):
                currentMedia = media
            default: break;
            }
        }
    }
}

struct WebImageView: View {
    var fileType: PlayerType = .audio
    var iconSize: CGFloat = 35
    let url: URL?

    var body: some View {
        WebImage(url: url) { image in
            image
                .resizable()
        } placeholder: {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.gray.opacity(0.25))
                .overlay {
                    Image(systemName: fileType == .audio ? "music.note" : "video")
                        .font(.system(size: iconSize, weight: .light))
                        .scaledToFill()
                        .foregroundStyle(Color("202020"))
                }
        }
        .onSuccess { image, data, cacheType in

        }
        .indicator(.activity(style: .linear))
        .transition(.opacity.animation(.easeInOut(duration: 0.5)))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

//#Preview {
//    AudioItemView(media: Binding<VLCMLMedia>)
//}
