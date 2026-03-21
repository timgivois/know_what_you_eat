import SwiftUI
import PhotosUI

struct EditorView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var vm: EditorViewModel?
    var onSaved: (() -> Void)?

    var body: some View {
        Group {
            if let vm {
                EditorContentView(vm: vm, onSaved: onSaved)
            } else {
                ProgressView()
            }
        }
        .onAppear {
            if vm == nil {
                let store = LayoutStore(context: modelContext)
                let newVM = EditorViewModel(store: store)
                newVM.loadOrCreateTodayLayout()
                vm = newVM
            }
        }
    }
}

// MARK: - Main content

private struct EditorContentView: View {
    @Bindable var vm: EditorViewModel
    var onSaved: (() -> Void)?
    @State private var hasTriggeredAutoCamera = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if vm.photoCount > 0 {
                        // Layout canvas
                        canvasSection
                            .padding(.horizontal)

                        // Add-more card with camera + library icons
                        if vm.canAddMore {
                            addMoreCard
                                .padding(.horizontal)
                        }

                        // Photo strip for removing individual photos
                        photoStrip

                        // Save button
                        saveButton
                            .padding(.horizontal)
                    } else {
                        emptyState
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if vm.photoCount > 0 {
                        HStack(spacing: 16) {
                            Button {
                                vm.showLayoutSettings = true
                            } label: {
                                Image(systemName: "slider.horizontal.3")
                            }

                            Button {
                                Task { await vm.prepareShare() }
                            } label: {
                                Image(systemName: "square.and.arrow.up")
                            }
                            .disabled(vm.isLoading)
                        }
                    }
                }
            }
            .overlay {
                if vm.isLoading {
                    ProgressView()
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .sheet(isPresented: $vm.showShareSheet) {
                if let img = vm.shareImage {
                    ShareSheet(items: [img])
                }
            }
            .sheet(isPresented: $vm.showLayoutSettings) {
                LayoutSettingsView(vm: vm)
            }
            .alert("Error", isPresented: .constant(vm.errorMessage != nil)) {
                Button("OK") { vm.errorMessage = nil }
            } message: {
                Text(vm.errorMessage ?? "")
            }
            .fullScreenCover(isPresented: $vm.showCamera) {
                CameraView { image in
                    vm.addCameraPhoto(image)
                }
                .ignoresSafeArea()
            }
            .onChange(of: vm.pickerItems) { _, newItems in
                Task { await vm.loadPhotos(from: newItems) }
            }
            .onChange(of: vm.didSave) { _, saved in
                if saved { onSaved?() }
            }
            .onAppear {
                if !hasTriggeredAutoCamera && vm.shouldAutoOpenCamera {
                    hasTriggeredAutoCamera = true
                    vm.showCamera = true
                }
            }
        }
    }

    // MARK: - Canvas

    @ViewBuilder
    private var canvasSection: some View {
        let side = min(UIScreen.main.bounds.width - 32, 380)
        if let preset = vm.currentPreset {
            LayoutCanvasView(
                photos: vm.layout?.orderedPhotos ?? [],
                preset: preset,
                dayKey: vm.layout?.dayKey
            )
            .frame(width: side, height: side)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(radius: 4)
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Add more card

    private var addMoreCard: some View {
        HStack(spacing: 0) {
            // Camera
            Button {
                vm.showCamera = true
            } label: {
                VStack(spacing: 6) {
                    Image(systemName: "camera.fill")
                        .font(.title2)
                    Text("Camera")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity, minHeight: 72)
                .foregroundStyle(.primary)
            }

            Divider()
                .frame(height: 48)

            // Photo library
            PhotosPicker(
                selection: $vm.pickerItems,
                maxSelectionCount: 8 - vm.photoCount,
                matching: .images
            ) {
                VStack(spacing: 6) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.title2)
                    Text("Library")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity, minHeight: 72)
                .foregroundStyle(.primary)
            }
        }
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Photo strip

    private var photoStrip: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Photos (\(vm.photoCount)/8)")
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(vm.layout?.orderedPhotos ?? []) { photo in
                        if let img = photo.uiImage {
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 72, height: 72)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))

                                Button {
                                    vm.removePhoto(photo)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .symbolRenderingMode(.palette)
                                        .foregroundStyle(.white, .black.opacity(0.6))
                                        .font(.system(size: 18))
                                }
                                .offset(x: 6, y: -6)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Save button

    private var saveButton: some View {
        Button {
            vm.commitLayout()
        } label: {
            Label("Save Layout", systemImage: "checkmark.circle.fill")
                .font(.headline)
                .frame(maxWidth: .infinity, minHeight: 50)
        }
        .buttonStyle(.borderedProminent)
        .disabled(vm.photoCount == 0)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 40)

            Image(systemName: "fork.knife.circle")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text("What did you eat today?")
                .font(.title3.weight(.medium))

            Text("Take a photo or pick one from your library to start today's layout.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 16) {
                Button {
                    vm.showCamera = true
                } label: {
                    Label("Camera", systemImage: "camera.fill")
                        .frame(maxWidth: .infinity, minHeight: 50)
                }
                .buttonStyle(.borderedProminent)

                PhotosPicker(
                    selection: $vm.pickerItems,
                    maxSelectionCount: 8,
                    matching: .images
                ) {
                    Label("Library", systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity, minHeight: 50)
                }
                .buttonStyle(.bordered)
            }

            Spacer()
        }
    }
}
