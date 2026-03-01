# Quick Start Guide

## Opening the Project

1. Navigate to the project directory:
   ```bash
   cd /Users/jancermak/dev/video-shorts-factory/VideoShortsFactory
   ```

2. Open the Xcode project:
   ```bash
   open VideoShortsFactory.xcodeproj
   ```

## First Time Setup in Xcode

1. **Configure Signing**:
   - Select the project in the navigator
   - Select the "VideoShortsFactory" target
   - Go to "Signing & Capabilities" tab
   - Select your development team from the dropdown
   - Xcode will automatically manage signing

2. **Verify FFmpeg**:
   - In Project Navigator, expand `VideoShortsFactory` → `Resources`
   - Verify that `ffmpeg` binary is present (80.1 MB)
   - If not present, copy it: `cp ../ffmpeg/ffmpeg VideoShortsFactory/Resources/`

3. **Build and Run**:
   - Press ⌘R or click the Run button
   - The app should launch on your Mac

## Testing the App

1. **Add a test video**:
   - Click "Add Videos" button
   - Select any .mp4 or .mov file

2. **Configure settings**:
   - Set quantity: 3 clips (for quick test)
   - Set duration: 10 seconds
   - Add a title: "Test Short"
   - Add hashtags: "#test #shorts"

3. **Select output folder**:
   - Click "Select Output Folder"
   - Choose a folder with at least 5GB free space

4. **Process**:
   - Click "Start Batch"
   - Watch progress in real-time
   - Check output folder when complete

## Project Structure

```
VideoShortsFactory/
├── VideoShortsFactory.xcodeproj     # Xcode project
├── VideoShortsFactory/              # Source code
│   ├── Models/                      # Data models
│   ├── ViewModels/                  # Business logic
│   ├── Views/                       # SwiftUI views
│   ├── Services/                    # Core services
│   └── Resources/                   # FFmpeg binary
└── README.md                        # Documentation
```

## Key Files

- **VideoShortsFactoryApp.swift**: App entry point, verifies FFmpeg on launch
- **VideoManager.swift**: Coordinates processing queue, ETA, progress
- **FFmpegService.swift**: Executes FFmpeg commands, parses output
- **ContentView.swift**: Main UI with 3-panel layout
- **VideoItem.swift**: Represents a video with state and progress

## FFmpeg Binary Location

The FFmpeg binary is already copied to:
```
VideoShortsFactory/VideoShortsFactory/Resources/ffmpeg
```

When the app runs, it will:
1. First try to use bundled FFmpeg from Resources
2. Fall back to `/opt/homebrew/bin/ffmpeg`
3. Fall back to `/usr/local/bin/ffmpeg`
4. Show warning if none found

## Troubleshooting

### "Developer cannot be verified" error
```bash
xattr -cr VideoShortsFactory.app
```

### FFmpeg not executable
```bash
chmod +x VideoShortsFactory/VideoShortsFactory/Resources/ffmpeg
```

### Sandbox restrictions
For development, you may need to temporarily disable sandboxing:
- In Xcode: Target → Signing & Capabilities
- Remove "App Sandbox" capability (development only)

## Next Steps

1. Test with a sample video
2. Adjust settings as needed
3. Process multiple videos in batch
4. Check generated .txt metadata files
5. Archive the app for distribution (Product → Archive)

## Support

Check the main README.md for detailed documentation and troubleshooting.
