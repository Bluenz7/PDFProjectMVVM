
//
//  DocumentListView.swift
//  PDFRedactor
//
//  Created by Владислав Скриганюк on 21.10.2025.
//
import SwiftUI

struct SavedListView: View {
    @StateObject private var vm = DocumentListViewModel()
    @State private var showNameSheet = false

    var body: some View {
        List {
            if vm.isMergingMode, let src = vm.mergingSource {
                Section {
                    Label("Выберите второй документ для объединения с «\(src.name)»",
                          systemImage: "arrow.left.arrow.right.circle.fill")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }

            ForEach(vm.documents, id: \.id) { doc in
                Group {
                    if vm.isMergingMode {
                        row(for: doc)
                            .contentShape(Rectangle())
                            .onTapGesture { selectForMerge(doc) }
                    } else {
                        NavigationLink(
                            destination: PDFReaderView(model: doc)
                        ) {
                            row(for: doc)
                        }
                    }
                }
                .contextMenu {
                    Button { share(doc) } label: {
                        Label("Поделиться", systemImage: "square.and.arrow.up")
                    }
                    Button(role: .destructive) { vm.delete(doc) } label: {
                        Label("Удалить", systemImage: "trash")
                    }
                    Button("Объединить") { vm.startMerge(source: doc) }
                }
            }
        }
        .sheet(isPresented: $showNameSheet) {
            MergeNameSheet(
                defaultName: vm.newName,
                name: $vm.newName,
                onCancel: {
                    vm.cancelMerge()
                    showNameSheet = false
                },
                onSave: { _ in
                    let ok = vm.performMerge()
                    if ok { showNameSheet = false }
                }
            )
            .applyDetentsIfAvailable()
        }
        /// toolbar: используем placements, которые доступны на iOS 15
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarLeading) {
                if vm.isMergingMode {
                    Button("Отмена") { vm.cancelMerge() }
                }
            }
        }
        .navigationTitle("Сохраненные PDF")
    }

    // MARK: - Row UI.

    @ViewBuilder
    private func row(for doc: PDFDocumentModel) -> some View {
        HStack {
            if let data = doc.thumbnail, let ui = UIImage(data: data) {
                Image(uiImage: ui)
                    .resizable()
                    .frame(width: 54, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 54, height: 72)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(doc.name).font(.headline)
                Text(doc.fileExtension ?? "pdf")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(vm.formattedDate(doc.timestamp))
                .font(.caption)
                .foregroundStyle(.secondary)

            if vm.isMergingMode { mergeIndicator(for: doc) }
        }
        .opacity(vm.isMergingMode && vm.mergingSource?.id == doc.id ? 0.86 : 1)
    }

    private func mergeIndicator(for doc: PDFDocumentModel) -> some View {
        Group {
            if vm.mergingSource?.id == doc.id {
                Image(systemName: "1.circle.fill").foregroundStyle(.secondary)
            } else if vm.mergeTarget?.id == doc.id {
                Image(systemName: "checkmark.circle.fill")
            } else {
                Image(systemName: "circle.dashed").foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Actions Methods.

    private func selectForMerge(_ doc: PDFDocumentModel) {
        guard vm.isMergingMode else { return }
        vm.selectTarget(doc)
        showNameSheet = true
    }

    private func share(_ doc: PDFDocumentModel) {
        guard let url = vm.shareURL(for: doc) else { return }
        DispatchQueue.main.async {
            let av = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = scene.windows.first,
               let root = window.rootViewController {
                root.present(av, animated: true)
            }
        }
    }
}

// MARK: - iOS15 Helper for PresentationDetents.

private extension View {
    @ViewBuilder
    func applyDetentsIfAvailable() -> some View {
        if #available(iOS 16.0, *) {
            self.presentationDetents([.height(180), .medium])
        } else {
            self
        }
    }
}
