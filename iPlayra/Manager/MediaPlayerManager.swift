//
//  MediaPlayerManager.swift
//  iPlayra
//
//  Created by Shiv on 21/10/26.
//

import SwiftUI
import Combine
import Foundation
import MediaPlayer
import VLCKit
import VLCMediaLibraryKit

// MARK: - Player Events
public enum MediaPlayerEvent {
    case timeChanged(VLCMediaPlayer?)
    case loudnessChanged(Double)
    case stateChanged(VLCMediaPlayerState)
    case currentMedia(VLCMedia, VLCMLMedia?)
    case stoppedPlayback(VLCMediaListPlayer)
    case finishedPlayback(VLCMediaListPlayer)
}

// MARK: - Media Event
enum PlayerType: String, CaseIterable {
    case video, audio
}

struct AudioTrackModel {
    var index: Int32
    var track: String
}

struct SubtitleTrack: Identifiable {
    let id = UUID()
    let name: String
    let index: Int32
    var isDisable: Bool { name == "Disable" }
}

public enum VisualizationType: String, CaseIterable {
    case img, line, wave, circle
}

// MARK: - MediaPlayerManager
final class MediaPlayerManager: NSObject, ObservableObject {
    static let shared: MediaPlayerManager = .init()
    
    private var mediaListPlayer: VLCMediaListPlayer?
    var mediaList: VLCMediaList = VLCMediaList()
    
    @AppStorage("isPlayerType") var isPlayerType: PlayerType = .audio
    @AppStorage("selectedVisualizerType") var selectedVisualizerType: VisualizationType = .img
    @AppStorage("isShuffle") var isShuffle: Bool = false
    @AppStorage("isOnEqualizer") var isOnEqualizer: Bool = false
    @AppStorage("repeatMode") var repeatMode: VLCRepeatMode = .doNotRepeat {
        didSet {
            mediaListPlayer?.repeatMode = repeatMode
        }
    }
    @AppStorage("decoderType") var decoderType: DecoderType = .hwDecoder {
        didSet {
            print(decoderType.rawValue)
            mediaListPlayer?.mediaPlayer.media?.addOptions(decoderType.codecOptions)
        }
    }
    @AppStorage("playerVolume") var volume: Double = 1.0 {
        didSet {
            applyVolume()
        }
    }
    
    var videoOutputView: PiPVideoView = PiPVideoView()
    @Published var isPiPReady = false
    @Published var isPiPActive = false
    
    // MARK: - Sleep Timer Properties
    private var sleepTimer: Timer?
    @Published var remainingTime: TimeInterval = 30
    @AppStorage("sleepTimerTargetDate") private var sleepTimerTargetDate: TimeInterval = 0

    @Published var isMute: Bool = false
    @Published var currentSubtitleIndex: Int32 = 0
    @Published var availableCastDevices: [VLCRendererItem] = []
    @Published private(set) var isCasting: Bool = false
    @Published private(set) var colors: (Color, Color, Color) = (Color("202020"), Color("202020"), Color("202020"))
    @Published var playbackRate: Float = 1.0 {
        didSet {
            mediaListPlayer?.mediaPlayer.rate = playbackRate
        }
    }
    @Published var currentDuration: VLCTime = VLCTime()
    @Published var totalDuration: VLCTime = VLCTime()
    @Published var position: Float = 0
    @Published var power: Double = 0
    @Published var powerLine: Double = 0
    @Published var state: VLCMediaPlayerState = .stopped
    @Published var hdrFilters: VLCAdjustFilter = .init(vlcMediaPlayer: .init())
    @Published private(set) var miliseconds: Int32 = 0
    
    @Published var eqBands: VLCAudioEqualizer = VLCAudioEqualizer()
    @Published var preset: VLCAudioEqualizer.Preset? = VLCAudioEqualizer.presets.first
    
    var currentAudioTrack: (Int32, Int) {
        return (0 ,self.mediaListPlayer?.mediaPlayer.currentAudioPlaybackDelay ?? 0)
    }
    
    // MARK: - Combine Subject for Events
    let event = PassthroughSubject<MediaPlayerEvent, Never>()
    
