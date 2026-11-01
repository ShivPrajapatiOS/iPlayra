//
//  DownloadView.swift
//  iPlay
//
//  Created by Shiv on 14/12/25.
//

import AVKit
import SwiftUI
import Combine
import YouTubeKit
import VLCKit
import AVFoundation

struct DownloadView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var txtURL: String = "https://www.youtube.com/watch?v=xdGO-qmEJio"
    @State var isLoading: Bool = false
    @State var errorMessage: String? = nil
    
    @StateObject private var youtubeMediaPlayer: YoutubeMediaManager = .init()
    
    @State private var metadata: YouTubeMetadata?
    @State private var allStreams: [YouTubeKit.Stream] = []
    
    @State private var selectedVideoStream: YouTubeKit.Stream? = nil
    
    @State private var showPlayerControls: Bool = true
    
    @State private var isShowDownloadProgress: Bool = false
    @State private var precentage: Double = 0.0
    
    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()
            if !allStreams.isEmpty {
                GeometryReader { geoProxy in
                    VStack(spacing: 0) {
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(.gray.gradient.opacity(0.25), lineWidth: 1)
                            .frame(maxWidth: .infinity, maxHeight: geoProxy.size.height * 0.325)
                            .overlay(content: {
                                Group(content: {
                                    if selectedVideoStream?.fileExtension == .mp4 {
                                        YouTubeVideoView(mediaPlayer: youtubeMediaPlayer.mediaPlayer)
                                    } else {
                                        WebImageView(url: metadata?.thumbnail?.url)
                                    }
                                })
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .padding(5)
                                .overlay(content: {
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(.black.opacity(0.001))
                                })
                                .onTapGesture {
                                    withAnimation(.linear(duration: 0.35)) {
                                        showPlayerControls.toggle()
                                    }
                                }
                            })
                            .overlay {
                                HStack(spacing: 25) {
                                    Button {
                                        youtubeMediaPlayer.mediaPlayer.jumpBackward(10)
                                        
                                    } label: {
                                        Image(systemName: "gobackward.10")
                                            .font(.system(size: 16, weight: .light, design: .default))
                                            .frame(width: 35, height: 35)
                                            .background(Capsule().fill(.ultraThinMaterial).stroke(Color.gray.opacity(0.5), lineWidth: 1))
                                    }
                                    
                                    Button {
                                        if youtubeMediaPlayer.state == .playing {
                                            youtubeMediaPlayer.mediaPlayer.pause()
                                        } else {
                                            youtubeMediaPlayer.mediaPlayer.play()
                                        }
                                    } label: {
                                        Image(systemName: youtubeMediaPlayer.state == .playing ? "pause.fill" : "play.fill")
                                            .font(.system(size: 25, weight: .light, design: .default))
                                            .frame(width: 55, height: 55)
                                            .background(Capsule().fill(.ultraThinMaterial).stroke(Color.gray.opacity(0.5), lineWidth: 1))
                                    }
                                    
                                    Button {
                                        youtubeMediaPlayer.mediaPlayer.jumpForward(10)
                                    } label: {
                                        Image(systemName: "goforward.10")
                                            .font(.system(size: 16, weight: .light, design: .default))
                                            .frame(width: 35, height: 35)
                                            .background(Capsule().fill(.ultraThinMaterial).stroke(Color.gray.opacity(0.5), lineWidth: 1))
                                    }
                                }
                                .foregroundStyle(.theme.gradient)
                                .opacity(showPlayerControls ? 1 : 0)
                            }
                            .overlay(alignment: .bottom) {
                                HStack(spacing: 20) {
                                    Group {
                                        if let _ = selectedVideoStream?.audioCodec {
                                            Image(systemName: "speaker.fill")
                                                .font(.system(size: 20, weight: .light, design: .default))
                                                .foregroundStyle(Color.white.gradient)
                                        } else {
                                            Image(systemName: "speaker.slash.fill")
                                                .font(.system(size: 20, weight: .light, design: .default))
                                                .foregroundStyle(Color.gray.gradient.opacity(0.75))
                                        }
                                    }
                                    .frame(width: 40, height: 40)
                                    HStack(spacing: 16) {
                                        Text(youtubeMediaPlayer.currentTime.description)
//                                        HorizontalSlider(progress: $youtubeMediaPlayer.progress, minValue: 0, maxValue: 1) { (progress, isTracking) in
//                                            youtubeMediaPlayer.mediaPlayer.position = Double(progress)
//                                        }
                                        Text(youtubeMediaPlayer.totalTime.description)
                                    }
                                    .frame(height: 30)
                                    .font(.system(size: 10, weight: .regular, design: .default))
                                    .foregroundStyle(.white)
                                    .opacity(showPlayerControls ? 1 : 0)
                                    Button {
                                        if let download = selectedVideoStream, let metadata = metadata {
                                            Task {
                                                do {
                                                    isShowDownloadProgress = true
                                                    GlobalLoader.shared.show()
                                                    let savePath = try await VideoDownloader.downloadAndSaveVideo(from: download.url, fileName: "\(metadata.title)_\(download.videoResolution ?? 0).\(download.fileExtension.rawValue)") { progress in
                                                        print("Progress:- ",progress)
                                                        precentage = progress
                                                    }
                                                    GlobalLoader.shared.hide()
                                                    print("Video successfully saved at: \(savePath)")
                                                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                                                    isShowDownloadProgress = false
                                                } catch {
                                                    GlobalLoader.shared.hide()
                                                    isShowDownloadProgress = false
                                                    print("Download failed: \(error.localizedDescription)")
                                                }
                                            }
                                        }
                                    } label: {
                                        Image(systemName: "arrow.down")
                                            .font(.system(size: 20, weight: .regular, design: .default))
                                            .foregroundStyle(.white.gradient)
                                            .frame(width: 40, height: 40)
                                            .background(Capsule().fill(.theme.gradient))
                                    }
                                }
                                .padding(16)
                            }
                            .padding(10)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                        Text(metadata?.title ?? "")
                            .font(.system(size: 20, weight: .medium, design: .default))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .animation(.default, value: isLoading)
                            .padding(.horizontal, 20)
                        ScrollView(.vertical, showsIndicators: false) {
                            LazyVStack {
                                ForEach(allStreams, id: \.url) { stream in
                                    HStack {
                                        Button {
                                            withAnimation(.linear) {
                                                self.selectedVideoStream = stream
                                                guard let media = VLCMedia(url: stream.url) else { return }
                                                youtubeMediaPlayer.playMedia(media: media)
                                            }
                                        } label: {
                                            Image(systemName: selectedVideoStream?.url == stream.url ? "checkmark.square.fill" : "square")
                                                .font(.system(size: 25, weight: .light, design: .default))
                                                .foregroundStyle(.theme)
                                        }
                                        
                                        Text(stream.fileExtension.rawValue)
                                            .font(.system(size: 14, weight: .regular, design: .default))
                                            .foregroundStyle(.white)
                                        Spacer(minLength: 0)
                                        Text("\(stream.videoResolution ?? 0)p")
                                            .font(.system(size: 14, weight: .regular, design: .default))
                                            .foregroundStyle(.white)
                                            .padding(.vertical, 2.5)
                                            .padding(.horizontal, 10)
                                            .background {
                                                Capsule().fill(.theme.gradient)
                                            }
                                    }
                                    .frame(maxWidth: .infinity, maxHeight: 40, alignment: .leading)
                                }
                            }
                            .padding(30)
                            .padding(.horizontal, 30)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationBarBackButtonHidden()
        .safeAreaInset(edge: .top) {
            HStack(spacing: 16) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .regular, design: .default))
                        .foregroundStyle(.white.gradient)
                        .frame(width: 35, height: 35)
                        .background(Capsule().fill(.ultraThinMaterial))
                }
                Capsule().fill(.ultraThinMaterial)
                    .frame(height: 40)
                    .overlay {
                        HStack {
                            TextField("YouTube or URLs", text: $txtURL)
                                .font(.system(size: 16, weight: .regular, design: .default))
                                .keyboardType(.URL)
                                .keyboardShortcut(.defaultAction)
                                .tint(.theme)
                                .padding(.leading, 10)
                        }
                        .padding(.horizontal, 5)
                    }
                    .overlay {
                        Capsule().fill(.clear)
                            .stroke(.gray.opacity(0.25), lineWidth: 1)
                    }
                
                Button {
                    Task {
                        isLoading = true
                        GlobalLoader.shared.show()
                        errorMessage = nil
                        guard let url = URL(string: txtURL) else { return }
                        do {
                            let video = YouTube(url: url)
                            allStreams = try await video.streams
                            metadata = try await video.metadata
                            isLoading = false
                            errorMessage = nil
                            guard let streamURL = allStreams.first?.url else { return }
                            self.selectedVideoStream = allStreams.first
                            guard let media = VLCMedia(url: streamURL) else { return }
                            youtubeMediaPlayer.playMedia(media: media)
                            GlobalLoader.shared.hide()
                        } catch {
                            isLoading = false
                            GlobalLoader.shared.hide()
                            errorMessage = error.localizedDescription
                        }
                    }
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 20, weight: .regular, design: .default))
                        .foregroundStyle(txtURL.isEmpty ? Color.gray.opacity(0.5).gradient : Color.theme.gradient)
                        .frame(width: 35, height: 35)
                        .background(Capsule().fill(.ultraThinMaterial))
                }
                .disabled(txtURL.isEmpty)
            }
            .frame(maxWidth: .infinity, maxHeight: 50)
            .padding(.horizontal, 16)
        }
    }
}

