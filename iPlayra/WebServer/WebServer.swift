//
//  WebServer.swift
//  iPlay
//
//  Created by Shiv on 22/11/25.
//

import SwiftUI
import Combine
import GCDWebServer

class WebServer: ObservableObject {
    let webServer = GCDWebServer()
    @Published private(set) var serverURL: URL?
    
    private var continuation: CheckedContinuation<URL, Never>?
    
    /// ⬇️ Call this function to wait for uploaded file URL
        func waitForUploadedFile() async -> URL {
            return await withCheckedContinuation { continuation in
                self.continuation = continuation
            }
        }
    
    func startServer() {
        
        // 1️⃣ Serve Static HTML Directory FIRST
               let htmlPath = Bundle.main.path(forResource: "index", ofType: "html")!

               webServer.addGETHandler(
                   forBasePath: "/",
                   directoryPath: (htmlPath as NSString).deletingLastPathComponent,
                   indexFilename: "index.html",
                   cacheAge: 0,
                   allowRangeRequests: true
               )
        
        // 2️⃣ Serve Image Route (NOW IT WILL MATCH)
        webServer.addHandler(forMethod: "GET", path: "/ic_app", request: GCDWebServerRequest.self) { request -> GCDWebServerResponse? in
            
            guard let filePath = Bundle.main.path(forResource: "ic_app", ofType: "png"),
                  let data = try? Data(contentsOf: URL(fileURLWithPath: filePath)) else {
                return GCDWebServerDataResponse(text: "Icon not found")
            }
            
            let response = GCDWebServerDataResponse(data: data, contentType: "image/png")
            response.setValue("no-cache", forAdditionalHeader: "Cache-Control")
            
            return response
        }

        // File Upload Handler
        webServer.addHandler(forMethod: "POST", path: "/upload", request: GCDWebServerMultiPartFormRequest.self) { request in
            
            guard let multipart = request as? GCDWebServerMultiPartFormRequest,
                  let file = multipart.firstFile(forControlName: "file") else {
                return GCDWebServerDataResponse(text: "Upload Failed")
            }
            
            // Save file in documents directory
            let docURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let destination = docURL.appendingPathComponent(file.fileName)
            
            do {
                try FileManager.default.moveItem(atPath: file.temporaryPath, toPath: destination.path)
                print("File saved at: \(destination)")
                self.continuation?.resume(returning: destination)
                self.continuation = nil
            } catch {
                print("Error saving file: \(error)")
            }
            
            return GCDWebServerDataResponse(text: "Upload Successful ✔️")
        }
        
        try? webServer.start(options: [
            "Port": 8080,
            "BindToLocalhost": true
        ])
        
        serverURL = webServer.serverURL
        print("🚀 Server Running at: \(serverURL!)")
    }
    
    func stopServer() {
        webServer.stop()
    }
}
