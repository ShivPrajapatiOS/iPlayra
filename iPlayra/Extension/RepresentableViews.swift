//
//  RepresentableViews.swift
//  iPlay
//
//  Created by Shiv on 07/09/25.
//

import SwiftUI
import Combine
import UIKit
import Foundation
import UniformTypeIdentifiers
import WebKit
import AVKit
import MarqueeLabel
import PhotosUI

// MARK: - BlurView
struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: style))
        return blurView
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}

// MARK: - ShareSheetView
struct ShareSheetView: UIViewControllerRepresentable {
    var items: [Any] // share karne wale items
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - GalleryPickerView
struct GalleryVideoPickerView: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    
    var onVideoPicked: ([URL]) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        
        configuration.filter = .videos
        configuration.selectionLimit = 0

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
        // ...
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    // MARK: Coordinator Class
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: GalleryVideoPickerView

        init(parent: GalleryVideoPickerView) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.isPresented = false
            
            guard !results.isEmpty else {
                parent.onVideoPicked([])
                return
            }

            let dispatchGroup = DispatchGroup()
            var selectedURLs: [URL] = []
            
            for result in results {
                if result.itemProvider.hasItemConformingToTypeIdentifier("public.movie") {
                    dispatchGroup.enter()
                    result.itemProvider.loadItem(forTypeIdentifier: "public.movie", options: [:]) { (item, error) in
                        if let url = item as? URL {
                            selectedURLs.append(url)
                        }
                        dispatchGroup.leave()
                    }
                }
            }
            dispatchGroup.notify(queue: .main) {
                self.parent.onVideoPicked(selectedURLs)
            }
        }
    }
}



// MARK: - Web Page Load View
struct WebPageLoadView: UIViewRepresentable {
    var pageName: String = "PrivacyPolicy"
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.underPageBackgroundColor = .clear
        if let url = Bundle.main.url(forResource: pageName, withExtension: "html") {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}



struct AirPlayButton: UIViewRepresentable {
    func makeUIView(context: Context) -> AVRoutePickerView {
        let routePickerView = AVRoutePickerView()
        routePickerView.activeTintColor = .theme
        routePickerView.tintColor = .white
        routePickerView.backgroundColor = .clear
        routePickerView.sizeToFit()
        return routePickerView
    }
    
    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {}
}

// MARK: - MarqueeLabel
struct MarqueeTextView: UIViewRepresentable {
    var text: String
    var leadingBuffer: CGFloat = 0
    
    func makeUIView(context: Context) -> MarqueeLabel {
        let label = MarqueeLabel(frame: .zero, duration: 8.0, fadeLength: 0)
        label.autoresizesSubviews = true
        label.text = text
        label.type = .continuous
        label.speed = .rate(25)
        label.forceScrolling = true
        label.animationDelay = 1.0
        label.baselineAdjustment = .alignCenters
        label.leadingBuffer = leadingBuffer
        label.trailingBuffer = -leadingBuffer
        label.textColor = .label
        return label
    }
    
    func updateUIView(_ uiView: MarqueeLabel, context: Context) {
        uiView.text = text
    }
}
