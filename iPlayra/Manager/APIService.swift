//
//  APIService.swift
//  iPlay
//
//  Created by Shiv on 04/02/26.
//

import SwiftUI
import Combine


// MARK: - APIErrorr
enum APIErrorr: Error {
    case invalidURL
    case requestFailed(String)
    case invalidResponse
    case decodingError
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "The URL provided is invalid."
        case .requestFailed(let message):
            return message
        case .invalidResponse:
            return "Received an invalid response from the server."
        case .decodingError:
            return "Failed to parse the data from the server."
        }
    }
}

// MARK: - LyricLine
struct LyricLine: Identifiable, Hashable {
    let id = UUID()
    let startTime: TimeInterval
    let startMiliseconds: Int32
    let text: String
}


// MARK: - LyricResponse
struct LyricResponse: Codable {
    let id: Int
    let name: String?
    let trackName: String
    let artistName: String
    let albumName: String?
    let duration: Double?
    let instrumental: Bool?
    let plainLyrics: String?
    let syncedLyrics: String?
}

// MARK: - LyricsService
class LyricsService {
    static let shared = LyricsService()
    
    func fetchLyrics(artist: String, track: String) async throws -> LyricResponse {
        var components = URLComponents(string: "https://lrclib.net/api/get")!
        components.queryItems = [
            URLQueryItem(name: "artist_name", value: artist),
            URLQueryItem(name: "track_name", value: track)
        ]
        
        guard let url = components.url else { throw APIErrorr.invalidURL }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIErrorr.invalidResponse
        }
        
        return try JSONDecoder().decode(LyricResponse.self, from: data)
    }
    
    func searchLyrics(query: String) async throws -> [LyricResponse] {
            var components = URLComponents(string: "https://lrclib.net/api/search")!
            
            components.queryItems = [
                URLQueryItem(name: "q", value: query)
            ]
            
            guard let url = components.url else { throw APIErrorr.invalidURL }
            
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw APIErrorr.invalidResponse
            }
            
            do {
//                if let jsonString = String(data: data, encoding: .utf8) {
//                    print("--- RAW JSON START ---")
//                    print(jsonString)
//                    print("--- RAW JSON END ---")
//                }
                return try JSONDecoder().decode([LyricResponse].self, from: data)
            } catch {
                throw APIErrorr.decodingError
            }
        }
}


// MARK: - LyricsViewModel
class LyricsViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    @Published var lyrics: [LyricResponse] = []
    @Published var syncedLyricLines: [LyricLine] = []
    @Published var plainLyric: [String] = []
    
    
    func loadLyrics(artist name: String, song title: String) async throws -> LyricResponse {
        do {
            let result = try await LyricsService.shared.fetchLyrics(artist: name, track: title)
            return result
        } catch {
            throw error
        }
    }
    
    func performSearch(for rawTitle: String) async throws -> [LyricResponse] {
        let cleanQuery = rawTitle.cleanSongTitle()
        do {
            let results = try await LyricsService.shared.searchLyrics(query: cleanQuery)
            return results
        } catch {
            throw error
        }
    }
}
