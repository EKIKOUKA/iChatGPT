//
//  LoadingOverlayView.swift
//  iChatGPT
//
//  Created by 宇都宮　誠 on R 7/05/26.
//
import SwiftUI

struct LoadingOverlayView: View {
    var isLoading: Bool
    
    var body: some View {
        if isLoading {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .overlay(
                    ProgressView("ローディング中…")
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(10)
                )
        }
    }
}
