//
//  MediaLibraryService.swift
//  iPlayra
//
//  Created by Shiv on 21/10/26.
//

import SwiftUI
import Combine
import VLCMediaLibraryKit

// Events publisher container
public enum MediaLibraryEvent {
    case didAddMedia([VLCMLMedia])
    case didDeleteMediaWith(ids: [NSNumber])
    case didModifyMedia(ids: [NSNumber])
}

public enum PlaylistMediaLibraryEvent {
    case didAddPlaylist([VLCMLPlaylist])
    case didDeletePlaylistWithIds(ids: [NSNumber], [VLCMLPlaylist])
    case didModifyPlaylist(ids: [NSNumber], [VLCMLPlaylist])
}

public enum ArtistMediaLibraryEvent {
    case didAddArtists([VLCMLArtist])
    case didModifyArtistsWith(ids: [NSNumber])
    case didDeleteArtistsWith(ids: [NSNumber])
}

public enum AlbumMediaLibraryEvent {
    case didAddAlbums([VLCMLAlbum])
    case didModifyAlbumsWith(ids: [NSNumber])
    case didDeleteAlbumsWith(ids: [NSNumber])
}

public enum DiscoveryMediaLibraryEvent {
    case didStartDiscovery
    case didEndDiscovery(library: VLCMediaLibrary)
    case didStartRescan
    case didProgressDiscovery(String)
    case didFailDiscovery(String)
}

@MainActor
class MediaLibraryService: NSObject, ObservableObject {
    // MARK: - Singleton Instance
    static let shared = MediaLibraryService()
    
    // These properties
    @Published private(set) var allMedias: [VLCMLMedia] = []
    @Published private(set) var audioMedias: [VLCMLMedia] = []
    @Published private(set) var allAudioAlbums: [VLCMLAlbum] = []
    @Published private(set) var allAudioArtists: [VLCMLArtist] = []
    @Published private(set) var videoMedias: [VLCMLMedia] = []
    @Published private(set) var histories: [VLCMLMedia] = []
    @Published private(set) var playlists: [VLCMLPlaylist] = []
    @Published private(set) var genres: [VLCMLGenre] = []
    @Published private(set) var isRescanning: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Combine Subject for Events
    
    // Use this subject to get fine-grained events in real-time
    let mediaEvent = PassthroughSubject<MediaLibraryEvent, Never>()
    let playlistEvent = PassthroughSubject<PlaylistMediaLibraryEvent, Never>()
    let artistEvent = PassthroughSubject<ArtistMediaLibraryEvent, Never>()
    let albumEvent = PassthroughSubject<AlbumMediaLibraryEvent, Never>()
    let discoveryEvent = PassthroughSubject<DiscoveryMediaLibraryEvent, Never>()
    