    @Published var currentVlcMedia: VLCMedia = VLCMedia() {
        didSet {
//            isMediaPlaying.delegate = self
        }
    }
    @Published var currentMLMedia: VLCMLMedia? {
        didSet {
            print(currentMLMedia?.album?.title ?? "")
        }
    }
    @Published var originalMedias: [VLCMLMedia] = []
    
    // Priview
    @Published var previewImage: UIImage? = nil
    private var imageCache = NSCache<NSString, UIImage>()
    private var lastRequestTime: Date = Date()
    
    private var artworkCache: [String: MPMediaItemArtwork] = [:]
    private var currentArtwork: MPMediaItemArtwork?
    
    private var castDiscoverers: [VLCRendererDiscoverer] = []
    private var activeCastItem: VLCRendererItem?
    
    // MARK: - Initializer
    private override init() {
        super.init()
        imageCache.countLimit = 100
        checkAndResumeTimer()
        configureAudioSession()
//        setupRemoteTransportControls()
    }
    
    // MARK: - Public Method
    func setupAndPlay(mlMedias: [VLCMLMedia], playIndex: Int, playbackType: PlayerType = .video) {
        Task { @MainActor in
            if mediaListPlayer == nil {
                mediaListPlayer = VLCMediaListPlayer()
            }
            isPlayerType = playbackType
            originalMedias = mlMedias
            let medias: [VLCMedia] = mlMedias.map({ VLCMedia(url: $0.mainFile()!.mrl!)! })
            medias.forEach { $0.delegate = self }
            
            mediaList = VLCMediaList(array: medias)
            let vlcLogger = VLCConsoleLogger()
            vlcLogger.level = .debug
            vlcLogger.formatter.contextFlags = .levelContextAll
            mediaListPlayer?.mediaPlayer.libraryInstance.loggers = [vlcLogger]
            
            mediaListPlayer?.delegate = self
            mediaListPlayer?.mediaPlayer.delegate = self
            mediaListPlayer?.mediaList = self.mediaList
            guard let playMedia = self.mediaList.media(at: UInt(playIndex)) else { return }
            hdrFilters = mediaListPlayer?.mediaPlayer.adjustFilter ?? VLCAdjustFilter.init(vlcMediaPlayer: .init())
            currentVlcMedia = playMedia
            currentMLMedia = mlMedias[playIndex]
            loadArtwork(for: playMedia)
            updateNowPlayingInfo()
            currentSubtitleIndex = self.mediaListPlayer?.mediaPlayer.currentTitleIndex ?? -1
            playbackRate = mediaListPlayer?.mediaPlayer.rate ?? 1.0
            totalDuration = currentVlcMedia.length
            mediaListPlayer?.repeatMode = repeatMode
            if playbackType == .video {
                attachDrawable()
            }
            mediaListPlayer?.play(playMedia)
            applyVolume()
            reapplyEqualizerIfNeeded()
            reapplyCastIfNeeded()
            event.send(.currentMedia(currentVlcMedia, currentMLMedia))
            updateNowPlayingInfo()
        }
    }
        
    // Is method ko apne MediaPlayerManager class mein replace karein
    @MainActor // Ye ensure karta hai ki UI updates hamesha main thread par hon
    func generatePreview(position: Double) {
        // 1. Throttling: Request rate control karein
        if Date().timeIntervalSince(lastRequestTime) < 0.1 { return }
        lastRequestTime = Date()

        // 2. Cache Check
        let cacheKey = NSString(string: "\(Int(position * 100))")
        if let cachedImage = imageCache.object(forKey: cacheKey) {
            self.previewImage = cachedImage
            return
        }

        // 3. Crash Protection: Check video output
        guard let player = mediaListPlayer?.mediaPlayer, player.hasVideoOut else { return }

        // 4. Background Task using Task.detached
        Task {
            // Player position update (Main thread par hi hona chahiye)
            player.position = position
            
            // Snapshot logic ko non-isolated task mein chalayenge taaki UI freeze na ho
            let snapshotImage = await captureFrame(player: player)
            
            // 5. Result update on MainActor
            if let image = snapshotImage {
                self.imageCache.setObject(image, forKey: cacheKey)
                self.previewImage = image
            }
        }
    }
    
