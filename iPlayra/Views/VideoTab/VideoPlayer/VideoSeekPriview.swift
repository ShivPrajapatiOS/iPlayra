//
//  VideoSeekPriview.swift
//  iPlay
//
//  Created by Shiv on 07/03/26.
//

import SwiftUI

struct VideoSeekPriview: View {
    @StateObject private var player: MediaPlayerManager = .shared
    
    @Binding var thumbOffset: CGFloat
    @Binding var showPreview: Bool
    
    let previewWidth: CGFloat = 120
    
    var body: some View {
        GeometryReader { outerGeometry in
            let totalWidth = outerGeometry.size.width
            
            ZStack(alignment: .topLeading) {
                if showPreview {
                    VStack(spacing: 5) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.black)
                            .frame(width: previewWidth, height: 70)
                            .overlay(content: {
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(.gray.opacity(0.25), lineWidth: 1)
                            })
                            .overlay {
                                if let img = player.previewImage {
                                    Image(uiImage: img)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: previewWidth, height: 70)
                                        .cornerRadius(8)
                                        .clipped()
                                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white, lineWidth: 2))
                                } else {
                                    // Loading Placeholder
                                    Rectangle()
                                        .fill(Color.gray)
                                        .frame(width: 160, height: 90)
                                        .cornerRadius(8)
                                }
                            }
                        
                        Image(systemName: "arrowtriangle.down.fill")
                            .font(.caption)
                            .offset(x: thumbOffset - clampedOffset(in: totalWidth))
                    }
                    .frame(width: previewWidth)
                    .offset(x: clampedOffset(in: totalWidth) - (previewWidth / 2))
                    .transition(.opacity)
                }
            }
        }
        .padding(.horizontal)
    }
    
    private func clampedOffset(in totalWidth: CGFloat) -> CGFloat {
        let halfPreview = previewWidth / 2
        return max(halfPreview, min(thumbOffset, totalWidth - halfPreview))
    }
}

#Preview {
    VideoSeekPriview(thumbOffset: .constant(0.5), showPreview: .constant(false))
}
