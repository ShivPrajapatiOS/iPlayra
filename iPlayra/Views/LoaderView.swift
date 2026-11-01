//
//  LoaderView.swift
//  iPlay
//
//  Created by Shiv on 07/10/25.
//

import SwiftUI

final class GlobalLoader {

    static let shared = GlobalLoader()

    private var window: UIWindow?

    private init() {}

    func show() {
        guard window == nil else { return }

        // 🔹 Get active window scene
        guard let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else {
            return
        }

        let window = UIWindow(windowScene: scene)
        window.frame = scene.coordinateSpace.bounds
        window.windowLevel = .alert + 1
        window.backgroundColor = .clear

        let host = UIHostingController(
            rootView: ZStack {
                LoaderView()
            }
        )

        host.view.backgroundColor = .clear
        window.rootViewController = host
        window.isHidden = false

        self.window = window
    }

    func hide() {
        window?.isHidden = true
        window = nil
    }
}


struct LoaderView: View {
    var body: some View {
        ZStack {
            Rectangle().fill(.ultraThinMaterial)
                .ignoresSafeArea()

            Spinner()
        }
        .contentShape(Rectangle())
        .ignoresSafeArea()
    }
}

struct LoadingViewModifier: ViewModifier {
    @Binding var isShowing: Bool

    func body(content: Content) -> some View {
        ZStack {
            content
                .disabled(isShowing)
                .opacity(isShowing ? 0.7 : 1.0)
            if isShowing {
                LoaderView()
                    .transition(.blurReplace())
            }
        }
    }
}

extension View {
    func loader(isShowing: Binding<Bool>) -> some View {
        self.modifier(LoadingViewModifier(isShowing: isShowing))
    }
}

struct Spinner: View {

    let rotationTime: Double = 0.75
    let animationTime: Double = 1.9 // Sum of all animation times
    let fullRotation: Angle = .degrees(360)
    static let initialDegree: Angle = .degrees(270)

    @State var spinnerStart: CGFloat = 0.0
    @State var spinnerEndS1: CGFloat = 0.03
    @State var spinnerEndS2S3: CGFloat = 0.03

    @State var rotationDegreeS1 = initialDegree
    @State var rotationDegreeS2 = initialDegree
    @State var rotationDegreeS3 = initialDegree

    var body: some View {
        ZStack {
            // S3
            SpinnerCircle(start: spinnerStart, end: spinnerEndS2S3, rotation: rotationDegreeS3, color: .theme.opacity(0.5))

            // S2
            SpinnerCircle(start: spinnerStart, end: spinnerEndS2S3, rotation: rotationDegreeS2, color: .theme.opacity(0.75))

            // S1
            SpinnerCircle(start: spinnerStart, end: spinnerEndS1, rotation: rotationDegreeS1, color: .theme)
        }
        .frame(width: 100, height: 100)
        .onAppear() {
            self.animateSpinner()
            Timer.scheduledTimer(withTimeInterval: animationTime, repeats: true) { (mainTimer) in
                self.animateSpinner()
            }
        }
    }

    // MARK: Animation methods
    func animateSpinner(with duration: Double, completion: @escaping (() -> Void)) {
        Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { _ in
            withAnimation(Animation.easeInOut(duration: self.rotationTime)) {
                completion()
            }
        }
    }

    func animateSpinner() {
        animateSpinner(with: rotationTime) { self.spinnerEndS1 = 1.0 }

        animateSpinner(with: (rotationTime * 2) - 0.025) {
            self.rotationDegreeS1 += fullRotation
            self.spinnerEndS2S3 = 0.5
        }

        animateSpinner(with: (rotationTime * 2)) {
            self.spinnerEndS1 = 0.02
            self.spinnerEndS2S3 = 0.02
        }

        animateSpinner(with: (rotationTime * 2) + 0.0525) { self.rotationDegreeS2 += fullRotation }

        animateSpinner(with: (rotationTime * 2) + 0.225) { self.rotationDegreeS3 += fullRotation }
    }
}

// MARK: SpinnerCircle

struct SpinnerCircle: View {
    var start: CGFloat
    var end: CGFloat
    var rotation: Angle
    var color: Color

    var body: some View {
        Circle()
            .trim(from: start, to: end)
            .stroke(style: StrokeStyle(lineWidth: 10, lineCap: .round))
            .fill(color)
            .rotationEffect(rotation)
    }
}

#Preview {
    LoaderView()
}