    // Helper function to capture frame safely
    private func captureFrame(player: VLCMediaPlayer) async -> UIImage? {
        let tempPath = NSTemporaryDirectory() + "seek_preview.jpg"
        
        // Check again before snapshot
        guard player.hasVideoOut else { return nil }
        
        // Snapshot trigger
        player.saveVideoSnapshot(at: tempPath, withWidth: 240, andHeight: 135)
        
        // Thoda delay taaki VLC frame render kar sake (Async friendly sleep)
        try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
        
        return player.lastSnapshot
    }
    
    func setStereoMode(_ mode: VLCMediaPlayer.AudioStereoMode) {
        mediaListPlayer?.mediaPlayer.audioStereoMode = mode
    }
    
    func setAudioMixMode(_ mode: VLCMediaPlayer.AudioMixMode) {
        mediaListPlayer?.mediaPlayer.audioMixMode = mode
    }
    
    // MARK: - Casting Control (Chromecast / AirPlay via VLCRendererDiscoverer)
    /// Network par available cast devices (Chromecast/AirPlay) scan karna shuru karta hai.
    /// Cast picker sheet ke `.onAppear` se call karo.
    func startCastDiscovery() {
        availableCastDevices.removeAll()
        let services = VLCRendererDiscoverer.list() ?? []
        for service in services {
            // macOS par kabhi-kabhi name nil aata hai — guard zaroori hai, warna crash
            guard let discoverer = VLCRendererDiscoverer(name: service.name) else { continue }
            discoverer.delegate = self
            discoverer.start()
            castDiscoverers.append(discoverer)
        }
    }

    /// Scanning band karo — cast picker sheet ke `.onDisappear` se call karo.
    func stopCastDiscovery() {
        castDiscoverers.forEach { $0.stop() }
        castDiscoverers.removeAll()
    }

    /// Selected device par casting shuru karo
    func cast(to item: VLCRendererItem) {
        activeCastItem = item
        mediaListPlayer?.mediaPlayer.setRendererItem(item)
        isCasting = true
    }

    /// Wapas local playback (phone/Mac) par le aao
    func stopCasting() {
        activeCastItem = nil
        mediaListPlayer?.mediaPlayer.setRendererItem(nil)
        isCasting = false
    }

    /// Naya `VLCMediaListPlayer` instance banne par (setupPlay/setupPlayRadio ke andar)
    /// active cast selection ko usi par dobara apply karta hai — jaise
    private func reapplyCastIfNeeded() {
        guard isCasting, let item = activeCastItem else { return }
        mediaListPlayer?.mediaPlayer.setRendererItem(item)
    }
    
