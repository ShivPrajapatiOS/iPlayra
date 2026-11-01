//
//  SettingsView.swift
//  iPlay
//
//  Created by Shiv on 31/10/25.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var languageManager: LocalizationManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
            ZStack(alignment: .top) {
                Color.background.ignoresSafeArea()
                VStack(spacing: 0) {
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 15) {
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color("202020"))
                                .overlay {
                                    VStack(spacing: 0) {
                                        HStack {
                                            Text("kVideoPlayerControlsSettingsOptions".localized())
                                                .font(.system(size: 16, weight: .regular, design: .default))
                                        }
                                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                                        .padding(.horizontal, 20)
                                        RoundedRectangle(cornerRadius: .infinity)
                                            .fill(Color.background)
                                            .frame(height: 1)
                                            .padding(.horizontal, 20)
                                        HStack {
                                            Text("kAudioPlayerControlsSettingsOptions".localized())
                                                .font(.system(size: 16, weight: .regular, design: .default))
                                        }
                                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                                        .padding(.horizontal, 20)
                                    }
                                }
                                .frame(height: 120)
                            Text("kGeneral".localized())
                                .foregroundStyle(.gray)
                                .font(.system(size: 13, weight: .light, design: .default))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, 10)
                            VStack(spacing: 0) {
                                NavigationLink {
                                    AppLanguageView()
                                        .environmentObject(languageManager)
                                } label: {
                                    HStack {
                                        Text("kAppLanguages".localized())
                                            .font(.system(size: 16, weight: .regular, design: .default))
                                    }
                                    .frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
                                    .padding(.horizontal, 20)
                                }

//                                RoundedRectangle(cornerRadius: .infinity)
//                                    .fill(Color.background)
//                                    .frame(height: 2)
//                                    .padding(.horizontal, 20)
                            }
                            .background(Color("202020"))
                            .foregroundStyle(.white)
                            .cornerRadius(15)
                        }
                        .padding(.horizontal, 15)
                    }
                }
            }
            .navigationBarBackButtonHidden()
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .regular, design: .default))
                            .frame(width: 35, height: 35)
                            .foregroundStyle(.white)
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text("kSettings".localized())
                        .font(.system(size: 20, weight: .bold, design: .default))
                }
            })
    }
}

#Preview {
    SettingsView()
}