    // MARK: - Private Properties
    private let medialib = VLCMediaLibrary()
    private var cancellables = Set<AnyCancellable>()
    private let databaseName: String = "iPlay_DB"
    private let vlcFolderName: String = "iPlay_Media"
    private let vlcFolderCache: String = "iPlay_Cache"
    private var thumbnailRequestsInFlight = Set<Int64>()
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
        setup()
        medialib.delegate = self
    }
    
    
    // MARK: - Setup
    func setup() {
        setupMediaLibrary(allowRetry: true, busyRetries: 3)
    }
    
    private func setupMediaLibrary(allowRetry: Bool, busyRetries: Int) {
        guard let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first, let libraryPath = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first, let cachesPath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first else {
            errorMessage = "Directories not found"
            return
        }

        let mediaFolderPath = (documentsPath as NSString).appendingPathComponent(vlcFolderName)
        let cacheFolderPath = (cachesPath as NSString).appendingPathComponent(vlcFolderCache)
        let dbFolderPath = (libraryPath as NSString).appendingPathComponent(databaseName)

        do {
            try FileManager.default.createDirectory(atPath: mediaFolderPath, withIntermediateDirectories: true)
            try FileManager.default.createDirectory(atPath: dbFolderPath, withIntermediateDirectories: true)
            try FileManager.default.createDirectory(atPath: cacheFolderPath, withIntermediateDirectories: true)
        } catch {
            print("MediaLibraryService: Error creating directories: \(error.localizedDescription)")
            errorMessage = "Storage folder nahi ban paya"
            return
        }

        let dbFullPath = (dbFolderPath as NSString).appendingPathComponent(databaseName)

        let status = medialib.setupMediaLibrary(databasePath: dbFullPath, medialibraryPath: mediaFolderPath, cachePath: cacheFolderPath)

        switch status {
        case .success, .dbReset:
            let url = URL(fileURLWithPath: mediaFolderPath).absoluteString
            medialib.discover(onEntryPoint: url)
            Task { await self.reload() }

        case .alreadyInitialized:
            Task { await self.reload() }

        case .dbBusy:
            guard busyRetries > 0 else { errorMessage = "Database busy hai"; return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.setupMediaLibrary(allowRetry: allowRetry, busyRetries: busyRetries - 1)
            }

        case .dbCorrupted, .dbSchemaMismatch, .dbMigrationFailed, .dbForeignKeyViolation:
            guard allowRetry else { errorMessage = "Database repair nahi ho paya"; return }
            try? FileManager.default.removeItem(atPath: dbFolderPath)   // purana DB hatao
            setupMediaLibrary(allowRetry: false, busyRetries: busyRetries)

        case .failed:
            print("MediaLibraryService: setup failed")
            errorMessage = "Media library start nahi hui"

        @unknown default:
            errorMessage = "Unknown setup status"
        }
    }
    
    /// Copy media to app directory and add to library using async/await.
    func copyMediaToAppDirectoryAndAddToLibrary(from sourceURL: URL) async throws -> URL {
        return try await withCheckedThrowingContinuation { continuation in
            guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                continuation.resume(throwing: NSError(domain: "MediaLibraryService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Documents directory not found"]))
                return
            }
            let destinationFolderURL = documentsURL.appendingPathComponent(vlcFolderName)
            let destinationURL = destinationFolderURL.appendingPathComponent(sourceURL.lastPathComponent)
            
            do {
                try FileManager.default.createDirectory(at: destinationFolderURL, withIntermediateDirectories: true, attributes: nil)
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    continuation.resume(returning: destinationURL)
                    Task { await self.reload() } // Reload if file already exists
                    return
                }
                
                try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
                // Trigger a rescan after a successful copy.
                Task {
                    do {
                        try await Task.sleep(nanoseconds: 1_000_000_000)
                        await self.reload()
                        try await Task.sleep(nanoseconds: 1_000_000_000)
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }
                continuation.resume(returning: destinationURL)
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    // MARK: - Public Asynchronous Methods
    /// Reload the medialib and update published properties.
    func reload() async {
        medialib.reload()
        await reloadPublishedMedia()
    }
    
    // MARK: - Private: Keep published values in sync
    private func reloadPublishedMedia() async {
        self.audioMedias = medialib.audioFiles(with: .insertionDate, desc: true) ?? []
        self.allAudioAlbums = medialib.albums() ?? []
        self.allAudioArtists = medialib.artists(with: .album, desc: true, all: false) ?? []
        self.videoMedias = medialib.videoFiles(with: .insertionDate, desc: true) ?? []
        self.histories = medialib.videoFiles()?.filter({ $0.playCount() > 0 }).sorted(by: { $0.playCount() > $1.playCount() }) ?? []
        self.genres = self.medialib.genres() ?? []
        self.playlists = medialib.playlists() ?? []
        let videos = self.videoMedias
        let audios = self.audioMedias
        self.allMedias = videos + audios

        // Re-request thumbnails missing from persisted media after a cold launch.
        (videos + audios).forEach(requestThumbnailIfNeeded(for:))
    }

    private func requestThumbnailIfNeeded(for media: VLCMLMedia) {
        guard media.thumbnail() == nil else { return }
        let identifier = media.identifier()
        guard thumbnailRequestsInFlight.insert(identifier).inserted else { return }

        let isVideo = media.type() == .video
        let queued = media.requestThumbnail(
            of: .thumbnail,
            desiredWidth: isVideo ? 320 : 120,
            desiredHeight: isVideo ? 200 : 120,
            atPosition: 0
        )
        if !queued {
            thumbnailRequestsInFlight.remove(identifier)
        }

    }
    
    func deleteMedia(_ medias: [VLCMLMedia]) async {
        defer { medialib.reload() }
        medias.forEach { m in
            if let mainFile = m.mainFile() {
                mainFile.delete()
            }
        }
        try? await Task.sleep(nanoseconds: 1_000_000_000)
    }
    
    func createNewPlaylist(_ name: String) async {
        medialib.createPlaylist(withName: name)
        try? await Task.sleep(nanoseconds: 1_000_000_000)
    }
    
    func deletePlaylist(_ ids: VLCMLIdentifier) async {
        medialib.deletePlaylist(withIdentifier: ids)
        try? await Task.sleep(nanoseconds: 1_000_000_000)
    }
    
    func createNewGroup(_ name: String) async {
        medialib.createMediaGroup(withName: name)
        try? await Task.sleep(nanoseconds: 1_000_000_000)
    }
    
    func deleteGroup(_ ids: VLCMLIdentifier) async {
        medialib.deleteMediaGroup(withIdentifier: ids)
        try? await Task.sleep(nanoseconds: 1_000_000_000)
    }
    
}