    // MARK: - New: Audio Session Configuration
    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .moviePlayback, options: [.allowAirPlay])
            try session.setActive(true)
            print("Audio session configured successfully for playback.")
        } catch {
            print("Failed to set audio session category: \(error.localizedDescription)")
        }
    }
    
    // MARK: - New: Remote Command Center Setup
    private func updateNowPlayingInfo() {
        var info: [String: Any] = [:]
        info[MPMediaItemPropertyTitle] = currentVlcMedia.metaData.title ?? "Unknown"
        info[MPMediaItemPropertyArtist] = currentVlcMedia.metaData.artist ?? "Unknown Artist"
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = Double(mediaListPlayer?.mediaPlayer.time.intValue ?? 0) / 1000.0
        info[MPMediaItemPropertyPlaybackDuration] = Double(totalDuration.intValue) / 1000.0
        info[MPNowPlayingInfoPropertyIsLiveStream] = false
        
        info[MPNowPlayingInfoPropertyPlaybackRate] = state == .playing ? Double(playbackRate) : 0.0
        if let artwork = currentArtwork {
            info[MPMediaItemPropertyArtwork] = artwork
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
    
    // MARK: - New: Now Playing Info Update
    
    private func loadArtwork(for media: VLCMedia) {
        loadArtwork(urlString: media.metaData.artworkURL?.absoluteString, cacheKey: media.url?.absoluteString)
    }
    
    private func loadArtwork(urlString: String?, cacheKey: String?) {
        guard let cacheKey, let urlString, let url = URL(string: urlString) else {
            currentArtwork = nil
            updateNowPlayingInfo()
            return
        }
        
        if let cached = artworkCache[cacheKey] {
            currentArtwork = cached
            updateNowPlayingInfo()
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
#if os(macOS)
            guard let self, let data, let image = NSImage(data: data) else { return }
            let one = Color(image.dominantColors()[0])
            let two = Color(image.dominantColors()[1])
            let three = Color(image.dominantColors()[2])
            DispatchQueue.main.async {
                self.colors = (one, two, three)
            }
#else
            guard let self, let data, let image = UIImage(data: data) else { return }
#endif
            
            let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
            
            DispatchQueue.main.async {
                self.artworkCache[cacheKey] = artwork
                // Ab tak wahi song/station current hai to hi apply karo
                if self.currentVlcMedia.url?.absoluteString == cacheKey {
                    self.currentArtwork = artwork
                    self.updateNowPlayingInfo()
                }
            }
        }.resume()
    }
    
    func getSubtitleTracks() async -> [SubtitleTrack] {
        await MainActor.run {
            var tracks: [SubtitleTrack] = []
//            if let subtitles = mediaListPlayer?.mediaPlayer.videoSubTitlesNames as? [String],
//               let indexes = mediaListPlayer?.mediaPlayer.videoSubTitlesIndexes as? [Int] {
//                guard subtitles.count == indexes.count else {
//                    print("Error: Subtitles and indexes count mismatch")
//                    return [SubtitleTrack(name: "Disable", index: -1)]
//                }
//                tracks.append(SubtitleTrack(name: "Disable", index: -1))
//                for (i, name) in subtitles.enumerated() {
//                    if i > 0 {
//                        let index = Int32(indexes[i])
//                        tracks.append(SubtitleTrack(name: name, index: index))
//                    }
//                }
//            } else {
//                tracks.append(SubtitleTrack(name: "Disable", index: -1))
//            }
            return tracks
        }
    }
    
    func setSubtitleTrack(_ index: Int32) {
        self.currentSubtitleIndex = index
//        self.mediaListPlayer?.mediaPlayer.currentVideoSubTitleIndex = index
        self.mediaListPlayer?.mediaPlayer.yaw = 180.0
        self.mediaListPlayer?.mediaPlayer.fov = 90.0
        self.mediaListPlayer?.mediaPlayer.pitch = 50.0
        self.mediaListPlayer?.mediaPlayer.roll = 100.0
        let isFlag = self.mediaListPlayer?.mediaPlayer.updateViewpoint(180.0, pitch: 50.0, roll: 100.0, fov: 90.0, absolute: true)
        
        print(isFlag)
    }
    
    func getAudioTracks() async -> [AudioTrackModel] {
        var audioTracks: [Int32: String] = [:]
//        if let trackIndexes = self.mediaListPlayer?.mediaPlayer.audioTrackIndexes as? [Int32],
//           let trackNames = self.mediaListPlayer?.mediaPlayer.audioTrackNames as? [String],
//           trackIndexes.count == trackNames.count {
//            for (index, trackIndex) in trackIndexes.enumerated() {
//                let name = trackNames[index]
//                // Extract language from brackets
//                if let start = name.firstIndex(of: "["),
//                   let end = name.firstIndex(of: "]"),
//                   start < end {
//                    let language = String(name[name.index(after: start)..<end])
//                    audioTracks[trackIndex] = language
//                } else {
//                    // fallback if name doesn't have brackets (like "Disable")
//                    audioTracks[trackIndex] = name
//                }
//            }
//        }
        return audioTracks.map({ AudioTrackModel(index: $0.key, track: $0.value) })
    }
    
    func audioTrackPlay(track: AudioTrackModel, delay: Int) {
//        mediaListPlayer?.mediaPlayer.currentAudioTrackIndex = track.index
        mediaListPlayer?.mediaPlayer.currentAudioPlaybackDelay = delay
    }
    
    func playFromPlaylist(index: Int) {
        guard let media = self.mediaList.media(at: UInt(index)) else { return }
        currentVlcMedia = media
        currentMLMedia = originalMedias.filter({ $0.mainFile()?.mrl == currentVlcMedia.url }).first
        event.send(.currentMedia(currentVlcMedia, currentMLMedia))
        mediaListPlayer?.play(currentVlcMedia)
    }
    
    func removeFromPlaylist(index: Int) {
        mediaList.removeMedia(at: UInt(index))
        originalMedias.remove(at: index)
    }
    
    func playPause() {
        if mediaListPlayer?.mediaPlayer.isPlaying ?? false {
            mediaListPlayer?.pause()
        } else {
            mediaListPlayer?.play()
        }
    }
    
    func isMuted() {
        mediaListPlayer?.mediaPlayer.audio?.isMuted.toggle()
        isMute.toggle()
    }
    
    func jumpBackward(sec: Double) {
        mediaListPlayer?.mediaPlayer.jumpBackward(sec)
    }
    
    func jumpForward(sec: Double) {
        mediaListPlayer?.mediaPlayer.jumpForward(sec)
    }
    
    func seek(to position: Double, isTracking: Bool) {
        mediaListPlayer?.mediaPlayer.position = position
    }
    
    func setVolume(_ value: Float, isTracking: Bool) {
        volume = Double(value)
    }
    
    private func applyVolume() {
        guard let audio = mediaListPlayer?.mediaPlayer.audio else { return }
        let clamped = max(0.0, min(volume, 1.0))
        audio.volume = Int32(clamped * 100)
    }
    
    func nextPlay() {
        if !isShuffle {
            guard let currentMedia = mediaListPlayer?.mediaPlayer.media else { return }
            let currentIndex = mediaList.index(of: currentMedia)
            
            switch repeatMode {
            case .repeatAllItems:
                let nextIndex = (Int(currentIndex) + 1) % mediaList.count
                guard let media = mediaList.media(at: UInt(nextIndex)) else { return }
                currentVlcMedia = media
            case .repeatCurrentItem:
                guard let media = mediaList.media(at: UInt(currentIndex)) else { return }
                currentVlcMedia = media
            case .doNotRepeat:
                let nextIndex = (Int(currentIndex) + 1) % mediaList.count
                guard let media = mediaList.media(at: UInt(nextIndex)) else { return }
                currentVlcMedia = media
            default:
                break
            }
        } else {
            if let randomMedia = mediaList.media(at: UInt.random(in: 0..<UInt(mediaList.count))) {
                currentVlcMedia = randomMedia
            }
        }
        if let current = originalMedias.first(where: { $0.mainFile()?.mrl == currentVlcMedia.url }) {
            currentMLMedia = current
            mediaListPlayer?.play(currentVlcMedia)
            event.send(.currentMedia(currentVlcMedia, current))
            updateNowPlayingInfo()
        }
    }
    
    func previousPlay() {
        if isShuffle {
            guard let currentMedia = mediaListPlayer?.mediaPlayer.media else { return }
            let currentIndex = mediaList.index(of: currentMedia)
            
            switch repeatMode {
            case .repeatAllItems:
                let previousIndex = (Int(currentIndex) - 1 + mediaList.count) % mediaList.count
                guard let media = mediaList.media(at: UInt(previousIndex)) else { return }
                currentVlcMedia = media
            case .repeatCurrentItem:
                guard let media = mediaList.media(at: UInt(currentIndex)) else { return }
                currentVlcMedia = media
            case .doNotRepeat:
                let previousIndex = (Int(currentIndex) - 1 + mediaList.count) % mediaList.count
                guard let media = mediaList.media(at: UInt(previousIndex)) else { return }
                currentVlcMedia = media
            default:
                break
            }
        } else {
            if let randomMedia = mediaList.media(at: UInt.random(in: 0..<UInt(mediaList.count))) {
                currentVlcMedia = randomMedia
            }
        }
        if let current = originalMedias.first(where: { $0.mainFile()?.mrl == currentVlcMedia.url }) {
            currentMLMedia = current
            mediaListPlayer?.play(currentVlcMedia)
            event.send(.currentMedia(currentVlcMedia, current))
            updateNowPlayingInfo()
        }
    }
    
    func attachDrawable() {
        videoOutputView.playbackController = self
        videoOutputView.onPiPReady = { [weak self] in
            DispatchQueue.main.async { self?.isPiPReady = true }
        }
        videoOutputView.onPiPStateChange = { [weak self] isStarted in
            DispatchQueue.main.async { self?.isPiPActive = isStarted }
        }
        mediaListPlayer?.mediaPlayer.drawable = videoOutputView
    }

    func startPiP() {
        videoOutputView.startPiP()
    }
    func stopPiP()  {
        videoOutputView.stopPiP()
    }
    
    // Video FIlter Effect Apply
    func applyVideoFilterEffect(filter: (Float, Float, Float, Float, Float, Bool)) {
        if filter.5 {
            mediaListPlayer?.mediaPlayer.adjustFilter.isEnabled = filter.5
            mediaListPlayer?.mediaPlayer.adjustFilter.brightness.value = filter.0
            mediaListPlayer?.mediaPlayer.adjustFilter.contrast.value = filter.1
            mediaListPlayer?.mediaPlayer.adjustFilter.saturation.value = filter.2
            mediaListPlayer?.mediaPlayer.adjustFilter.gamma.value = filter.3
            mediaListPlayer?.mediaPlayer.adjustFilter.hue.value = filter.4
        } else {
            mediaListPlayer?.mediaPlayer.adjustFilter.isEnabled = filter.5
            mediaListPlayer?.mediaPlayer.adjustFilter.brightness.isValueSetToDefault()
            mediaListPlayer?.mediaPlayer.adjustFilter.contrast.isValueSetToDefault()
            mediaListPlayer?.mediaPlayer.adjustFilter.saturation.isValueSetToDefault()
            mediaListPlayer?.mediaPlayer.adjustFilter.gamma.isValueSetToDefault()
            mediaListPlayer?.mediaPlayer.adjustFilter.hue.isValueSetToDefault()
        }
        guard let filter = mediaListPlayer?.mediaPlayer.adjustFilter else { return }
        hdrFilters = filter
    }
    
    func setAspectRatio(_ ratio: AspectRatio) {
        if ratio == .original {
            mediaListPlayer?.mediaPlayer.videoAspectRatio = nil
        } else if ratio == .fullScreen {
            let screenSize = UIScreen.main.bounds.size
            let width = Int(screenSize.width)
            let height = Int(screenSize.height)
            
            if let aspect = self.mediaListPlayer?.mediaPlayer.videoAspectRatio {
//                free(aspect)
            }
//            mediaListPlayer?.mediaPlayer.videoAspectRatio = strdup("\(width):\(height)")
        } else {
//            mediaListPlayer?.mediaPlayer.videoAspectRatio = strdup(ratio.rawValue)
        }
    }
    
    // MARK: - Equalizer Control
    /// Equalizer ko on/off karta hai. Toggle se call hoga.
    func setEqualizerEnabled(_ enabled: Bool) {
        isOnEqualizer = enabled
        if enabled {
            // Player par equalizer instance attach karo (ek hi baar)
            mediaListPlayer?.mediaPlayer.equalizer = eqBands
            applyStoredEqualizerValues()
        } else {
            mediaListPlayer?.mediaPlayer.equalizer = nil
        }
    }

    /// Currently attached equalizer par saved bands/preAmp values push karta hai
    private func applyStoredEqualizerValues() {
        guard let liveEq = mediaListPlayer?.mediaPlayer.equalizer else { return }
        liveEq.preAmplification = eqBands.preAmplification
        eqBands.bands.enumerated().forEach { index, band in
            liveEq.bands[index].amplification = band.amplification
        }
    }

    /// Naya media play hone ke baad call karo — agar equalizer ON hai to reattach + reapply
    private func reapplyEqualizerIfNeeded() {
        guard isOnEqualizer else { return }
        mediaListPlayer?.mediaPlayer.equalizer = eqBands
        applyStoredEqualizerValues()
    }

    /// Slider drag karte waqt REAL-TIME call hoga (isTracking check ki zaroorat nahi)
    func updatePreAmplification(_ value: Float) {
        eqBands.preAmplification = value
        guard isOnEqualizer, let liveEq = mediaListPlayer?.mediaPlayer.equalizer else { return }
        liveEq.preAmplification = value
    }

    /// Band slider drag karte waqt REAL-TIME call hoga
    func updateBand(index: Int, amplification: Float) {
        guard eqBands.bands.indices.contains(index) else { return }
        eqBands.bands[index].amplification = amplification
        guard isOnEqualizer, let liveEq = mediaListPlayer?.mediaPlayer.equalizer else { return }
        liveEq.bands[index].amplification = amplification
    }
    
    func applyEqualizerEffect(eq: VLCAudioEqualizer, preset: VLCAudioEqualizer.Preset?) {
        guard isOnEqualizer else {
            // OFF hone par equalizer hatao
            mediaListPlayer?.mediaPlayer.equalizer = nil
            return
        }
        
        // ✅ Pehle assign karo
        mediaListPlayer?.mediaPlayer.equalizer = eq
        
        // ✅ Assign ke BAAD directly player ke equalizer par set karo
        // eq copy par nahi — player ke actual equalizer par
        mediaListPlayer?.mediaPlayer.equalizer?.preAmplification = eq.preAmplification
        
        eq.bands.enumerated().forEach { index, band in
            mediaListPlayer?.mediaPlayer.equalizer?.bands[index].amplification = band.amplification
        }
    }

    /// Apply a VLC built-in preset to the saved EQ and the currently playing media.
    func selectEqualizerPreset(_ selectedPreset: VLCAudioEqualizer.Preset) {
        let selectedEQ = VLCAudioEqualizer(preset: selectedPreset)
        eqBands.preAmplification = selectedEQ.preAmplification
        selectedEQ.bands.enumerated().forEach { index, band in
            guard eqBands.bands.indices.contains(index) else { return }
            eqBands.bands[index].amplification = band.amplification
        }
        preset = selectedPreset
        if isOnEqualizer {
            applyEqualizerEffect(eq: eqBands, preset: selectedPreset)
        }
    }

    func stop() {
//        guard let media = self.mediaListPlayer?.mediaPlayer.media, let audioTrackIndex = self.mediaListPlayer?.mediaPlayer.currentAudioTrackIndex, let videoSubtitleIndex = self.mediaListPlayer?.mediaPlayer.currentVideoSubTitleIndex else { return }
//        // Yahan savePlaybackState call karo
//        DispatchQueue.main.async {
//            MediaLibraryService.shared.savePlaybackState(from: media, from: self.mediaListPlayer?.mediaPlayer.position ?? 0, currentAudioTrackIndex: audioTrackIndex, currentVideoSubTitleIndex: videoSubtitleIndex)
//        }
        mediaListPlayer?.stop()
    }
    
    // Sleep Timer Methods
    func startSleepTimer(minutes: Double) {
        let targetDate = Date().addingTimeInterval(minutes * 60)
        sleepTimerTargetDate = targetDate.timeIntervalSince1970
        setupTimer(targetDate: targetDate)
    }
    
    private func setupTimer(targetDate: Date) {
        sleepTimer?.invalidate()
        sleepTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let timeLeft = targetDate.timeIntervalSinceNow
            if timeLeft <= 0 {
                self.stopPlaybackByTimer()
            } else {
                DispatchQueue.main.async {
                    self.remainingTime = timeLeft
                }
            }
        }
    }
    
    private func stopPlaybackByTimer() {
        print("Sleep Timer Triggered: Stopping Player")
        self.stop()
        cancelSleepTimer()
    }
    
    func cancelSleepTimer() {
        sleepTimer?.invalidate()
        sleepTimer = nil
        remainingTime = 0
        sleepTimerTargetDate = 0
    }
    
    func checkAndResumeTimer() {
        let savedDate = Date(timeIntervalSince1970: sleepTimerTargetDate)
        if savedDate > Date() {
            setupTimer(targetDate: savedDate)
        } else {
            cancelSleepTimer()
        }
    }
}

