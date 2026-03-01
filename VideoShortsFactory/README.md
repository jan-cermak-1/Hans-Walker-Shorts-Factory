# Video Shorts Factory

A professional macOS application for batch-generating vertical Shorts from 4K videos using FFmpeg with hardware acceleration.

## Features

- **Wizard-style UI**: Compact single-panel layout with numbered steps
- **Batch Processing**: Process multiple 4K videos with queue management
- **Hardware Acceleration**: Uses h264_videotoolbox for GPU-accelerated encoding
- **Smart Cropping**: Automatically crops and scales videos to vertical format (1080x1920)
- **Progress Tracking**: Real-time progress updates with accurate ETA calculation
- **Metadata Generation**: Creates companion .txt files with titles and hashtags
- **Settings Persistence**: Remembers clip settings and output folder between sessions
- **Dark Mode**: Fully supports macOS light and dark appearance
- **Disk Space Management**: Verifies available disk space before processing
- **Sleep Prevention**: Keeps Mac awake during rendering

## System Requirements

- macOS 13.0 Ventura or later
- FFmpeg binary (see installation instructions below)
- Sufficient disk space (minimum 5GB free)

## FFmpeg Installation

The app requires FFmpeg to process videos. You have two options:

### Option 1: Homebrew (Recommended)

```bash
brew install ffmpeg
```

### Option 2: Bundle FFmpeg with the App

1. Download a static FFmpeg build from https://evermeet.cx/ffmpeg/
2. Add the `ffmpeg` binary to `VideoShortsFactory/Resources/` in Xcode

## Building

1. Open `VideoShortsFactory.xcodeproj` in Xcode
2. Select your development team in Signing & Capabilities
3. Build and run (Cmd+R)

## Usage

The app follows a 4-step wizard workflow:

1. **Add Videos** -- Click "Add Videos" or use Cmd+O to select source files
2. **Configure** -- Set clip quantity (1-50), duration (5-60s), title, and hashtags
3. **Output** -- Choose destination folder (remembered between sessions)
4. **Process** -- Click "Start Batch" to generate clips

After processing completes, you can open the output folder or start a new batch.

## Project Structure

```
VideoShortsFactory/
├── Models/
│   ├── VideoItem.swift              # Video item model
│   ├── ProcessingState.swift        # Processing state enum
│   └── ClipConfiguration.swift      # Configuration model
├── ViewModels/
│   └── VideoManager.swift           # Main processing coordinator + persistence
├── Views/
│   └── ContentView.swift            # Wizard layout with all 4 sections
├── Services/
│   ├── FFmpegService.swift          # FFmpeg command execution
│   ├── VideoMetadataLoader.swift    # AVFoundation metadata loading
│   ├── DiskSpaceChecker.swift       # Disk space validation
│   └── SleepPrevention.swift        # Sleep prevention
└── Resources/
    └── ffmpeg                        # FFmpeg binary (user-provided)
```

## License

Copyright 2026. All rights reserved.
