//
//  ToastView.swift
//  Nower
//
//  Created by 신종원 on 3/29/25.
//

import SwiftUI

struct ToastView: View {
    var message: String

    var body: some View {
        Text(message)
            .padding()
            .background(AppColors.black.opacity(0.7))
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding(.bottom, 30)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .zIndex(1)
    }
}
