# Video Shorts Factory

A professional macOS application for batch-generating vertical Shorts from 4K videos using FFmpeg with hardware acceleration.

## Features

- **Batch Processing**: Process multiple 4K videos simultaneously with queue management
- **Hardware Acceleration**: Uses h264_videotoolbox for GPU-accelerated encoding
- **Smart Cropping**: Automatically crops and scales videos to vertical format (1080x1920)
- **Progress Tracking**: Real-time progress updates with accurate ETA calculation
- **Metadata Generation**: Creates companion .txt files with titles and hashtags
- **Disk Space Management**: Verifies available disk space before processing
- **Sleep Prevention**: Keeps Mac awake during rendering
- **Modern UI**: Clean SwiftUI interface with three-panel layout

## System Requirements

- macOS 13.0 Ventura or later
- FFmpeg binary (see installation instructions below)
- Sufficient disk space (minimum 5GB free)

## FFmpeg Installation

The app requires FFmpeg to process videos. You have three options:

### Option 1: Homebrew (Recommended for Development)

```bash
brew install ffmpeg
```

The app will automatically detect FFmpeg at `/opt/homebrew/bin/ffmpeg` or `/usr/local/bin/ffmpeg`.

### Option 2: Bundle FFmpeg with the App (For Distribution)

1. Download a static FFmpeg build:
   - From: https://evermeet.cx/ffmpeg/
   - Download `ffmpeg-7.1.zip` or later

2. Extract the `ffmpeg` binary

3. Add to Xcode project:
   - Open the Xcode project
   - Drag the `ffmpeg` binary into the `VideoShortsFactory/Resources` folder
   - In the dialog, check "Copy items if needed"
   - Ensure "VideoShortsFactory" target is selected

4. Verify in Build Phases:
   - Select the project in Xcode
   - Go to Target → VideoShortsFactory → Build Phases
   - Check that `ffmpeg` appears in "Copy Bundle Resources"

### Option 3: Use the Pre-copied Binary

If you already copied FFmpeg to `VideoShortsFactory/VideoShortsFactory/Resources/ffmpeg`, the app will automatically find and use it.

## Building the Project

1. Open `VideoShortsFactory.xcodeproj` in Xcode
2. Select your development team in Signing & Capabilities
3. Build and run (⌘R)

## Usage

1. **Add Videos**: Click "Add Videos" or drag video files into the source table
2. **Configure Settings**:
   - Set number of clips to generate per video (1-50)
   - Set clip duration (5-60 seconds)
   - Add a base title for your clips
   - Add hashtags for metadata files
3. **Select Output Folder**: Choose where to save generated clips
4. **Start Processing**: Click "Start Batch" to begin processing

## How It Works

### Video Processing Pipeline

1. **Random Selection**: For each clip, the app randomly selects a start time from the source video
2. **Cropping**: Applies center crop to convert 16:9 to 9:16 aspect ratio
3. **Scaling**: Scales to 1080x1920 (vertical HD)
4. **Encoding**: Uses h264_videotoolbox for hardware-accelerated encoding at 15Mbps
5. **Audio**: Preserves original audio without re-encoding
6. **Metadata**: Creates .txt files with titles and hashtags

### FFmpeg Command Template

```bash
ffmpeg -ss [RANDOM_START] -i [INPUT] -t [DURATION] \
  -vf "crop=ih*9/16:ih,scale=1080:1920" \
  -c:v h264_videotoolbox -b:v 15M \
  -c:a copy \
  [OUTPUT]
```

## Project Structure

```
VideoShortsFactory/
├── Models/
│   ├── VideoItem.swift              # Video item model
│   ├── ProcessingState.swift        # Processing state enum
│   └── ClipConfiguration.swift      # Configuration model
├── ViewModels/
│   └── VideoManager.swift           # Main processing coordinator
├── Views/
│   ├── ContentView.swift            # Main app layout
│   ├── SourceTableView.swift        # Video list table
│   ├── ConfigurationPanel.swift    # Settings panel
│   └── DashboardView.swift          # Control dashboard
├── Services/
│   ├── FFmpegService.swift          # FFmpeg command execution
│   ├── DiskSpaceChecker.swift       # Disk space validation
│   └── SleepPrevention.swift        # Sleep prevention
└── Resources/
    └── ffmpeg                        # FFmpeg binary (user-provided)
```

## Advanced Features

### Queue Management
- Sequential processing prevents thermal throttling
- Cancel processing at any time
- Automatic cleanup of partial files on cancellation

### Time Estimation
- Initial estimate based on 5x processing speed
- Refines estimate based on actual processing times
- Uses rolling average of last 5 clips for accuracy

### Disk Space Check
- Verifies minimum 5GB free space before starting
- Estimates required space based on clip settings
- Displays available vs. required space in UI

### Error Handling
- Validates video accessibility before processing
- Handles FFmpeg errors gracefully
- Provides user-friendly error messages
- Logs detailed errors to console

## Troubleshooting

### FFmpeg Not Found

If you see "FFmpeg Not Found" warning:
1. Install FFmpeg via Homebrew: `brew install ffmpeg`
2. Or bundle FFmpeg with the app (see instructions above)
3. Restart the application

### Processing Fails

- Ensure video file is accessible and not corrupted
- Check that video is longer than requested clip duration
- Verify sufficient disk space in output folder
- Check Console.app for detailed error messages

### Slow Processing

- Processing speed depends on video codec and resolution
- Hardware acceleration requires compatible GPU
- Sequential processing prevents overheating but takes longer

## Entitlements

The app requires these entitlements:
- `com.apple.security.app-sandbox` - App sandboxing
- `com.apple.security.files.user-selected.read-write` - File access
- `com.apple.security.files.bookmarks.app-scope` - Bookmark persistence

## License

Copyright © 2026. All rights reserved.

## Support

For issues or questions, please check the FFmpeg installation and verify your system meets the requirements.
