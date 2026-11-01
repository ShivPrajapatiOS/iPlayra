//
//  iPlayraApp.swift
//  iPlayra
//
//  Created by Shiv on 21/10/26.
//

import SwiftUI

@main
struct iPlayraApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        GlobalStorage.appLaunchCount += 1
        print("App Launched \(GlobalStorage.appLaunchCount) times.")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .lockOrientation(to: .portrait)
        }
    }
}

class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    static var orientationLock: UIInterfaceOrientationMask = .portrait
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        print("AppDelegate: didFinishLaunchingWithOptions")
        return true
    }
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return AppDelegate.orientationLock
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return true
    }
}

struct OrientationLock: ViewModifier {
    let orientation: UIInterfaceOrientationMask
    
    private func setOrientation() {
        AppDelegate.orientationLock = orientation
        if #available(iOS 16.0, *) {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: orientation)) { error in
                    // Handle error if necessary
                }
            }
        } else {
            UIDevice.current.setValue(orientation.rawValue, forKey: "orientation")
        }
        UIViewController.attemptRotationToDeviceOrientation()
    }
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                setOrientation()
            }
            .onDisappear {
                AppDelegate.orientationLock = .allButUpsideDown
                UIViewController.attemptRotationToDeviceOrientation()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                if AppDelegate.orientationLock == self.orientation {
                    setOrientation()
                }
            }
    }
}

extension View {
    func lockOrientation(to orientation: UIInterfaceOrientationMask) -> some View {
        self.modifier(OrientationLock(orientation: orientation))
    }
}
