//
//  PurchaseView.swift
//  iPlay
//
//  Created by Shiv on 17/09/25.
//

import Foundation
import SwiftUI
import StoreKit

struct PurchaseView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var isShowPurchase: Bool
    @StateObject var purchaseManager = InAppPurchaseManager.shared
    @State private var selectedProduct: Product?
    @State private var isShowPrivacyPolicy: Bool = false
    @State private var isShowTermsAndConditions: Bool = false
    
    var body: some View {
        ZStack {
            Rectangle()
                .ignoresSafeArea()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay {
                    Image("ic_feel_music_girl")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .ignoresSafeArea()
                    LinearGradient(colors: [.black, .black, .black, .black, .black, .black.opacity(0.75), .black.opacity(0.5), .black.opacity(0.25), .black.opacity(0.125), .black.opacity(0.0625)], startPoint: .bottom, endPoint: .top)
                        .ignoresSafeArea()
                }
            VStack {
                HStack {
                    Button {
                        withAnimation {
                            if !isShowPurchase {
                                dismiss()
                            } else {
                                isShowPurchase.toggle()
                            }
                        }
                    } label: {
                        Image(systemName: isShowPurchase ?  "multiply" : "chevron.left")
                            .font(.system(size: 20, weight: .regular, design: .default))
                            .padding(.init(top: 10, leading: 0, bottom: 10, trailing: 10))
                            .foregroundStyle(.white.opacity(0.75))
                    }
                    Spacer()
                    Button {
                        Task {
                            await purchaseManager.restorePurchases()
                        }
                    } label: {
                        Text("Restore")
                            .font(.system(size: 16, weight: .regular, design: .default))
                            .padding(.init(top: 10, leading: 0, bottom: 10, trailing: 10))
                            .foregroundStyle(.white)
                    }

                }
                .frame(maxHeight: 50)
                .padding(.horizontal, 20)
                Spacer()
                VStack(alignment: .leading) {
                    HStack {
                        Image(systemName: "checkmark.square.fill")
                            .font(.system(size: 25, weight: .light, design: .default))
                            .foregroundStyle(.theme)
                        Text("No Ads")
                            .font(.system(size: 20, weight: .medium, design: .default))
                            .foregroundStyle(.white)
                    }
                    
                    HStack {
                        Image(systemName: "checkmark.square.fill")
                            .font(.system(size: 25, weight: .light, design: .default))
                            .foregroundStyle(.theme)
                        Text("Offline Mode")
                            .font(.system(size: 20, weight: .medium, design: .default))
                            .foregroundStyle(.white)
                    }
                    
                    HStack {
                        Image(systemName: "checkmark.square.fill")
                            .font(.system(size: 25, weight: .light, design: .default))
                            .foregroundStyle(.theme)
                        Text("Equalizer")
                            .font(.system(size: 20, weight: .medium, design: .default))
                            .foregroundStyle(.white)
                    }
                    
                    HStack {
                        Image(systemName: "checkmark.square.fill")
                            .font(.system(size: 25, weight: .light, design: .default))
                            .foregroundStyle(.theme)
                        Text("High Quality Video")
                            .font(.system(size: 20, weight: .medium, design: .default))
                            .foregroundStyle(.white)
                    }
                }
                .frame(maxHeight: .infinity)
                HStack {
                    ForEach(purchaseManager.availableProducts, id: \.id) { plan in
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.gray.opacity(0.25))
                            .stroke(LinearGradient(colors: selectedProduct == plan ? [.orange, .yellow] : [.clear], startPoint: .bottomLeading, endPoint: .topTrailing), lineWidth: 2.5)
                            .overlay {
                                ZStack {
                                    VStack {
                                        Text(plan.displayName)
                                            .font(.system(size: 16, weight: .semibold, design: .default))
                                        Spacer()
                                        VStack {
                                            Text("\(plan.price)")
                                                .font(.system(size: 20, weight: .black, design: .default))
                                            Text(plan.description)
                                                .font(.system(size: 12, weight: .light, design: .default))
                                        }
                                        Spacer()
                                    }
                                    .foregroundStyle(.white)
                                }
                                .padding(10)
                            }
                            .onTapGesture {
                                withAnimation {
                                    self.selectedProduct = plan
                                }
                            }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: (UIScreen.main.bounds.width - 20) / 3)
                .padding(10)
                VStack(spacing: 10) {
                    Button {
                        guard let selectedProduct = selectedProduct else { return }
                        Task {
                            let isSuccess = await purchaseManager.purchase(selectedProduct)
                            if isSuccess {
                                dismiss()
                            }
                        }
                    } label: {
                        RoundedRectangle(cornerRadius: .infinity)
                            .fill(LinearGradient(colors: [.theme, .blue], startPoint: .bottomLeading, endPoint: .topTrailing))
                            .frame(maxWidth: .infinity, maxHeight: 50)
                            .overlay {
                                Text("Purchase Now")
                                    .font(.system(size: 18, weight: .semibold, design: .default))
                                    .foregroundStyle(.white)
                            }
                    }
                    .buttonStyle(.plain)
                    .disabled(selectedProduct != nil ? false : true)
                    HStack(spacing: 10) {
                        Button {
                            withAnimation {
                                isShowPrivacyPolicy.toggle()
                            }
                        } label: {
                            Text("Privacy Policy")
                                .font(.system(size: 14, weight: .regular, design: .default))
                        }
                        Button {
                            isShowTermsAndConditions.toggle()
                        } label: {
                            Text("Terms & Conditions")
                                .font(.system(size: 14, weight: .regular, design: .default))
                        }
                    }
                    .frame(height: 35)
                    .foregroundStyle(.white)
                }
                .padding(20)

            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        .toolbar(.hidden, for: .tabBar)
        .navigationBarBackButtonHidden(true)
        .fullScreenCover(isPresented: $isShowPrivacyPolicy) {
            WebPageView(isShowBottmSheet: .constant(true), isShowPrivacyPolicy: $isShowPrivacyPolicy, pageName: "PrivacyPolicy")
            .presentationBackground(.clear)
        }
        .fullScreenCover(isPresented: $isShowTermsAndConditions) {
            WebPageView(isShowBottmSheet: .constant(true), isShowPrivacyPolicy: $isShowTermsAndConditions, pageName: "TermsAndConditions")
            .presentationBackground(.clear)
        }
    }
}


#Preview {
    PurchaseView(isShowPurchase: .constant(false))
        .environmentObject(InAppPurchaseManager.shared)
}
