//
//  MediaInfoDetailView.swift
//  iPlay
//
//  Created by Shiv on 26/10/25.
//

import SwiftUI
import VLCMediaLibraryKit
import VLCKit

struct MediaInfoDetailView: View {
    @Environment(\.dismiss) var dismiss
    var media: VLCMLMedia
    @State private var currentOrientation: UIDeviceOrientation = UIDevice.current.orientation
//    @Binding var isPresented: Bool
    
    var body: some View {
        GeometryReader { geometry in
            let isVideo = media.type() == .video
            ZStack(alignment: isPortrait(geometry: geometry) ? .bottom : .leading) {
                Color.black.opacity(0.0001).ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.bouncy) {
                            dismiss()
                        }
                    }
                ZStack {
                    VStack(spacing: 0) {
                        ScrollView(.vertical, showsIndicators: false) {
                            LazyVStack {
                                ZStack {
                                    WebImageView(fileType: isVideo ? .video : .audio, url: media.thumbnail(of: .thumbnail))
                                        .clipShape(RoundedRectangle(cornerRadius: 5))
                                }
                                .frame(width: isVideo ? geometry.size.width * 0.35 : geometry.size.width * 0.25, height: geometry.size.width * 0.25)
                                let fileInfo = media.mainFile()?.mrl?.getFileInfo()
                                VStack {
                                    Text(media.title)
                                        .foregroundStyle(.white)
                                        .font(.system(size: 20, weight: .medium, design: .default))
                                        .lineLimit(2)
                                    Text("\(fileInfo?.fileType ?? "") - \(fileInfo?.fileSize ?? "0 MB")")
                                        .foregroundStyle(.gray)
                                        .font(.system(size: 15, weight: .medium, design: .default))
                                }
                                .padding(.horizontal, 30)
                                VStack {
                                    HStack {
                                        Text("kCreated".localized())
                                        Spacer()
                                        Text(fileInfo?.created ?? "")
                                    }
                                    .frame(height: 30)
                                    HStack {
                                        Text("kModified".localized())
                                        Spacer()
                                        Text(fileInfo?.modified ?? "")
                                    }
                                    .frame(height: 30)
                                    HStack {
                                        Text("kLastOpened".localized())
                                        Spacer()
                                        Text(fileInfo?.accessed ?? "")
                                    }
                                    .frame(height: 30)
                                    HStack {
                                        Text("kDuration".localized())
                                        Spacer()
                                        Text(media.duration().toTimeString())
                                    }
                                    .frame(height: 30)
                                }
                                .font(.system(size: 14, weight: .regular, design: .default))
                                .padding(.horizontal, 25)
                                .foregroundStyle(.gray)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .safeAreaInset(edge: .top) {
                        HStack(spacing: 10) {
                            Button {
                                withAnimation(.bouncy) {
                                    dismiss()
                                }
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 18, weight: .regular, design: .default))
                                    .foregroundStyle(.gray.gradient)
                                    .frame(width: 35, height: 35)
                                    .background(Capsule().fill(.ultraThinMaterial))
                            }
                            Text("Info")
                                .font(.system(size: 18, weight: .semibold, design: .default))
                                .foregroundStyle(.white)
                            Spacer()
                        }
                        .padding(10)
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .background(BlurView(style: .dark).cornerRadius(20).ignoresSafeArea())
                .animation(.linear, value: currentOrientation)
            }
        }
    }
    
    func isPortrait(geometry: GeometryProxy) -> Bool {
        return geometry.size.height > geometry.size.width
    }
}

//#Preview {
//    MediaInfoDetailView()
//}