// MARK: - VLCMediaListPlayerDelegate Bridge
extension MediaPlayerManager: VLCMediaListPlayerDelegate {
    func mediaListPlayer(_ player: VLCMediaListPlayer, nextMedia media: VLCMedia) {
        DispatchQueue.main.async {
            if let current = self.originalMedias.first(where: { $0.mainFile()?.mrl == media.url }) {
                self.currentVlcMedia = media
                self.currentMLMedia = current
                self.loadArtwork(for: media)
                self.event.send(.currentMedia(self.currentVlcMedia, current))
                self.updateNowPlayingInfo()
                self.videoOutputView.invalidatePlayback()
            }
        }
    }
    
    func mediaListPlayerStopped(_ player: VLCMediaListPlayer) {
        DispatchQueue.main.async {
            self.event.send(.stoppedPlayback(player))
        }
    }
    
    func mediaListPlayerFinishedPlayback(_ player: VLCMediaListPlayer) {
        DispatchQueue.main.async {
            self.event.send(.finishedPlayback(player))
        }
    }
}

// MARK: - VLCMediaPlayerDelegate Bridge
extension MediaPlayerManager: VLCMediaPlayerDelegate {
    func mediaPlayerTimeChanged(_ aNotification: Notification) {
        DispatchQueue.main.async {
            self.position = Float(self.mediaListPlayer?.mediaPlayer.position ?? 0)
            self.currentDuration = self.mediaListPlayer?.mediaPlayer.time ?? VLCTime()
            self.miliseconds = self.mediaListPlayer?.mediaPlayer.time.intValue ?? 0
            print("Length ms:", self.currentVlcMedia.length.intValue)
        }
    }
        
