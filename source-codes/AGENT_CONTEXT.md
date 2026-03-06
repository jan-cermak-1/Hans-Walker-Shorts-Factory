# Agent Context - Hans Walker Shorts Factory v1.1

## Project Overview

**Application Name:** Hans Walker - Shorts Factory  
**Platform:** macOS native application (SwiftUI + AppKit)  
**Current Version:** v1.1 (UI redesign with Hans Walker branding)  
**Purpose:** Batch video processing tool that converts long walking videos into multiple short clips (YouTube Shorts format)

## Project History & Current State

### Version Timeline

- **v0.9** - Stable working version with basic 3-column layout
- **v1.0** - UI redesign to wizard-style single panel layout with persistence
- **v1.1** - Current version: Hans Walker brand alignment (in progress)

### Critical Context: Why We're at v1.1

The user experienced application freezing issues after jumping directly to v2.0 (which included parallel processing). We rolled back to v0.9 and decided to proceed incrementally, testing each version thoroughly before moving forward.

**Current approach:** Only implement UI changes, NO advanced concurrency features yet.

## Application Architecture

### Core Technology Stack

- **SwiftUI** - Main UI framework
- **AppKit** - File dialogs (NSOpenPanel), system integration
- **AVFoundation** - Video metadata (duration, dimensions)
- **FFmpeg** - External binary for video processing (included in bundle)
- **UserDefaults** - Settings persistence

### Key Files & Their Roles

#### Models
- `VideoItem.swift` - Represents a source video with metadata
- `ProcessingState.swift` - Enum for video processing states
- `ClipConfiguration.swift` - Per-video clip settings (quantity, duration, title, hashtags)

#### ViewModels
- `VideoManager.swift` - Main state manager (@ObservableObject)
  - Manages video list, processing state, batch completion
  - Handles sequential processing (NOT parallel - v2.0 feature)
  - Persists settings via UserDefaults
  - Manages output folder with security-scoped bookmarks

#### Views
- `ContentView.swift` - Main application view
  - Wizard-style layout with numbered cards (1. Source Videos, 2. Clip Settings, 3. Output)
  - Uses SF Symbols for icons (NOT emoji)
  - ScrollView for main content
- `HeaderView.swift` - Custom app header
  - Hans Walker logo (PNG image)
  - "SHORTS FACTORY" title in Krona One font
- `FooterView.swift` - Dynamic footer
  - Shows different content based on state (Start button / Progress / Completion)
  - Always includes YouTube link
- `HansWalkerButton.swift` - Custom 3D button component
  - Main button with green 3D press effect
  - Secondary button for completion actions

#### Services
- `FFmpegService.swift` - Handles FFmpeg execution
- `VideoMetadataLoader.swift` - Loads video metadata asynchronously
- `DiskSpaceChecker.swift` - Checks available disk space
- `SleepPrevention.swift` - Prevents Mac from sleeping during processing

#### Utils
- `ColorExtensions.swift` - Hex color initializer
- `DesignTokens.swift` - Hans Walker brand colors and fonts

### Application Flow

1. **Add Videos** - User selects video files via NSOpenPanel
2. **Configure Clips** - Set quantity (1-99), duration (10-90 sec), title, hashtags
3. **Select Output** - Choose output folder (remembered via bookmark)
4. **Process** - Sequential processing with progress updates
5. **Complete** - Show success, offer "Open Folder" and "New Batch" buttons

## Hans Walker Brand Design (v1.1)

### Design Principles

- **Reference:** `/Users/jancermak/Library/CloudStorage/Dropbox/hans-walker/hans walker — shorts factory/web/hanswalker-v6_1.html`
- **Style:** Art Deco inspired, elegant, walking-focused brand
- **macOS Native:** Respect macOS conventions while applying brand identity

### Color Palette

#### Light Mode
```
Background:     #F4EFE4 (cream)
Background Mid: #EBE4D4 (cream mid)
Background Deep:#DDD4BF (cream deep)
Text (Ink):     #2C1F14 (dark brown)
Text Secondary: #513F34 (brown light)
Accent Green:   #5EC48A (brand green)
Green Dark:     #3aad73 (shadows)
Green Deeper:   #2a8a58 (3D depth)
Gold Accent:    #C9A84C (decorative)
```

