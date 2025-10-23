
//
//  MergeSelectionView.swift
//  PDFRedactor
//
//  Created by Владислав Скриганюк on 21.10.2025.
//


import SwiftUI

struct MergeNameSheet: View {

    let defaultName: String
    @Binding var name: String
    var onCancel: () -> Void
    var onSave: (String) -> Void

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Имя нового документа")
                    .font(.callout)
                    .foregroundStyle(.secondary)

                TextField(defaultName, text: $name)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.words)
                    .submitLabel(.done)
                    .padding(.bottom, 8)

                Spacer()
            }
            .padding()
            .navigationTitle("Объединить PDF")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { onCancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        onSave(name.isEmpty ? defaultName : name)
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}


