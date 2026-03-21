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

// MARK: - Main content

private struct EditorContentView: View {
    @Bindable var vm: EditorViewModel
    @State private var hasTriggeredAutoCamera = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                // Main content
                ScrollView {
                    VStack(spacing: 20) {
                        if vm.photoCount > 0 {
                            canvasSection
                                .padding(.horizontal)
                        } else {
                            emptyState
                                .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }

                // Floating add button (two-step)
                if vm.canAddMore && vm.photoCount > 0 {
                    addButton
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                }
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
            // Photo overlay (blur + actions)
            .overlay {
                if let photo = vm.selectedPhoto {
                    PhotoOverlayView(photo: photo, vm: vm)
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
            .onAppear {
                if !hasTriggeredAutoCamera && vm.shouldAutoOpenCamera {
                    hasTriggeredAutoCamera = true
                    vm.showCamera = true
                }
            }
        }
    }

    // MARK: - Canvas (tappable photos)

    @ViewBuilder
    private var canvasSection: some View {
        let side = min(UIScreen.main.bounds.width - 32, 380)
        if let preset = vm.currentPreset {
            ZStack {
                LayoutCanvasView(
                    photos: vm.layout?.orderedPhotos ?? [],
                    preset: preset,
                    dayKey: vm.layout?.dayKey
                )
                .frame(width: side, height: side)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(radius: 4)

                // Invisible tap targets over each photo slot
                GeometryReader { geo in
                    let bannerHeight = geo.size.height * 0.08
                    let canvasSize = CGSize(width: geo.size.width,
                                            height: geo.size.height - bannerHeight)

                    ForEach(Array(preset.slots.enumerated()), id: \.offset) { index, slot in
                        if index < (vm.layout?.orderedPhotos.count ?? 0) {
                            let rect = slot.cgRect(in: canvasSize)
                            let shifted = CGRect(x: rect.origin.x,
                                                 y: rect.origin.y + bannerHeight,
                                                 width: rect.width,
                                                 height: rect.height)

                            Color.clear
                                .contentShape(Rectangle())
                                .frame(width: shifted.width, height: shifted.height)
                                .position(x: shifted.midX, y: shifted.midY)
                                .onTapGesture {
                                    let photos = vm.layout?.orderedPhotos ?? []
                                    if index < photos.count {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            vm.selectedPhoto = photos[index]
                                        }
                                    }
                                }
                        }
                    }
                }
                .frame(width: side, height: side)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Floating add button (two-step)

    private var addButton: some View {
        VStack(spacing: 12) {
            // Expanded options
            if vm.showAddMenu {
                VStack(spacing: 8) {
                    Button {
                        vm.showAddMenu = false
                        vm.showCamera = true
                    } label: {
                        Image(systemName: "camera.fill")
                            .font(.title3)
                            .frame(width: 50, height: 50)
                            .background(.thinMaterial, in: Circle())
                            .shadow(radius: 4)
                    }

                    PhotosPicker(
                        selection: $vm.pickerItems,
                        maxSelectionCount: 8 - vm.photoCount,
                        matching: .images
                    ) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.title3)
                            .frame(width: 50, height: 50)
                            .background(.thinMaterial, in: Circle())
                            .shadow(radius: 4)
                    }
                    .onChange(of: vm.pickerItems) { _, _ in
                        vm.showAddMenu = false
                    }
                }
                .transition(.scale.combined(with: .opacity))
            }

            // Main + button
            Button {
                withAnimation(.spring(duration: 0.25)) {
                    vm.showAddMenu.toggle()
                }
            } label: {
                Image(systemName: vm.showAddMenu ? "xmark" : "plus")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(Color.accentColor, in: Circle())
                    .shadow(color: .black.opacity(0.25), radius: 8, y: 4)
                    .rotationEffect(.degrees(vm.showAddMenu ? 45 : 0))
            }
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 0) {
            Spacer()

            // Illustration area
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.08))
                    .frame(width: 160, height: 160)

                Circle()
                    .fill(Color.accentColor.opacity(0.12))
                    .frame(width: 110, height: 110)

                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 44, weight: .light))
                    .foregroundStyle(Color.accentColor)
            }
            .padding(.bottom, 32)

            Text("Capture your meals")
                .font(.title2.weight(.semibold))
                .padding(.bottom, 8)

            Text("Snap a photo or choose from your library\nto build today's food layout.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.bottom, 36)

            // Action cards
            VStack(spacing: 12) {
                Button {
                    vm.showCamera = true
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "camera.fill")
                            .font(.title3)
                            .frame(width: 44, height: 44)
                            .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Take a Photo")
                                .font(.subheadline.weight(.semibold))
                            Text("Open camera to capture now")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(14)
                    .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)

                PhotosPicker(
                    selection: $vm.pickerItems,
                    maxSelectionCount: 8,
                    matching: .images
                ) {
                    HStack(spacing: 14) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.title3)
                            .frame(width: 44, height: 44)
                            .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(.orange)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Choose from Library")
                                .font(.subheadline.weight(.semibold))
                            Text("Pick existing photos")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(14)
                    .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
            }

            Spacer()
            Spacer()
        }
    }
}

// MARK: - Photo overlay (Instagram/Snap style)

private struct PhotoOverlayView: View {
    let photo: PhotoItem
    @Bindable var vm: EditorViewModel

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f
    }()

    var body: some View {
        ZStack {
            // Blurred background
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        vm.selectedPhoto = nil
                    }
                }

            VStack(spacing: 24) {
                // Selected photo large
                if let img = photo.uiImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(radius: 12)
                        .padding(.horizontal, 40)
                }

                // Time label
                Text(Self.timeFormatter.string(from: photo.capturedAt))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.8))

                // Action buttons
                HStack(spacing: 32) {
                    Button(role: .destructive) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            vm.removePhoto(photo)
                        }
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: "trash.fill")
                                .font(.title2)
                            Text("Delete")
                                .font(.caption)
                        }
                        .foregroundStyle(.white)
                        .frame(width: 80, height: 70)
                        .background(Color.red.opacity(0.8), in: RoundedRectangle(cornerRadius: 12))
                    }

                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            vm.selectedPhoto = nil
                        }
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: "xmark")
                                .font(.title2)
                            Text("Cancel")
                                .font(.caption)
                        }
                        .foregroundStyle(.white)
                        .frame(width: 80, height: 70)
                        .background(Color(.systemGray).opacity(0.8), in: RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
        .transition(.opacity)
    }
}