#Preview {
    DownloadView()
}


// MARK: - VideoView
struct YouTubeVideoView: UIViewControllerRepresentable {
    var mediaPlayer: VLCMediaPlayer

    // UIViewController Create
    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        let videoView = UIView()
        videoView.backgroundColor = .black
        videoView.translatesAutoresizingMaskIntoConstraints = false
        videoView.tag = 999  // 🔖 Tag to identify view later

        controller.view.addSubview(videoView)

        NSLayoutConstraint.activate([
            videoView.topAnchor.constraint(equalTo: controller.view.topAnchor),
            videoView.bottomAnchor.constraint(equalTo: controller.view.bottomAnchor),
            videoView.leadingAnchor.constraint(equalTo: controller.view.leadingAnchor),
            videoView.trailingAnchor.constraint(equalTo: controller.view.trailingAnchor)
        ])

//        mediaPlayer.setDrawableView(view: videoView)
        mediaPlayer.drawable = videoView
        return controller
    }
    // UIViewController Update
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
//        if let videoView = uiViewController.view.viewWithTag(999) {
//            mediaPlayer.setDrawableView(view: videoView)
//        }
    }
}


class YoutubeMediaManager: NSObject, ObservableObject {
    let mediaPlayer: VLCMediaPlayer
    
    @Published var position: Double = .zero
    @Published private(set) var currentTime: VLCTime = VLCTime()
    @Published private(set) var totalTime: VLCTime = VLCTime()
    @Published var state: VLCMediaPlayerState = .stopped
    @Published var title: String = ""
    