// MARK: - VLCMediaLibraryDelegate Bridge
extension MediaLibraryService: VLCMediaLibraryDelegate {
    nonisolated func medialibrary(_ medialibrary: VLCMediaLibrary, didChangeIdleBackgroundTasksWithSuccess success: Bool) {
        print(success)
        
    }
    
    nonisolated func medialibrary(_ medialibrary: VLCMediaLibrary, didUpdateParsingStatsWithOpsDone opsDone: UInt32, opsScheduled: UInt32) {
        print(opsDone)
        print(opsScheduled)
    }
    
    nonisolated func medialibrary(_ medialibrary: VLCMediaLibrary, unhandledExceptionWithContext context: String, errorMessage: String, clearSuggested: Bool) -> Bool {
        print(context)
        print(errorMessage)
        print(clearSuggested)
        return clearSuggested
    }
    
    // Media Methods
    nonisolated func medialibrary(_ medialibrary: VLCMediaLibrary, didAddMedia media: [VLCMLMedia]) {
        Task { @MainActor in
            await reloadPublishedMedia()
        }
    }
    
    nonisolated func medialibrary(_ medialibrary: VLCMediaLibrary, didDeleteMediaWithIds mediaIds: [NSNumber]) {
        Task { @MainActor in
            await reloadPublishedMedia()
        }
    }
    
    nonisolated func medialibrary(_ medialibrary: VLCMediaLibrary, didModifyMediaWithIds mediaIds: [NSNumber]) {
        Task { @MainActor in
            mediaEvent.send(.didModifyMedia(ids: mediaIds))
        }
    }
    
    // Artist Methods
    nonisolated func medialibrary(_ medialibrary: VLCMediaLibrary, didAdd artists: [VLCMLArtist]) {
        Task { @MainActor in
            artistEvent.send(.didAddArtists(artists))
        }
    }
    
    nonisolated func medialibrary(_ medialibrary: VLCMediaLibrary, didModifyArtistsWithIds artistsIds: [NSNumber]) {
        Task { @MainActor in
            artistEvent.send(.didModifyArtistsWith(ids: artistsIds))
        }
    }
    
    nonisolated func medialibrary(_ medialibrary: VLCMediaLibrary, didDeleteArtistsWithIds artistsIds: [NSNumber]) {
        Task { @MainActor in
            artistEvent.send(.didDeleteArtistsWith(ids: artistsIds))
        }
    }
    
    // Album Methods
    nonisolated func medialibrary(_ medialibrary: VLCMediaLibrary, didAdd albums: [VLCMLAlbum]) {
        Task { @MainActor in
//            allAudioAlbums = medialibrary.albums() ?? []
            albumEvent.send(.didAddAlbums(albums))
        }
    }
    
