
//
//  PDFReaderView.swift
//  PDFRedactor
//
//  Created by Владислав Скриганюк on 21.10.2025.
//


import SwiftUI
import PDFKit

struct PDFReaderView: View {
    @StateObject private var vm: PDFReaderVM

    /// Открываем созраненный документ из списка
    init(model: PDFDocumentModel) {
        _vm = StateObject(wrappedValue: PDFReaderVM(savedModel: model))
    }

    /// Открываем временный документы из конструктора
    init(data: Data, onUpdate: ((Data) -> Void)? = nil) {
        _vm = StateObject(wrappedValue: PDFReaderVM(ephemeralData: data, onUpdate: onUpdate))
    }

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(vm.pageImages.indices, id: \.self) { idx in
                        Image(uiImage: vm.pageImages[idx])
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .overlay(selectionOverlay(isSelected: vm.selectedIndex == idx))
                            .padding(.horizontal, 16)
                            .onTapGesture { vm.select(idx) }
                    }
                }
                .padding(.top, 12)
                .onAppear { vm.renderIfNeeded(width: geo.size.width - 32) }
                .onChange(of: geo.size.width) { vm.renderIfNeeded(width: $0 - 32) }
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 8) {
                    Button(role: .destructive) {
                        _ = vm.deleteSelectedPage()  /// UI обновится сразу
                    } label: {
                        Text("Удалить выбранную страницу")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(vm.selectedIndex == nil)

                    Text(vm.selectedIndex == nil
                         ? "Нажмите на страницу, чтобы выбрать её"
                         : "Выбрана страница №\((vm.selectedIndex ?? 0) + 1)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func selectionOverlay(isSelected: Bool) -> some View {
        RoundedRectangle(cornerRadius: 8)
            .stroke(isSelected ? Color.accentColor : .clear, lineWidth: 3)
            .shadow(color: isSelected ? Color.accentColor.opacity(0.25) : .clear, radius: 6)
    }
}
