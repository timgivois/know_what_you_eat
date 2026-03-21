import SwiftUI
import PhotosUI

struct EditorView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var vm: EditorViewModel?

    var body: some View {
        Group {
            if let vm {
                EditorContentView(vm: vm)
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

private struct EditorContentView: View {
    @Bindable var vm: EditorViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Canvas
                canvasSection
                    .padding()

                Divider()

                // Preset picker (only when photos exist)
                if vm.photoCount > 0 {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Layout")
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal)
                            .padding(.top, 12)

                        PresetPickerView(
                            photoCount: vm.photoCount,
                            selectedPresetID: Binding(
                                get: { vm.selectedPresetID },
                                set: { vm.applyPreset($0) }
                            )
                        )
                        .padding(.bottom, 12)
                    }

                    Divider()
                }

                // Photo strip
                photoStrip
                    .padding(.vertical, 12)

                Spacer()
            }
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if vm.photoCount > 0 {
                        Button {
                            Task { await vm.prepareShare() }
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                        .disabled(vm.isLoading)
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
        }
    }

    // MARK: - Canvas

    @ViewBuilder
    private var canvasSection: some View {
        let side = min(UIScreen.main.bounds.width - 32, 360)
        Group {
            if vm.photoCount > 0, let preset = vm.currentPreset {
                LayoutCanvasView(
                    photos: vm.layout?.orderedPhotos ?? [],
                    preset: preset,
                    dayKey: vm.layout?.dayKey
                )
                .frame(width: side, height: side)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(radius: 4)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .frame(width: side, height: side)
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: "fork.knife.circle")
                                .font(.system(size: 48))
                                .foregroundStyle(.secondary)
                            Text("Add photos to start your layout")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                    )
            }
        }
    }

    // MARK: - Photo strip

    private var photoStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                // Existing photos
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

                // Add buttons
                if vm.canAddMore {
                    // Camera button
                    Button {
                        vm.showCamera = true
                    } label: {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray5))
                            .frame(width: 72, height: 72)
                            .overlay(
                                VStack(spacing: 4) {
                                    Image(systemName: "camera.fill")
                                        .font(.title2.weight(.semibold))
                                    Text("Camera")
                                        .font(.caption2)
                                }
                                .foregroundStyle(.secondary)
                            )
                    }

                    // Library picker
                    PhotosPicker(
                        selection: $vm.pickerItems,
                        maxSelectionCount: 8 - vm.photoCount,
                        matching: .images
                    ) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray5))
                            .frame(width: 72, height: 72)
                            .overlay(
                                VStack(spacing: 4) {
                                    Image(systemName: "photo.on.rectangle")
                                        .font(.title2.weight(.semibold))
                                    Text("\(vm.photoCount)/8")
                                        .font(.caption2)
                                }
                                .foregroundStyle(.secondary)
                            )
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}
