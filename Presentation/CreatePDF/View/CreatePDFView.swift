
//
//  CreatePDFView.swift
//  PDFRedactor
//
//  Created by Владислав Скриганюк on 21.10.2025.
//

import SwiftUI
import PhotosUI
import PDFKit
import UniformTypeIdentifiers


struct CreatePDFView: View {

    @StateObject var vm = CreatePDFViewModel()

    @State private var showPicker = false
    @State private var showDocumentPicker = false
    @State private var showShareSheet = false
    @State private var shareURL: URL? = nil

    @State private var showToast = false
    @State private var toastText = ""

    var body: some View {
        ZStack(alignment: .bottom) {
            Form {
                
                /// Название
                Section(header: Text("Название")) {
                    TextField("Название документа", text: $vm.name)
                }

                /// Страницы
                Section(header: Text("Страницы")) {
                    if vm.pages.isEmpty {
                        /// Placeholder
                        VStack(spacing: 12) {
                            Image(systemName: "doc.richtext")
                                .font(.system(size: 36))
                                .foregroundColor(.secondary)
                            Text("Страницы не добавлены")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("Добавьте из галереи или из Файлов")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.secondary.opacity(0.08))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.secondary.opacity(0.15))
                        )
                        .padding(.horizontal)
                    } else {
                        /// стабильное удаление из любого места
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: 16) {
                                ForEach(vm.pages, id: \.id) { page in
                                    let id = page.id /// вот тут - фиксируем id до мутации

                                    ZStack(alignment: .topTrailing) {
                                        Image(uiImage: page.image)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 120, height: 160)
                                            .clipped()
                                            .cornerRadius(8)
                                            .contentShape(Rectangle())

                                        /// Кнопка удаления с расширенной hit-area
                                        Button {
                                            withAnimation(.easeInOut) {
                                                vm.remove(id: id)
                                            }
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.title3)
                                                .symbolRenderingMode(.hierarchical)
                                                .foregroundColor(.white)
                                                .shadow(radius: 2)
                                                .padding(8)
                                                .background(Color.black.opacity(0.001))
                                                .clipShape(Circle())
                                        }
                                        .buttonStyle(.plain)
                                        .contentShape(Rectangle())
                                        .zIndex(2)
                                        .padding(6)
                                    }
                                    .contentShape(Rectangle())
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                        }
                        .animation(.default, value: vm.pages)
                    }

                    /// Кнопки добавления — добавляю только иконки
                    HStack(spacing: 20) {
                        Button { showPicker = true } label: {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 22, weight: .medium))
                                .frame(width: 60, height: 60)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                        .clipShape(Circle())

                        Button { showDocumentPicker = true } label: {
                            Image(systemName: "doc")
                                .font(.system(size: 22, weight: .medium))
                                .frame(width: 60, height: 60)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                        .clipShape(Circle())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }

                // MARK: - Genaration and action.
                
                Section {
                    Button("Сгенерировать PDF") { vm.generatePDF() }
                        .disabled(!vm.canGenerate) /// будет активна только при валидных данных

                    if let data = vm.generatedPDFData {
                        NavigationLink(
                            "Открыть PDF",
                            destination: PDFReaderView(data: data) { newData in
                                vm.generatedPDFData = newData
                            }
                        )

                        Button("Сохранить") {
                            do {
                                try vm.saveGeneratedPDF()
                                toastText = "Документ сохранён"
                                showToast = true
                            } catch {
                                toastText = "Ошибка сохранения"
                                showToast = true
                                print("Save error:", error)
                            }
                        }

                        Button("Поделиться") {
                            let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(vm.name + ".pdf")
                            try? data.write(to: tmp)
                            shareURL = tmp
                            showShareSheet = true
                        }
                    }
                }
            }
            .navigationTitle("Создание PDF")
            .sheet(isPresented: $showPicker) {
                PhotoPicker(configuration: photoPickerConfig()) { items in
                    handlePickedResults(items: items)
                }
            }
            .sheet(isPresented: $showDocumentPicker) {
                DocumentPicker { urls in
                    handleDocumentPicker(urls: urls)
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = shareURL { ShareSheet(activityItems: [url]) }
            }

            /// Snackbar
            if showToast {
                ToastView(text: toastText)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                            withAnimation { showToast = false }
                        }
                    }
                    .padding(.bottom, 16)
            }
        }
    }

    // MARK: - Helpers.

    func photoPickerConfig() -> PHPickerConfiguration {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.selectionLimit = 0
        config.filter = .images
        return config
    }

    func handleDocumentPicker(urls: [URL]) {
        var newImages: [UIImage] = []
        for url in urls {
            let ext = url.pathExtension.lowercased()
            if ["png","jpg","jpeg","heic","tiff"].contains(ext),
               let data = try? Data(contentsOf: url),
               let img  = UIImage(data: data) {
                newImages.append(img)
            } else if ext == "pdf",
                      let data = try? Data(contentsOf: url),
                      let pdf  = PDFDocument(data: data) {
                for i in 0..<pdf.pageCount {
                    if let page = pdf.page(at: i) {
                        let box = page.bounds(for: .mediaBox)
                        let img = page.thumbnail(of: box.size, for: .mediaBox)
                        newImages.append(img)
                    }
                }
            }
        }
        vm.append(images: newImages)
    }

    func handlePickedResults(items: [PHPickerResult]) {
        var images: [UIImage] = []
        let group = DispatchGroup()

        for item in items where item.itemProvider.canLoadObject(ofClass: UIImage.self) {
            group.enter()
            item.itemProvider.loadObject(ofClass: UIImage.self) { object, error in
                if let img = object as? UIImage { images.append(img) }
                else if let error = error { print("Picker load error:", error) }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            vm.append(images: images)
        }
    }
}