    override init() {
        mediaPlayer = VLCMediaPlayer()
    }
    
    func playMedia(media: VLCMedia) {
        mediaPlayer.media = media
        mediaPlayer.delegate = self
        mediaPlayer.play()
    }
    
    func cleanup() {
        if mediaPlayer.isPlaying {
            mediaPlayer.stop()
        }
        
        mediaPlayer.delegate = nil
        mediaPlayer.media = nil
        
        position = 0
        currentTime = VLCTime()
        totalTime = VLCTime()
        state = .stopped
    }
    
    deinit {
        cleanup()
    }
}

extension YoutubeMediaManager: VLCMediaPlayerDelegate {
    func mediaPlayerTimeChanged(_ aNotification: Notification) {
        position = mediaPlayer.position
        currentTime = mediaPlayer.time
    }
    
//    func mediaPlayerStateChanged(_ aNotification: Notification) {
//        switch mediaPlayer.state {
//        case .playing:
//            state = .playing
//        case .paused:
//            state = .paused
//        case .ended:
//            state = .ended
//        case .stopped:
//            state = .stopped
//        case .esAdded:
//            totalTime = mediaPlayer.media?.length ?? VLCTime()
//            title = mediaPlayer.media?.metaData.title ?? ""
//        default: break;
//        }
//    }
}

extension Optional where Wrapped == Double {
    /// Bitrate ko "kbps" format mein convert karta hai
    func toKbpsString() -> String {
        // 1. Check karein ki value nil toh nahi hai
        guard let bps = self else { return "Unknown" }
        
        // 2. bps ko 1000 se divide karke kbps nikalein
        let kbps = Int((bps / 1000).rounded())
        
        // 3. Aapki specific categories ke liye mapping (optional)
        // Agar 48-56 ke beech hai toh "56 kbps" dikhayega
        if kbps > 40 && kbps < 60 {
            return "56 kbps"
        } else if kbps > 120 && kbps < 140 {
            return "128 kbps"
        } else if kbps > 240 && kbps < 270 {
            return "256 kbps"
        }
        
        // Default: Jo actual value hai wahi dikhaye
        return "\(kbps) kbps"
    }
}

