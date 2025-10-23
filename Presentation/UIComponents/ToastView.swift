//
//  ToastView.swift
//  SwiftUIPDFProject
//
//  Created by Владислав Скриганюк on 21.10.2025.
//

import SwiftUI

struct ToastView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.subheadline)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .shadow(radius: 3)
            .padding(.horizontal, 24)
    }
}