    nonisolated func medialibrary(_ medialibrary: VLCMediaLibrary, didModifyAlbumsWithIds albumsIds: [NSNumber]) {
        Task { @MainActor in
//            allAudioAlbums = medialibrary.albums() ?? []
            albumEvent.send(.didModifyAlbumsWith(ids: albumsIds))
        }
    }
    
    nonisolated func medialibrary(_ medialibrary: VLCMediaLibrary, didDeleteAlbumsWithIds albumsIds: [NSNumber]) {
        Task { @MainActor in
//            allAudioAlbums = medialibrary.albums() ?? []
            albumEvent.send(.didDeleteAlbumsWith(ids: albumsIds))
        }
    }
    
    // Playlist Methods
    nonisolated func medialibrary(_ medialibrary: VLCMediaLibrary, didAdd playlists: [VLCMLPlaylist]) {
        Task { @MainActor in
            self.playlists = medialibrary.playlists() ?? []
            playlistEvent.send(.didAddPlaylist(medialibrary.playlists() ?? []))
            isLoading = false
        }
    }
    
    nonisolated func medialibrary(_ medialibrary: VLCMediaLibrary, didModifyPlaylistsWithIds playlistsIds: [NSNumber]) {
        Task { @MainActor in
            playlists = medialibrary.playlists() ?? []
            playlistEvent.send(.didModifyPlaylist(ids: playlistsIds, medialibrary.playlists() ?? []))
            isLoading = false
        }
    }
    
    nonisolated func medialibrary(_ medialibrary: VLCMediaLibrary, didDeletePlaylistsWithIds playlistsIds: [NSNumber]) {
        Task { @MainActor in
            playlists = medialibrary.playlists() ?? []
            playlistEvent.send(.didDeletePlaylistWithIds(ids: playlistsIds, medialibrary.playlists() ?? []))
            isLoading = false
        }
    }
                
    nonisolated func medialibrary(_ medialibrary: VLCMediaLibrary, thumbnailReadyFor media: VLCMLMedia, of type: VLCMLThumbnailSizeType, withSuccess success: Bool) {
        Task { @MainActor in
            let identifier = media.identifier()
            thumbnailRequestsInFlight.remove(identifier)
            guard success else { return }

            if media.type() == .video,
               let index = videoMedias.firstIndex(where: { $0.identifier() == media.identifier() }) {
                videoMedias[index] = media
            } else if media.type() == .audio,
                      let index = audioMedias.firstIndex(where: { $0.identifier() == media.identifier() }) {
                audioMedias[index] = media
            }
            allMedias = videoMedias + audioMedias
        }
    }
    
    nonisolated func medialibrary(_ medialibrary: VLCMediaLibrary, historyChangedOf type: VLCMLHistoryType) {
        let _ = medialibrary.audioHistory()
        if type == .global {
            print("Media")
        } else {
            print("Other")
        }
    }
    
    
    // Discovery Methods
    nonisolated func medialibraryDidStartDiscovery(_ medialibrary: VLCMediaLibrary) {
        Task { @MainActor in
            isRescanning = true
            discoveryEvent.send(.didStartDiscovery)
        }
    }
    
    nonisolated func medialibrary(_ medialibrary: VLCMediaLibrary, didProgressDiscovery currentFolder: String) {
        Task { @MainActor in
            discoveryEvent.send(.didProgressDiscovery(currentFolder))
            isRescanning = true
        }
    }
    
    nonisolated func medialibraryDidStartRescan(_ medialibrary: VLCMediaLibrary) {
        Task { @MainActor in
            discoveryEvent.send(.didStartRescan)
            isRescanning = true
        }
    }
    
    nonisolated func medialibraryDidEndDiscovery(_ medialibrary: VLCMediaLibrary) {
        Task { @MainActor in
            await reloadPublishedMedia()
            discoveryEvent.send(.didEndDiscovery(library: medialibrary))
            isRescanning = false
        }
    }
    
    nonisolated func medialibrary(_ medialibrary: VLCMediaLibrary, didFailDiscovery entryPoint: String) {
        Task { @MainActor in
            discoveryEvent.send(.didFailDiscovery(entryPoint))
            isRescanning = false
        }
    }
}