enum DownloadError: Error {
    case invalidResponse
    case fileSaveFailed
    case networkError(Error)
}

//class VideoDownloader {
//    static func downloadAndSaveVideo(from url: URL, fileName: String) async throws -> URL {
//        
//        let (tempLocalURL, response) = try await URLSession.shared.download(from: url)
//        
//        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
//            throw DownloadError.invalidResponse
//        }
//        
//        let fileManager = FileManager.default
//        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
//        let destinationURL = documentsPath.appendingPathComponent(fileName)
//        
//        if fileManager.fileExists(atPath: destinationURL.path) {
//            try? fileManager.removeItem(at: destinationURL)
//        }
//        
//        try fileManager.moveItem(at: tempLocalURL, to: destinationURL)
//        
//        return destinationURL
//    }
//}


class VideoDownloader {
    static func downloadAndSaveVideo(from url: URL, fileName: String, progressHandler: @escaping (Double) -> Void) async throws -> URL {
        
        let (asyncBytes, response) = try await URLSession.shared.bytes(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw DownloadError.invalidResponse
        }
        
        let totalBytes = httpResponse.expectedContentLength
        var downloadedBytes: Int64 = 0
        var data = Data()
        
        // सुरक्षित तरीके से data size reserve karein
        if totalBytes > 0 {
            data.reserveCapacity(Int(totalBytes))
        }

        // Chunks mein download aur progress update
        for try await byte in asyncBytes {
            data.append(byte)
            downloadedBytes += 1
            
            // Har 100kb ya kuch intervals par progress update karein (Performance ke liye)
            if downloadedBytes % 102400 == 0 || downloadedBytes == totalBytes {
                let progress = Double(downloadedBytes) / Double(totalBytes)
                // Main actor par UI update bhejein
                await MainActor.run {
                    progressHandler(progress)
                }
            }
        }

        // File Save Logic
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationURL = documentsPath.appendingPathComponent(fileName)

        if fileManager.fileExists(atPath: destinationURL.path) {
            try? fileManager.removeItem(at: destinationURL)
        }

        try data.write(to: destinationURL)
        return destinationURL
    }
}


class LoFiMixer {
    func createLoFiTrack(mainSong: URL, beatLoop: URL, ambientNoise: URL, volumes: [Float]) async throws -> AVMutableComposition {
        let composition = AVMutableComposition()
        
        // 1. Tracks Create Karein
        let mainTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        let beatTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        let ambientTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        // 2. Audio Assets Load Karein
        let mainAsset = AVAsset(url: mainSong)
        let beatAsset = AVAsset(url: beatLoop)
        let ambientAsset = AVAsset(url: ambientNoise)
        
        let duration = try await mainAsset.load(.duration)
        let timeRange = CMTimeRange(start: .zero, duration: duration)
        
        // 3. Audio Insert Karein (Beat aur Ambient ko loop karna padega)
        try mainTrack?.insertTimeRange(timeRange, of: mainAsset.tracks(withMediaType: .audio)[0], at: .zero)
        
        // Beat aur Ambient ko gaane ki lambai tak repeat karein
        try loopTrack(asset: beatAsset, targetTrack: beatTrack, targetDuration: duration)
        try loopTrack(asset: ambientAsset, targetTrack: ambientTrack, targetDuration: duration)
        
        return composition
    }
    
    private func loopTrack(asset: AVAsset, targetTrack: AVMutableCompositionTrack?, targetDuration: CMTime) throws {
        let assetDuration = try asset.duration // Simplified for example
        var currentTime = CMTime.zero
        
        while currentTime < targetDuration {
            let remaining = targetDuration - currentTime
            let durationToInsert = min(assetDuration, remaining)
            try targetTrack?.insertTimeRange(CMTimeRange(start: .zero, duration: durationToInsert), of: asset.tracks(withMediaType: .audio)[0], at: currentTime)
            currentTime = currentTime + durationToInsert
        }
    }
}
