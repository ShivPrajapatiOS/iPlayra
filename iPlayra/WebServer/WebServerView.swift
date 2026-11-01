//
//  WebServerView.swift
//  iPlay
//
//  Created by Shiv on 23/11/25.
//

import SwiftUI

struct WebServerView: View {
    @StateObject private var localWebServer = WebServer()
    
    var action: ((_ url: URL) -> Void)
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: .infinity)
                .fill(Color("202020"))
                .frame(height: 50)
                .overlay {
                    if let url = localWebServer.serverURL {
                        HStack(spacing: 15) {
                            Text("\(url.absoluteString)")
                                .font(.system(size: 16, weight: .medium, design: .default))
                                .foregroundStyle(.indigo)
                                .frame(maxWidth: .infinity)
                            Button {
                                UIPasteboard.general.string = url.absoluteString
                            } label: {
                                Image(systemName: "document.on.document")
                                    .font(.system(size: 18, weight: .medium, design: .default))
                                    .foregroundStyle(.indigo)
                            }
                            .frame(width: 40, height: 40)
                            .background {
                                RoundedRectangle(cornerRadius: .infinity).fill(.ultraThinMaterial)
                            }
                            
                        }
                        .padding(.horizontal, 15)
                    }
                }
                .padding(.horizontal, 20)
        }
        .task({
            localWebServer.startServer()
            let fileURL = await localWebServer.waitForUploadedFile()
            action(fileURL)
        })
        .onDisappear(perform: {
            localWebServer.stopServer()
        })
    }
}

#Preview {
    WebServerView { url in
        print(url)
    }
}
