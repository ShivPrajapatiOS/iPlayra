//
//  AppLanguageView.swift
//  iPlay
//
//  Created by Shiv on 31/10/25.
//

import SwiftUI

struct AppLanguageView: View {
    @EnvironmentObject var languageManager: LocalizationManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .top) {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 10) {
                    ForEach(languageManager.availableLanguages.indices, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color("202020"))
                            .frame(height: 45)
                            .overlay {
                                HStack {
                                    Text(languageManager.availableLanguages[index].name)
                                        .font(.system(size: 16, weight: .regular, design: .default))
                                        .foregroundStyle(.white)
                                    Spacer()
                                    Image(systemName: languageManager.currentLanguage == languageManager.availableLanguages[index].code ?  "largecircle.fill.circle" : "circle")
                                        .foregroundStyle(.theme)
                                        .font(.system(size: 16, weight: .thin, design: .default))
                                }
                                .padding(.horizontal, 20)
                            }
                            .onTapGesture {
                                languageManager.currentLanguage = languageManager.availableLanguages[index].code
                            }
                    }
                }
                .padding(.all, 15)
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
                Text("kLanguage".localized())
                    .font(.system(size: 20, weight: .bold, design: .default))
            }
        })
    }
}

#Preview {
    AppLanguageView()
        .environmentObject(LocalizationManager.shared)
}
