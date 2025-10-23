
//
//  WelcomeView.swift
//  PDFRedactor
//
//  Created by Владислав Скриганюк on 21.10.2025.
//


import SwiftUI

struct WelcomeView: View {
    
    var body: some View {
        VStack(spacing: 20) {
            Text("PDF Editor").font(.largeTitle).bold()
            
            Text("Загружайте фото, создавайте PDF, объединяйте и делитесь документами.")
                .multilineTextAlignment(.center)
            
            NavigationLink("Создать документ", destination: CreatePDFView())
                .buttonStyle(.borderedProminent)
            
            NavigationLink("Сохраненные документы", destination: SavedListView())
            
            Spacer()
        }
        .padding()
    }
}


