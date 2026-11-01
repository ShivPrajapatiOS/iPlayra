//
//  VideoItemView.swift
//  iPlayer
//
//  Created by Shiv on 02/01/26.
//

import SwiftUI
import VLCMediaLibraryKit
import VLCKit

enum VideoMenuType: String, CaseIterable {
    case share, info, delete
}
struct VideoItemView: View {
    var isPlayback: Bool = false
    let video: VLCMLMedia
    @State private var currentMedia: VLCMedia = .init()
    
    var menuAction: ((VideoMenuType, VLCMLMedia) -> Void)? = nil
    var removeAction: ((VLCMLMedia) -> Void)? = nil
    
    var body: some View {
        GeometryReader { geoProxy in
            ZStack {
                HStack {
                    RoundedRectangle(cornerRadius: 6)
                    .fill(.ultraThinMaterial)
                    .stroke(currentMedia.url == video.mainFile()?.mrl ? .theme : .gray.opacity(0.5), lineWidth: currentMedia.url == video.mainFile()?.mrl ? 2.5 : 1)
                    .frame(width: geoProxy.size.width * (isPlayback ? 0.3 : 0.4), height: geoProxy.size.height)
                    .overlay {
                        WebImageView(fileType: .video, url: video.thumbnail(of: .thumbnail))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .overlay(alignment: .trailing) {
                        VStack(alignment: .trailing) {
                            Text("NEW")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.theme.gradient)
                                .padding(.init(top: 2, leading: 6, bottom: 2, trailing: 6))
                                .background(RoundedRectangle(cornerRadius: 3).fill(.ultraThinMaterial))
                                .opacity(video.isNew ? 1 : 0)
                            Spacer(minLength: 0)
                            HStack(spacing: 3) {
                                Image(systemName: "play.fill")
                                Text(video.duration().toTimeString())
                            }
                            .font(.system(size: 10, weight: .regular))
                            .padding(.init(top: 2, leading: 6, bottom: 2, trailing: 6))
                            .background(RoundedRectangle(cornerRadius: 3).fill(.ultraThinMaterial))
                        }
                        .padding(4)
                    }
                    Group {
                        if !isPlayback {
                            VStack(alignment: .leading) {
                                Text(video.title)
                                    .font(.system(size: 16, weight: .regular))
                                    .lineLimit(2)
                                    .frame(maxHeight: .infinity)
                                Spacer(minLength: 10)
                                HStack {
                                    Group {
                                        Text(video.mainFile()?.mrl?.getFileInfo()?.fileSize ?? "0 MB")
                                            .foregroundStyle(.gray.gradient)
                                        Rectangle().fill(.theme).frame(width: 1, height: 10)
                                        Text(video.insertionDate().toStringShortMonth)
                                            .foregroundStyle(.gray.gradient)
                                    }
                                    .font(.system(size: 12, weight: .semibold))
                                    Spacer(minLength: 0)
                                    Menu {
                                        Button {
                                            menuAction?(.share, video)
                                        } label: {
                                            Label("kShare".localized(), systemImage: "square.and.arrow.up")
                                        }
                                        Button {
                                            menuAction?(.info, video)
                                        } label: {
                                            Label("kInfo".localized(), systemImage: "info.circle")
                                        }
                                        Button(role: .destructive) {
                                            menuAction?(.delete, video)
                                        } label: {
                                            Label("kDelete".localized(), systemImage: "trash")
                                        }
                                    } label: {
                                        Image(systemName: "ellipsis")
                                            .foregroundStyle(.theme.gradient)
                                            .font(.system(size: 18, weight: .semibold))
                                            .frame(width: 35, height: 20)
                                            .background(Capsule().fill(.ultraThinMaterial))
                                    }
                                }
                            }
                            .padding(.vertical, 5)
                        } else {
                            HStack {
                                Text(video.title)
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundStyle(currentMedia.url == video.mainFile()?.mrl ? Color.theme.gradient : Color.white.gradient)
                                    .lineLimit(2)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                if currentMedia.url != video.mainFile()?.mrl {
                                    Button {
                                        removeAction?(video)
                                    } label: {
                                        Image(systemName: "xmark")
                                            .font(.system(size: 15, weight: .light))
                                            .foregroundStyle(.gray.gradient)
                                            .frame(width: 30, height: 30)
                                            .background(Capsule().fill(.ultraThinMaterial))
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .onAppear(perform: {
                if isPlayback {
                    currentMedia = MediaPlayerManager.shared.currentVlcMedia
                }
            })
            .onReceive(MediaPlayerManager.shared.event) { obje in
                if isPlayback {
                    switch obje {
                    case .currentMedia(let media, _):
                        currentMedia = media
                    default: break;
                    }
                }
            }
        }
        .frame(maxHeight: .infinity)
    }
}

struct VideoItemGridView: View {
    let video: VLCMLMedia
    
    var body: some View {
        GeometryReader { geoProxy in
            VStack {
                RoundedRectangle(cornerRadius: 6)
                .fill(.ultraThinMaterial)
                .stroke(.gray.opacity(0.5), lineWidth: 1)
                .frame(width: geoProxy.size.width, height: geoProxy.size.height - 35)
                .overlay {
                    WebImageView(fileType: .video, url: video.thumbnail(of: .thumbnail))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .overlay(alignment: .trailing) {
                    VStack(alignment: .trailing) {
                        Text("NEW")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.theme.gradient)
                            .padding(.init(top: 2, leading: 6, bottom: 2, trailing: 6))
                            .background(RoundedRectangle(cornerRadius: 3).fill(.ultraThinMaterial))
                            .opacity(video.isNew ? 1 : 0)
                        Spacer(minLength: 0)
                        HStack(spacing: 3) {
                            Image(systemName: "play.fill")
                            Text(video.duration().toTimeString())
                        }
                        .font(.system(size: 10, weight: .regular))
                        .padding(.init(top: 2, leading: 6, bottom: 2, trailing: 6))
                        .background(RoundedRectangle(cornerRadius: 3).fill(.ultraThinMaterial))
                    }
                    .padding(4)
                }
                Text(video.title)
                    .font(.system(size: 16, weight: .regular))
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            }
        }
    }
}

#Preview {
//    VideoItemView(video: .constant(VLCMLMedia))
//    VideoGridItemView(video: <#VLCMLMedia#>)
}
