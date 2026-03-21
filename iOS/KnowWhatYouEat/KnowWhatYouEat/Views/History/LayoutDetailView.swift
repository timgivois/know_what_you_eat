import SwiftUI

struct LayoutDetailView: View {
    let layout: DailyLayout

    @State private var showShareSheet = false
    @State private var shareImage: UIImage?
    @State private var isExporting = false

    private var preset: LayoutPreset? {
        LayoutPreset.all.first(where: { $0.id == layout.presetID })
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let preset {
                    LayoutCanvasView(
                        photos: layout.orderedPhotos,
                        preset: preset,
                        dayKey: layout.dayKey
                    )
                    .aspectRatio(1, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(radius: 6)
                    .padding(.horizontal)
                }

                photoTimestamps
            }
            .padding(.vertical)
        }
        .navigationTitle(layout.dayKey.formatted(date: .long, time: .omitted))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await exportAndShare() }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .disabled(isExporting)
            }
        }
        .overlay {
            if isExporting {
                ProgressView()
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let img = shareImage {
                ShareSheet(items: [img])
            }
        }
    }

    private var photoTimestamps: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Photos")
                .font(.headline)
                .padding(.horizontal)

            ForEach(layout.orderedPhotos) { photo in
                HStack {
                    if let img = photo.uiImage {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 48, height: 48)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    VStack(alignment: .leading) {
                        Text("Slot \(photo.order + 1)")
                            .font(.subheadline.weight(.medium))
                        Text(photo.capturedAt, style: .time)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.horizontal)
            }
        }
    }

    private func exportAndShare() async {
        isExporting = true
        shareImage = await LayoutExportService.render(layout: layout)
        isExporting = false
        if shareImage != nil { showShareSheet = true }
    }
}
