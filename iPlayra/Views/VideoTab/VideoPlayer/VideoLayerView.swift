//
//  VideoLayerView.swift
//  iPlay
//
//  Created by Shiv on 07/03/26.
//

import Foundation
import UIKit
import SwiftUI
import Combine
import AVKit
import VLCKit

final class PiPVideoView: UIView, VLCPictureInPictureDrawable {
    weak var playbackController: VLCPictureInPictureMediaControlling?
    private(set) var pipController: VLCPictureInPictureWindowControlling?
    var onPiPReady: (() -> Void)?
    var onPiPStateChange: ((Bool) -> Void)?

    func mediaController() -> VLCPictureInPictureMediaControlling! {
        print("PiP: mediaController requested, nil?", playbackController == nil)
        return playbackController
    }

    func pictureInPictureReady() -> ((VLCPictureInPictureWindowControlling?) -> Void)! {
        print("PiP: pictureInPictureReady requested")
        return { [weak self] controller in
            print("PiP: controller received:", controller as Any)
            guard let self, let controller else { return }
            controller.stateChangeEventHandler = { [weak self] isStarted in
                print("PiP: state changed, started =", isStarted)
                self?.onPiPStateChange?(isStarted)
            }
            self.pipController = controller
            self.onPiPReady?()
        }
    }

    func startPiP() {
        print("PiP: startPiP tapped, controller =", String(describing: pipController))
        DispatchQueue.main.async {
            self.pipController?.startPictureInPicture()
        }
    }
    func stopPiP() {
        pipController?.stopPictureInPicture()
    }
    func invalidatePlayback() {
        pipController?.invalidatePlaybackState()
    }
}

struct VideoLayerView: UIViewRepresentable {
    @ObservedObject private var mediaPlayer: MediaPlayerManager = .shared

    func makeUIView(context: Context) -> PiPVideoView {
        let videoView = mediaPlayer.videoOutputView   // manager wala hi view, naya mat banao
        videoView.backgroundColor = .black
        return videoView
    }

    func updateUIView(_ uiView: PiPVideoView, context: Context) {}
}

// MARK: - VideoLayerView
//struct VideoLayerView: UIViewControllerRepresentable {
//    @ObservedObject private var mediaPlayer: MediaPlayerManager = .shared
//
//    // UIViewController Create
//    func makeUIViewController(context: Context) -> UIViewController {
//        let controller = UIViewController()
//        let videoView = UIView()
//        videoView.backgroundColor = .black
//        videoView.translatesAutoresizingMaskIntoConstraints = false
//        videoView.tag = 999  // 🔖 Tag to identify view later
//
//        controller.view.addSubview(videoView)
//
//        NSLayoutConstraint.activate([
//            videoView.topAnchor.constraint(equalTo: controller.view.topAnchor),
//            videoView.bottomAnchor.constraint(equalTo: controller.view.bottomAnchor),
//            videoView.leadingAnchor.constraint(equalTo: controller.view.leadingAnchor),
//            videoView.trailingAnchor.constraint(equalTo: controller.view.trailingAnchor)
//        ])
//
////        mediaPlayer.setDrawableView(view: videoView)
//        mediaPlayer.videoOutputView = videoView
//        return controller
//    }
//    // UIViewController Update
//    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
////        if let videoView = uiViewController.view.viewWithTag(999) {
////            mediaPlayer.setDrawableView(view: videoView)
////        }
//    }
//}


// MARK: - PiP Supporting
//struct VideoLayerView: UIViewControllerRepresentable {
//    @StateObject private var mediaPlayer: MediaPlayerManager = .shared
//    
//    func makeUIViewController(context: Context) -> VideoLayerViewController {
//        let controller = VideoLayerViewController()
//        // MediaPlayerManager ko Controller mein pass karein
//        controller.mediaPlayerManager = mediaPlayer
//        return controller
//    }
//    
//    func updateUIViewController(_ uiViewController: VideoLayerViewController, context: Context) {
//        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut]) {
//            uiViewController.view.layoutIfNeeded()
//        }
//    }
//}

//class VideoLayerViewController: UIViewController, AVPictureInPictureControllerDelegate {
//    
//    // MediaPlayerManager se data milega
//    var mediaPlayerManager: MediaPlayerManager!
//    
//    // Video View
//    let videoView = UIView()
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        
//        // 1. Setup view
//        setupVideoView()
//        
//        // 2. Audio Session Configure (PiP)
//        configureAudioSession()
//        
//        // 3. PiP Setup
//        setupPictureInPicture()
//    }
//    
//    private func setupVideoView() {
//            view.backgroundColor = .black
//            videoView.backgroundColor = .black
//            
//            videoView.contentMode = .scaleAspectFit
//            videoView.translatesAutoresizingMaskIntoConstraints = false
//            view.addSubview(videoView)
//
//            NSLayoutConstraint.activate([
//                videoView.topAnchor.constraint(equalTo: view.topAnchor),
//                videoView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//                videoView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//                videoView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
//            ])
//            
//            mediaPlayerManager.videoOutputView = videoView
//        }
//
//        // Is method ko add karein taaki resize ke waqt VLC layer adjust ho sake
//        override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
//            super.viewWillTransition(to: size, with: coordinator)
//            
//            coordinator.animate(alongsideTransition: { _ in
//                // Resize ke waqt layout refresh karein
//                self.view.layoutIfNeeded()
//            }, completion: nil)
//        }
//    
//    // --- PiP and Audio Setup ---
//    
//    func configureAudioSession() {
//        do {
//            let session = AVAudioSession.sharedInstance()
//            try session.setCategory(.playback, mode: .moviePlayback, options: [])
//            try session.setActive(true)
//        } catch {
//            print("❌ Audio Session error: \(error.localizedDescription)")
//        }
//    }
//    
//    func setupPictureInPicture() {
//        guard AVPictureInPictureController.isPictureInPictureSupported() else {
//            print("🚫 PiP is not supported on this device.")
//            return
//        }
//        
//        // VLCKit 4.0+ mein, yeh UIView ka layer PiP compatible ho jata hai.
//        let contentSource = AVPictureInPictureController.ContentSource(
//            activeVideoCallSourceView: videoView,
//            contentViewController: AVPictureInPictureVideoCallViewController()
//        )
//        
//        let pipController = AVPictureInPictureController(contentSource: contentSource)
//        
//        // Agar app background mein jaye to PiP automatically start ho jaye
//        pipController.canStartPictureInPictureAutomaticallyFromInline = true
//        
//        // Delegate assign karein
//        pipController.delegate = self
//        
//        // PiP Controller ko Manager mein store karein taaki SwiftUI se control kiya ja sake
//        mediaPlayerManager.pipController = pipController
//    }
//    
//    // --- AVPictureInPictureControllerDelegate Methods ---
//    
//    func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
//        print("✅ PiP Did Start")
//        // Yahan aap PiP active hone par UI update kar sakte hain
//    }
//    
//    func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
//        print("🛑 PiP Did Stop")
//        // Yahan aap PiP inactive hone par UI update kar sakte hain
//    }
//    
//    // Jab user PiP se wapas app mein aana chahe
//    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
//        // App ko foreground mein lakar UI restore karein
//        completionHandler(true)
//    }
//}