    func mediaPlayerStateChanged(_ newState: VLCMediaPlayerState) {
        DispatchQueue.main.async {
            self.state = newState
            if (newState == .opening || newState == .playing), self.totalDuration.intValue == 0 {
                self.totalDuration = self.currentVlcMedia.length
            }
            self.updateNowPlayingInfo()
            self.videoOutputView.invalidatePlayback()
            if newState == .playing || newState == .opening {
                print("Media now:", self.mediaListPlayer?.mediaPlayer.media?.url ?? "still nil")
            }
        }
    }
}

// MARK: - VLCRendererDiscovererDelegate Bridge
extension MediaPlayerManager: VLCRendererDiscovererDelegate {
    func rendererDiscovererItemAdded(_ rendererDiscoverer: VLCRendererDiscoverer, item: VLCRendererItem) {
        DispatchQueue.main.async {
            self.availableCastDevices.append(item)
        }
    }

    func rendererDiscovererItemDeleted(_ rendererDiscoverer: VLCRendererDiscoverer, item: VLCRendererItem) {
        DispatchQueue.main.async {
            self.availableCastDevices.removeAll { $0.name == item.name }
        }
    }
}


// MARK: - VLCMediaDelegate Bridge
extension MediaPlayerManager: VLCMediaDelegate {
    func mediaMetaDataDidChange(_ aMedia: VLCMedia) {
        DispatchQueue.main.async {
            self.totalDuration = aMedia.length
    //        let one = Color(aMedia.metaData.artwork?.dominantColorThree().0 ?? .clear)
    //        let two = Color(aMedia.metaData.artwork?.dominantColorThree().1 ?? .clear)
    //        let three = Color(aMedia.metaData.artwork?.dominantColorThree().2 ?? .clear)
    //        colors = (one, two, three)
            switch aMedia.parsedStatus {
            case .done:
                print("Media parsed status done")
            case .pending:
                print("Media parsed status pending")
            case .failed:
                print("Media parsed status Failed")
            case .skipped:
                print("Media parsed status skipped")
            case .timeout:
                print("Media parsed status time out")
            case .cancelled:
                print("Media parsed status cancelled")
            case .none:
                print("Media parsed status none")
            default: break;
            }
        }
    }
    
    func mediaDidFinishParsing(_ aMedia: VLCMedia) {
        print(aMedia.length)
    }
}


extension MediaPlayerManager: VLCPictureInPictureMediaControlling {
    func play()  {
        mediaListPlayer?.play()
    }
    func pause() {
        mediaListPlayer?.pause()
    }

    func seek(by offset: Int64, completion: (() -> Void)!) {
        let seconds = Double(abs(offset)) / 1000      // offset milliseconds me hai
        if offset >= 0 {
            jumpForward(sec: seconds)
        } else {
            jumpBackward(sec: seconds)
        }
        completion?()
    }

    func mediaLength() -> Int64 {
        Int64(currentVlcMedia.length.intValue)
    }
    func mediaTime() -> Int64   {
        Int64(mediaListPlayer?.mediaPlayer.time.intValue ?? 0)
    }
    func isMediaSeekable() -> Bool {
        mediaListPlayer?.mediaPlayer.isSeekable ?? false
    }
    func isMediaPlaying() -> Bool  {
        mediaListPlayer?.mediaPlayer.isPlaying ?? false
    }
}
