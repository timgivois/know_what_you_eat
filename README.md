# Know What You Eat

A minimal iOS app for building daily food photo collages. Add up to 8 photos throughout the day, pick a layout preset, and share a flat image.

## Requirements

- Xcode 15.3+
- iOS 17.0+ deployment target
- No external dependencies — pure SwiftUI + SwiftData

## How to run

```bash
open iOS/KnowWhatYouEat/KnowWhatYouEat.xcodeproj
```

Select a simulator (iPhone 15 or later recommended), then **⌘R** to build and run.

## How to run tests

**⌘U** in Xcode, or via CLI:

```bash
xcodebuild test \
  -project iOS/KnowWhatYouEat/KnowWhatYouEat.xcodeproj \
  -scheme KnowWhatYouEat \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest'
```

## Architecture

```
App/            Entry point + ModelContainer setup
Models/         SwiftData models (DailyLayout, PhotoItem)
ViewModels/     @Observable VMs (EditorViewModel, HistoryViewModel)
Views/
  Home/         Root TabView
  Editor/       Today's layout — add photos, pick preset, share
  History/      Past layouts grid + detail view
  Shared/       LayoutCanvasView, PresetPickerView, ShareSheet
Services/       LayoutStore (SwiftData CRUD), LayoutExportService (ImageRenderer)
Presets/        LayoutPreset definitions — 19 presets across 1–8 photos
```

## Features

| Feature | Detail |
|---|---|
| Add photos | PhotosPicker — up to 8 per day |
| Preset layouts | 19 presets, filtered to match current photo count |
| Persistent storage | SwiftData — survives app restarts |
| Export | Renders layout as 1080×1080 JPEG via ImageRenderer → system share sheet |
| History | All past days, tap to view or re-share |
| No auth | Fully local, single device |

## Layout presets

| Photos | Presets |
|---|---|
| 1 | Full Frame |
| 2 | Side by Side · Stacked |
| 3 | Left Focus · Row · Top Focus |
| 4 | 2×2 Grid · Left Focus · Strip |
| 5 | Top Focus · 2+3 Rows |
| 6 | 2×3 Grid · 3×2 Grid · Top Focus |
| 7 | 3+4 Rows · Left Focus |
| 8 | 4×2 Grid · 2×4 Grid · Magazine |
