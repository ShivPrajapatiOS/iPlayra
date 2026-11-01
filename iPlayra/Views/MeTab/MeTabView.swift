//
//  MeTabView.swift
//  iPlay
//
//  Created by Shiv on 31/10/25.
//

import SwiftUI

struct MeTabView: View {
    @StateObject var languageManager: LocalizationManager = .shared
    @StateObject var purchaseManager: InAppPurchaseManager = .shared

    var body: some View {
            ZStack(alignment: .top) {
                BlurView(style: .dark).blendMode(.plusDarker).ignoresSafeArea()
                VStack(spacing: 0) {
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack {
                            VStack {
                                NavigationLink {
                                    PurchaseView(isShowPurchase: .constant(false))
                                        .environmentObject(purchaseManager)
                                } label: {
                                    HStack(spacing: 20) {
                                        Image(systemName: "crown.fill")
                                            .font(.system(size: 20, weight: .light, design: .default))
                                            .foregroundStyle(.yellow)
                                        Text("kSubscription".localized())
                                            .font(.system(size: 16, weight: .semibold, design: .default))
                                    }
                                    .foregroundStyle(.white)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .frame(height: 55)
                            .padding(.horizontal, 15)
                            .background(Color("202020"))
                            .cornerRadius(15)
                            .padding(.vertical, 5)
                            
                            VStack(spacing: 0) {
                                NavigationLink {
                                    DownloadView()
                                        .navigationBarBackButtonHidden()
                                } label: {
                                    HStack(spacing: 20) {
                                        Image(systemName: "arrow.down.circle")
                                            .font(.system(size: 20, weight: .light, design: .default))
                                        VStack(alignment: .leading, spacing: 0) {
                                            Text("kDownload".localized())
                                                .font(.system(size: 16, weight: .semibold, design: .default))
                                                .frame(maxHeight: .infinity)
                                            RoundedRectangle(cornerRadius: .infinity)
                                                .fill(Color.background)
                                                .frame(height: 1)
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .frame(height: 55)
                                    .foregroundStyle(.white)
                                }
                                NavigationLink {
                                    SettingsView()
                                        .environmentObject(languageManager)
                                } label: {
                                    HStack(spacing: 20) {
                                        Image(systemName: "gearshape")
                                            .font(.system(size: 20, weight: .light, design: .default))
                                        VStack(alignment: .leading, spacing: 0) {
                                            Text("kSettings".localized())
                                                .font(.system(size: 16, weight: .semibold, design: .default))
                                                .frame(maxHeight: .infinity)
                                            RoundedRectangle(cornerRadius: .infinity)
                                                .fill(Color.background)
                                                .frame(height: 1)
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .frame(height: 55)
                                    .foregroundStyle(.white)
                                }
                                
                                NavigationLink {
                                    Text("Contact Us")
                                } label: {
                                    HStack(spacing: 20) {
                                        Image(systemName: "bubble")
                                            .font(.system(size: 20, weight: .light, design: .default))
                                        VStack(alignment: .leading, spacing: 0) {
                                            Text("kContactUs".localized())
                                                .font(.system(size: 16, weight: .semibold, design: .default))
                                                .frame(maxHeight: .infinity)
                                            RoundedRectangle(cornerRadius: .infinity)
                                                .fill(Color.background)
                                                .frame(height: 1)
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .frame(height: 55)
                                    .foregroundStyle(.white)
                                }
                                
                                NavigationLink {
                                    Text("Rate Us")
                                } label: {
                                    HStack(spacing: 20) {
                                        Image(systemName: "star.circle")
                                            .font(.system(size: 20, weight: .light, design: .default))
                                        VStack(alignment: .leading, spacing: 0) {
                                            Text("kRateUs".localized())
                                                .font(.system(size: 16, weight: .semibold, design: .default))
                                                .frame(maxHeight: .infinity)
                                            RoundedRectangle(cornerRadius: .infinity)
                                                .fill(Color.background)
                                                .frame(height: 1)
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .frame(height: 55)
                                    .foregroundStyle(.white)
                                }
                                
                                NavigationLink {
                                    Text("About")
                                } label: {
                                    HStack(spacing: 20) {
                                        Image(systemName: "info.circle")
                                            .font(.system(size: 20, weight: .light, design: .default))
                                        VStack(alignment: .leading, spacing: 0) {
                                            Text("kAbout".localized())
                                                .font(.system(size: 16, weight: .semibold, design: .default))
                                                .frame(maxHeight: .infinity)
                                            RoundedRectangle(cornerRadius: .infinity)
                                                .fill(Color.background)
                                                .frame(height: 1)
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .frame(height: 55)
                                    .foregroundStyle(.white)
                                }
                                
                                NavigationLink {
                                    WebPageLoadView(pageName: "PrivacyPolicy")
                                        .ignoresSafeArea()
                                } label: {
                                    HStack(spacing: 20) {
                                        Image(systemName: "hand.raised.circle")
                                            .font(.system(size: 20, weight: .light, design: .default))
                                        VStack(alignment: .leading, spacing: 0) {
                                            Text("kPrivacyPolicy".localized())
                                                .font(.system(size: 16, weight: .semibold, design: .default))
                                                .frame(maxHeight: .infinity)
                                            RoundedRectangle(cornerRadius: .infinity)
                                                .fill(Color.background)
                                                .frame(height: 1)
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .frame(height: 55)
                                    .foregroundStyle(.white)
                                }
                                
                                NavigationLink {
                                    WebPageLoadView(pageName: "TermsConditions")
                                        .ignoresSafeArea()
                                } label: {
                                    HStack(spacing: 20) {
                                        Image(systemName: "info.circle")
                                            .font(.system(size: 20, weight: .light, design: .default))
                                        VStack(alignment: .leading, spacing: 0) {
                                            Text("kTermsConditions".localized())
                                                .font(.system(size: 16, weight: .semibold, design: .default))
                                                .frame(maxHeight: .infinity)
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .frame(height: 55)
                                    .foregroundStyle(Color("#FFFFFF"))
                                }
                            }
                            .padding(.horizontal, 20)
                            .background(Color("202020"))
                            .cornerRadius(15)
                        }
                    }
                    .padding(.horizontal, 15)
                }
            }
            .safeAreaInset(edge: .top) {
                HStack {
                    Text("kMe".localized())
                        .font(.system(size: 20, weight: .bold, design: .default))
                }
                .frame(maxWidth: .infinity, minHeight: 50, alignment: .center)
                .padding(.horizontal, 16)
                .background(BlurView(style: .dark).blendMode(.plusDarker).ignoresSafeArea()
                    .overlay(alignment: .bottom, content: {
                        Rectangle().fill(Color("#5C5C5C").opacity(0.25))
                            .frame(height: 1)
                    }))
            }
    }
}

#Preview {
//    MeTabView()
//        .environmentObject(LocalizationManager.shared)
//        .environmentObject(InAppPurchaseManager.shared)
    ContentView()
}