#### Dark Mode
```
Background:     #1e1e22 (neutral dark - NOT brown!)
Background Mid: #2c2c30
Background Deep:#3a3a3e
Text:           #EDE4D0 (cream)
Text Secondary: #c8b89a
Accent Green:   #4EC98A
Green Dark:     #3aad73
Green Deeper:   #2a8a58
```

### Typography

- **Krona One** - ONLY for "SHORTS FACTORY" app title (uppercase, tracked)
- **SF Pro (system font)** - Everything else (body text, labels, inputs)
- **NO Cormorant Garamond** in the app (only on web)

### UI Components

#### Main Button (HansWalkerButton)
- 3D press effect with depth shadow
- Capsule shape
- Green color (#5EC48A)
- Krona One font, 11pt, uppercase, letter-spacing: 3.2pt
- Shadows: depth (6px) + glow (24px blur)
- Press animation: moves down 5px, depth reduces to 1px

#### Header
- Hans Walker logo (PNG, template rendering, 48pt height)
- Vertical separator line (1px x 40pt)
- "SHORTS / FACTORY" stacked text (Krona One, 13pt, tracked 2.6pt)
- Padding: 20px horizontal, 16px vertical

#### Footer (Dynamic)
- **Default state:** Start Batch button + YouTube link
- **Processing state:** Progress bar with ETA + Stop button + YouTube link
- **Completed state:** Success message + "Open Folder" + "New Batch" + YouTube link
- Always sticky at bottom
- Background: hwBackgroundMid

### Assets

- **Logo:** `Assets.xcassets/hans-walker-logo.imageset/hans-walker-logo@2x.png`
- **Font:** `Resources/Fonts/KronaOne-Regular.ttf` (registered in Info.plist)

## Critical Technical Notes

### Threading & Concurrency

⚠️ **IMPORTANT:** We use SIMPLE sequential processing only (v1.0/v1.1):

```swift
// DO THIS (v1.0/v1.1):
for video in videos {
    await processVideo(video)
}

// DON'T DO THIS (v2.0 feature - caused freezing):
await withTaskGroup { group in
    for video in videos {
        group.addTask { await processVideo(video) }
    }
}
```

### Main Thread Updates

Always update @Published properties on main thread:

```swift
DispatchQueue.main.async {
    self.progress = newValue
}
// or
await MainActor.run {
    self.progress = newValue
}
```

### File Dialogs

Use `panel.runModal()` NOT `panel.begin { }` to avoid freezing:

```swift
// DO THIS:
let response = panel.runModal()

// DON'T DO THIS (causes freeze):
panel.begin { response in
    // ...
}
```

### Video Metadata

Load metadata asynchronously using `VideoMetadataLoader`:

```swift
Task.detached {
    let metadata = await VideoMetadataLoader.loadMetadata(for: url)
    await MainActor.run {
        // update UI
    }
}
```

## Common Issues & Solutions

### Issue: Build Error "Generic parameter 'Icon' could not be inferred"
**Solution:** We fixed this by changing buttons from generic `<Icon: View>` to `icon: AnyView?`

### Issue: Logo appears as black rectangle
**Solution:** 
1. Verify PNG is in `Assets.xcassets/hans-walker-logo.imageset/`
2. Check `Contents.json` is correct
3. Clean Build Folder (Cmd+Shift+K)
4. Ensure PNG has transparency

### Issue: Application freezes when adding videos
**Solution:** 
- Use `panel.runModal()` for file dialogs
- Load metadata on background thread
- Don't use AVFoundation on main thread

### Issue: "Publishing changes from background threads" warning
**Solution:** Wrap all @Published updates in `DispatchQueue.main.async` or `await MainActor.run`

## Development Workflow

### Git Branching
- `main` - stable versions only
- `feature/ui-redesign-v1.1-hans-walker-ui` - current work branch
- Tags: `v0.9`, `v1.0`, `v1.1` (when complete)

### Before Making Changes
1. Read relevant files first
2. Check current state
3. Make incremental changes
4. Test after each change

### Build Process
1. Clean Build Folder (Cmd+Shift+K)
2. Build (Cmd+B)
3. Run (Cmd+R)
4. Test in both Light and Dark mode

## Project Structure

```
VideoShortsFactory/
├── VideoShortsFactory/
│   ├── Models/
│   │   ├── VideoItem.swift
│   │   ├── ProcessingState.swift
│   │   └── ClipConfiguration.swift
│   ├── ViewModels/
│   │   └── VideoManager.swift
│   ├── Views/
│   │   ├── ContentView.swift
│   │   ├── HeaderView.swift
│   │   ├── FooterView.swift
│   │   └── Components/
│   │       └── HansWalkerButton.swift
│   ├── Services/
│   │   ├── FFmpegService.swift
│   │   ├── VideoMetadataLoader.swift
│   │   ├── DiskSpaceChecker.swift
│   │   └── SleepPrevention.swift
│   ├── Utils/
│   │   ├── ColorExtensions.swift
│   │   └── DesignTokens.swift
│   ├── Resources/
│   │   └── Fonts/
│   │       └── KronaOne-Regular.ttf
│   ├── Assets.xcassets/
│   │   └── hans-walker-logo.imageset/
│   ├── VideoShortsFactoryApp.swift
│   └── Info.plist
├── README.md
├── PROJECT_SUMMARY.md
├── QUICKSTART.md
├── V1.1_IMPLEMENTATION_NOTES.md
└── V1.1_UPDATE_NOTES.md
```

## Current v1.1 Status

### ✅ Completed
- Color design tokens (DesignTokens.swift)
- Custom button components with 3D effect
- Header with Hans Walker logo and branding
- Footer with dynamic states
- SF Symbols instead of emoji
- Window sizing and resizability
- Font integration (Krona One)

### 🚧 In Progress
- Logo asset verification (may appear as rectangle)
- Button color fine-tuning to match web exactly

### ⏸️ Not Yet Started (Future Versions)
- v1.2: Per-video overrides
- v1.3: Batch templates
- v1.4: Progress notifications
- v2.0: Parallel processing (needs careful testing!)

## User's Workflow & Expectations

- User wants to **test each version** before moving to the next
- Focus on **UI/UX polish** for v1.1
- **NO new processing features** until v1.1 is stable
- User is comfortable with terminal/git commands
- User expects **incremental changes** with explanations

## Key User Requests for v1.1

1. ✅ Match Hans Walker web design colors
2. ✅ Dark mode should be NEUTRAL dark (not brown)
3. ✅ Krona One only for app title
4. ✅ 3D green button matching website
5. ✅ Logo in header
6. ✅ YouTube link in footer
7. 🔄 Logo should display correctly (not as rectangle)
8. 🔄 Button colors match web exactly

## Communication Style

- User speaks Czech - respond in Czech
- Be direct and technical
- Show code examples when relevant
- Explain what you're doing and why
- Ask for confirmation before major changes

## What NOT to Do

❌ Add parallel processing (v2.0 feature)  
❌ Use emoji instead of SF Symbols  
❌ Use Cormorant Garamond font  
❌ Make dark mode brown  
❌ Use generic types that cause inference errors  
❌ Block main thread with file operations  
❌ Make changes without reading current state first  

## Quick Reference Commands

```bash
# Clean Xcode build
# In Xcode: Product → Clean Build Folder (Cmd+Shift+K)

# Build and run
# In Xcode: Product → Run (Cmd+R)

# Check git status
git status

# Create new branch
git checkout -b feature/branch-name

# Commit changes
git add .
git commit -m "message"
git push origin branch-name
```

## Resources

- **Design reference:** `/Users/jancermak/Library/CloudStorage/Dropbox/hans-walker/hans walker — shorts factory/web/hanswalker-v6_1.html`
- **Logo source:** `/Users/jancermak/Library/CloudStorage/Dropbox/hans-walker/brand/`
- **Project root:** `/Users/jancermak/dev/video-shorts-factory/`
- **YouTube channel:** `www.youtube.com/@HansWalker.walking`

## Next Steps for New Agent

1. Read this context file thoroughly
2. Review current state of key files:
   - `ContentView.swift`
   - `HeaderView.swift`  
   - `FooterView.swift`
   - `HansWalkerButton.swift`
   - `DesignTokens.swift`
3. Check if logo is displaying correctly
4. Verify button colors match HTML reference
5. Test in both light and dark modes
6. Ask user for specific next task

---

**Last Updated:** 2026-03-02  
**By:** AI Assistant helping Jan Čermák with Hans Walker Shorts Factory development
