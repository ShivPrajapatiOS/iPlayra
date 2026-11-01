//
//  HistoryVideoPlaybackView.swift
//  iPlay
//
//  Created by Shiv on 17/11/25.
//

import SwiftUI

struct HistoryVideoPlaybackView: View {
    var body: some View {
        ZStack {
            ScrollView(.vertical) {
                LazyVStack(spacing: 15) {
                    ForEach(1...100, id: \.self) { index in
                        NavigationLink {
                            Text("Player View")
                        } label: {
                            GeometryReader { proxy in
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(.gray.opacity(0.25))
                            }
                            .frame(height: 85)
                        }

                    }
                }
                .padding(15)
            }
        }
        .navigationTitle("History".localized())
    }
}

#Preview {
    HistoryVideoPlaybackView()
}
