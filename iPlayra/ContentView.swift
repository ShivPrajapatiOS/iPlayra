//
//  ContentView.swift
//  iPlayra
//
//  Created by Shiv on 21/10/26.
//

import SwiftUI
import Combine
import VLCMediaLibraryKit
import VLCKit

struct ContentView: View {
    @Environment(\.scenePhase) var scenePhase
        
    @AppStorage("SELECTED_TAB") private var selectedTab: TabBar = .me
    
    @State private var showVideoPlayer: Bool = false
    
    var body: some View {
        ZStack {
            TabBarView(selectedTab: $selectedTab, showVideoPlayer: $showVideoPlayer)
            ZStack {
                if showVideoPlayer {
                    VideoPlayerView(showVideoPlayer: $showVideoPlayer) {
                        closePlayer()
                    }
                }
            }
        }
    }
    
    func closePlayer() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
        }
        AppDelegate.orientationLock = .portrait
        UIViewController.attemptRotationToDeviceOrientation()
        MediaPlayerManager.shared.stop()
        withAnimation(.linear(duration: 0.25)) {
            showVideoPlayer = false
        }
    }
}


#Preview {
    ContentView()
}

struct DeviceRotationViewModifier: ViewModifier {
    let action: (UIDeviceOrientation) -> Void

    func body(content: Content) -> some View {
        content
            .onAppear()
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                action(UIDevice.current.orientation)
            }
    }
}

// A View wrapper to make the modifier easier to use
extension View {
    func onRotate(perform action: @escaping (UIDeviceOrientation) -> Void) -> some View {
        self.modifier(DeviceRotationViewModifier(action: action))
    }
}


struct OrientationSheetView: View {
    @State private var showSheet = false
    @State private var orientation = UIDevice.current.orientation
    
    var body: some View {
        Button("Open Sheet") {
            showSheet.toggle()
        }
        .sheet(isPresented: $showSheet) {
            SheetContent()
                .modifier(ResponsiveSheetModifier(orientation: orientation))
                .presentationDetents([.medium, .large]) // portrait ke liye
        }
        .onAppear {
            startOrientationObserver()
        }
        .onDisappear {
            NotificationCenter.default.removeObserver(self)
        }
    }
    
    private func startOrientationObserver() {
        NotificationCenter.default.addObserver(
            forName: UIDevice.orientationDidChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.orientation = UIDevice.current.orientation
        }
    }
}

struct SheetContent: View {
    var body: some View {
        VStack {
            Text("Hello Sheet")
                .font(.system(size: 10, weight: .light, design: .default))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.orange.opacity(0.2))
    }
}

struct ResponsiveSheetModifier: ViewModifier {
    let orientation: UIDeviceOrientation
    func body(content: Content) -> some View {
        GeometryReader { geo in
            if orientation == .landscapeLeft || orientation == .landscapeRight || orientation == .portraitUpsideDown {
                content
                    .frame(width: geo.size.width / 2, height: geo.size.height) // half width, full height
            } else {
                content // portrait → default
            }
        }
    }
}

