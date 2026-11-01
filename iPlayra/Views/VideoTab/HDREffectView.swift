//
//  HDREffectView.swift
//  iPlay
//
//  Created by Shiv on 19/09/25.
//

import SwiftUI
import Combine
import VLCKit

struct HDREffectView: View {
    @StateObject private var mediaPlayer: MediaPlayerManager = .shared
    @StateObject private var purchaseManager: InAppPurchaseManager = .shared
    @State private var currentOrientation: UIDeviceOrientation = UIDevice.current.orientation
    @Binding var isPresented: Bool
    @State private var isShowPurchaseScreen: Bool = false
    @State private var isOnFilter: Bool = false
    @State private var brightness: Float = 1
    @State private var contrast: Float = 1
    @State private var saturation: Float = 1
    @State private var gamma: Float = 1
    @State private var hue: Float = 1
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: isPortrait(geometry: geometry) ? .bottom : .leading) {
                Color.black.opacity(0.0001).ignoresSafeArea()
                    .onTapGesture {
                        isPresented.toggle()
                    }
                ZStack {
                    VStack {
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(alignment: .leading) {
                                Text("Brightness  \(String(format: "%.3f", brightness))")
                                    .font(.system(size: 14, weight: .light, design: .default))
                                    .foregroundStyle(.white)
                                HorizontalSlider(progress: $brightness, minValue: 0, maxValue: 2) { (progress, isTracking) in
                                    mediaPlayer.applyVideoFilterEffect(filter: (brightness, contrast, saturation, gamma, hue, isOnFilter))
                                }
                            }
                            .padding(.horizontal, 20)
                            VStack(alignment: .leading) {
                                Text("Contrast  \(String(format: "%.3f", contrast))")
                                    .font(.system(size: 14, weight: .light, design: .default))
                                    .foregroundStyle(.white)
                                HorizontalSlider(progress: $contrast, minValue: 0, maxValue: 2) { (progress, isTracking) in
                                    mediaPlayer.applyVideoFilterEffect(filter: (brightness, contrast, saturation, gamma, hue, isOnFilter))
                                }
                            }
                            .padding(.horizontal, 20)
                            VStack(alignment: .leading) {
                                Text("Saturation  \(String(format: "%.3f", saturation))")
                                    .font(.system(size: 14, weight: .light, design: .default))
                                    .foregroundStyle(.white)
                                HorizontalSlider(progress: $saturation, minValue: 0, maxValue: 3) { (progress, isTracking) in
                                    mediaPlayer.applyVideoFilterEffect(filter: (brightness, contrast, saturation, gamma, hue, isOnFilter))
                                }
                            }
                            .padding(.horizontal, 20)
                            VStack(alignment: .leading) {
                                Text("Gamma  \(String(format: "%.3f", gamma))")
                                    .font(.system(size: 14, weight: .light, design: .default))
                                    .foregroundStyle(.white)
                                HorizontalSlider(progress: $gamma, minValue: 0.01, maxValue: 10) { (progress, isTracking) in
                                    mediaPlayer.applyVideoFilterEffect(filter: (brightness, contrast, saturation, gamma, hue, isOnFilter))
                                }
                            }
                            .padding(.horizontal, 20)
                            VStack(alignment: .leading) {
                                Text("Hue  \(String(format: "%.3f", hue))")
                                    .font(.system(size: 14, weight: .light, design: .default))
                                    .foregroundStyle(.white)
                                HorizontalSlider(progress: $hue, minValue: -180, maxValue: 180) { (progress, isTracking) in
                                    print("Hue:",hue)
                                    mediaPlayer.applyVideoFilterEffect(filter: (brightness, contrast, saturation, gamma, hue, isOnFilter))
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .safeAreaInset(edge: .top) {
                        HStack {
                            Button {
                                withAnimation(.bouncy) {
                                    isPresented.toggle()
                                }
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 18, weight: .regular, design: .default))
                                    .foregroundStyle(.gray.gradient)
                                    .frame(width: 35, height: 35)
                                    .background(Capsule().fill(.ultraThinMaterial))
                            }
                            HStack(spacing: 20) {
                                Text("HDR Effect")
                                    .font(.system(size: 18, weight: .semibold, design: .default))
                                    .foregroundStyle(.white)
                                if !purchaseManager.hasPurchased {
                                    Button {
                                        isShowPurchaseScreen.toggle()
                                    } label: {
                                        Image(systemName: "crown.fill")
                                            .font(.system(size: 25, weight: .light, design: .default))
                                            .foregroundStyle(LinearGradient(colors: [.pink, .purple, .blue], startPoint: .bottomLeading, endPoint: .topTrailing))
                                    }
                                }
                            }
                            Spacer(minLength: 0)
                            Toggle(isOn: $isOnFilter) {
                                HStack(spacing: 20) {
                                    Spacer()
                                    Text(isOnFilter ? "On" : "Off")
                                        .foregroundStyle(.white)
                                }
                            }
                            .tint(.theme)
                            .onChange(of: isOnFilter) { (oldValue, newValue) in
                                if !purchaseManager.hasPurchased && GlobalStorage.appLaunchCount > 100 {
                                    isShowPurchaseScreen = true
                                    isOnFilter = false
                                } else {
                                    mediaPlayer.applyVideoFilterEffect(filter: (brightness, contrast, saturation, gamma, hue, isOnFilter))
                                    if !isOnFilter {
                                        let filter = mediaPlayer.hdrFilters
                                        self.brightness = (filter.brightness.defaultValue as! Float)
                                        self.contrast = (filter.contrast.defaultValue as! Float)
                                        self.saturation = (filter.saturation.defaultValue as! Float)
                                        self.gamma = (filter.gamma.defaultValue as! Float)
                                        self.hue = (filter.hue.defaultValue as! Float)
                                    }
                                }
                            }
                        }
                        .padding(10)
                    }
                }
                .frame(width: isPortrait(geometry: geometry) ? geometry.size.width : geometry.size.width / 2, height: isPortrait(geometry: geometry) ? geometry.size.height / 2 : geometry.size.height)
                .background(BlurView(style: .dark).cornerRadius(20).ignoresSafeArea())
                .animation(.linear, value: currentOrientation)
            }
            .frame(maxWidth: geometry.size.width, maxHeight: geometry.size.height, alignment: .bottom)
            .fullScreenCover(isPresented: $isShowPurchaseScreen) {
                PurchaseView(isShowPurchase: $isShowPurchaseScreen)
            }
        }
        .onAppear {
            let filter = mediaPlayer.hdrFilters
            self.isOnFilter = filter.isEnabled
            self.brightness = filter.isEnabled ? (filter.brightness.value as! Float) : (filter.brightness.defaultValue as! Float)
            self.contrast = filter.isEnabled ? (filter.contrast.value as! Float) : (filter.contrast.defaultValue as! Float)
            self.saturation = filter.isEnabled ? (filter.saturation.value as! Float) : (filter.saturation.defaultValue as! Float)
            self.gamma = filter.isEnabled ? (filter.gamma.value as! Float) : (filter.gamma.defaultValue as! Float)
            self.hue = filter.isEnabled ? (filter.hue.value as! Float) : (filter.hue.defaultValue as! Float)
        }
    }
    
    func isPortrait(geometry: GeometryProxy) -> Bool {
        return geometry.size.height > geometry.size.width
    }
}

#Preview {
    HDREffectView(isPresented: .constant(false))
        .environmentObject(MediaPlayerManager.shared)
}
