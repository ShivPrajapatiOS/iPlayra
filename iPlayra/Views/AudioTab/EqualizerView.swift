//
//  EqualizerView.swift
//  iPlay
//
//  Created by Shiv on 07/09/25.
//

import SwiftUI
import VLCKit

struct EqualizerView: View {
    @StateObject var mediaPlayer: MediaPlayerManager = .shared
    @ObservedObject var purchaseManager: InAppPurchaseManager = .shared
    @State private var currentOrientation: UIDeviceOrientation = UIDevice.current.orientation
    @Binding var isPresented: Bool
    @State private var presets: [VLCAudioEqualizer.Preset] = VLCAudioEqualizer.presets
    @State private var bands: [(Float)] = Array(repeating: 0, count: 10)
    @State private var preAmplification: Float = 0
    @State private var isShowPurchaseScreen: Bool = false
    
    @Namespace private var animation
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: isPortrait(geometry: geometry) ? .bottom : .leading) {
                Color.black.opacity(0.0001).ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.bouncy) {
                            isPresented.toggle()
                        }
                    }
                ZStack {
                    VStack {
                        HStack(spacing: 10) {
                            Text("Base Booster")
                                .foregroundStyle(.gray)
                                .font(.system(size: 12, weight: .semibold, design: .default))
                            HorizontalSlider(progress: $preAmplification, minValue: -20, maxValue: 20) { (amplification, isTracking) in
                                mediaPlayer.updatePreAmplification(amplification)
                            }
                            Spacer(minLength: 0)
                            Text("\(String(format: "%.0f", preAmplification * 5))%")
                                .font(.system(size: 12, weight: .light, design: .default))
                                .frame(width: 35)
                        }
                        .foregroundStyle(Color("#FFFFFF"))
                        .padding(.horizontal, 16)
                        .frame(height: 50)
                        HStack {
                            VStack {
                                Text("+20 dB")
                                Spacer()
                                Text("0 dB")
                                Spacer()
                                Text("-20 dB")
                            }
                            .font(.system(size: 12, weight: .light, design: .default))
                            .foregroundStyle(Color("#FFFFFF"))
                            .padding(.leading, 20)
                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHStack(spacing: 5) {
                                    ForEach(bands.indices, id: \.self) { index in
                                        VStack(spacing: 6) {
                                            Text(String(format: "%.1f", bands[index]))
                                                .font(.system(size: 10, weight: .light, design: .default))
                                                .foregroundStyle(.white)
                                            VerticalSlider(progress: $bands[index], minValue: -20, maxValue: 20) { (amplification, isTracking) in
                                                mediaPlayer.updateBand(index: index, amplification: amplification)
                                            }
                                            Text("Hz\(String(format: "%.0f", VLCAudioEqualizer.init().bands[index].frequency))")
                                                .font(.system(size: 10, weight: .light, design: .default))
                                                .foregroundStyle(.white)
                                        }
                                        .frame(width: 45)
                                    }
                                }
                            }
                        }
                        .padding(.bottom, 10)
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: 15) {
                                ForEach(presets, id: \.self) { preset in
                                    Text(preset.name)
                                        .font(.system(size: 16, weight: .medium, design: .default))
                                        .foregroundStyle(mediaPlayer.preset == preset ? .white : .gray)
                                        .padding(.horizontal , 20)
                                        .frame(height: 35)
                                        .background {
                                            if mediaPlayer.preset == preset {
                                                Capsule()
                                                    .fill(.theme.gradient)
                                                    .stroke(.gray.gradient.opacity(0.25), lineWidth: 1)
                                                    .matchedGeometryEffect(id: "PRESET_ACTIVETAD", in: animation)
                                            } else {
                                                Capsule()
                                                    .fill(.ultraThinMaterial)
                                                    .stroke(.gray.gradient.opacity(0.25), lineWidth: 1)
                                            }
                                        }
                                        .contentShape(.rect)
                                        .onTapGesture {
                                            withAnimation(.snappy) {
                                                if mediaPlayer.preset != preset {
                                                    mediaPlayer.selectEqualizerPreset(preset)
                                                    mediaPlayer.eqBands.bands.enumerated().forEach { index, band in
                                                        bands[index] = band.amplification
                                                    }
                                                    preAmplification = mediaPlayer.eqBands.preAmplification
                                                }
                                            }
                                        }
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                        .scrollIndicators(.hidden)
                        .scrollPosition(id: .init(get: {
                            return mediaPlayer.preset
                        }, set: { _ in
                            
                        }), anchor: .center)
                        .frame(height: 40)
                        .padding(.bottom, 20)
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
                                    .font(.system(size: 16, weight: .regular, design: .default))
                                    .foregroundStyle(.gray.gradient)
                                    .frame(width: 35, height: 35)
                                    .background(Capsule().fill(.ultraThinMaterial))
                            }
                            HStack(spacing: 20) {
                                Text("Equalizer")
                                    .font(.system(size: 18, weight: .bold, design: .default))
                                    .foregroundStyle(Color("#FFFFFF"))
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
                            Toggle(isOn: $mediaPlayer.isOnEqualizer) {
                                HStack(spacing: 20) {
                                    Spacer()
                                    Text(mediaPlayer.isOnEqualizer ? "ON" : "OFF")
                                        .font(.system(size: 13, weight: .bold, design: .default))
                                        .foregroundStyle(.white.gradient)
                                }
                            }
                            .tint(.theme)
                            .onChange(of: mediaPlayer.isOnEqualizer) { _, isOn in
                                mediaPlayer.setEqualizerEnabled(isOn)
                            }
                            .onAppear {
                                mediaPlayer.eqBands.bands.enumerated().forEach { (index, band) in
                                    bands[index] = band.amplification
                                }
                                // ← preAmplification bhi sync karo
                                preAmplification = mediaPlayer.eqBands.preAmplification
                            }
                        }
                        .padding(10)
                    }
            }
                .frame(width: isPortrait(geometry: geometry) ? geometry.size.width : geometry.size.width / 2, height: isPortrait(geometry: geometry) ? geometry.size.height / 2 : geometry.size.height)
                .background(BlurView(style: .dark).cornerRadius(20).ignoresSafeArea())
                .animation(.linear, value: currentOrientation)
            }
            .fullScreenCover(isPresented: $isShowPurchaseScreen) {
                PurchaseView(isShowPurchase: $isShowPurchaseScreen)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            self.currentOrientation = UIDevice.current.orientation
        }
        .onAppear {
            mediaPlayer.eqBands.bands.enumerated().forEach { (index, band) in
                bands[index] = band.amplification
            }
        }
    }
    
    func isPortrait(geometry: GeometryProxy) -> Bool {
        return geometry.size.height > geometry.size.width
    }
}

#Preview {
    EqualizerView(isPresented: .constant(false))
}
