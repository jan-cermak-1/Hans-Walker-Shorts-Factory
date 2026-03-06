# Hans Walker Shorts Factory

> Turn long walks into short clips — effortlessly

Transform your long-form videos into engaging short clips for social media. Built for macOS, designed for creators.

[![Version](https://img.shields.io/badge/version-1.1.0-green.svg)](https://github.com/jan-cermak-1/video-shorts-factory/releases)
[![Platform](https://img.shields.io/badge/platform-macOS%2013+-blue.svg)](https://www.apple.com/macos/)
[![License](https://img.shields.io/badge/license-MIT-orange.svg)](LICENSE)
[![Made with SwiftUI](https://img.shields.io/badge/made%20with-SwiftUI-red.svg)](https://developer.apple.com/xcode/swiftui/)

## ✨ Features

- **⚡ Batch Processing** — Process multiple videos at once automatically
- **🎯 Smart Clipping** — Set duration (5-300s) and quantity, app does the rest
- **🎨 Hans Walker Design** — Beautiful, minimalist interface inspired by Hans Walker's brand
- **🔒 100% Private** — Everything runs locally on your Mac, no cloud, no tracking
- **🚀 FFmpeg Powered** — Industry-standard video processing, fast and reliable
- **💰 Free Forever** — No subscriptions, no trials, no hidden costs

## 📥 Download

**Latest Release: v1.1.0**

- [**Download for macOS (DMG)**](releases/Hans-Walker-Shorts-Factory-v1.1.0.dmg) — Recommended
- [View All Releases](https://github.com/jan-cermak-1/video-shorts-factory/releases)
- [Visit Website](website/index.html)

### System Requirements

- **macOS**: 13.0 (Ventura) or later
- **Processor**: Apple Silicon (M1/M2/M3) or Intel
- **Memory**: 4GB RAM minimum (8GB recommended)
- **Storage**: 200MB for app + space for video processing

## 🚀 Quick Start

1. **Download** the DMG file from [releases](releases/)
2. **Install** by dragging to Applications folder
3. **Open** the app and add your videos
4. **Configure** clip duration and quantity
5. **Process** and export to your chosen folder

## 📸 Screenshots

| Light Mode | Dark Mode | Processing |
|------------|-----------|------------|
| ![Light](website/assets/screenshots/light-mode.png) | ![Dark](website/assets/screenshots/dark-mode.png) | ![Processing](website/assets/screenshots/processing.png) |

## 📁 Project Structure

```
video-shorts-factory/
├── source-codes/          # Source code (Xcode project)
│   ├── VideoShortsFactory.xcodeproj
│   ├── VideoShortsFactory/
│   └── Documentation/
├── releases/             # Compiled app builds (.dmg, .zip)
├── website/             # Landing page with download
└── README.md           # This file
```

## 🛠️ Build from Source

### Prerequisites

- Xcode 15.0 or later
- macOS 13.0 or later
- FFmpeg (included in bundle)

### Steps

```bash
# Clone the repository
git clone https://github.com/jan-cermak-1/video-shorts-factory.git
cd video-shorts-factory

# Open in Xcode
open source-codes/VideoShortsFactory.xcodeproj

# Build and run (⌘+R)
```

For detailed build instructions, see [source-codes/README.md](source-codes/README.md)

## 📖 Documentation

- [Project Summary](source-codes/PROJECT_SUMMARY.md) — Architecture and design decisions
- [Quick Start Guide](source-codes/QUICKSTART.md) — Getting started with development
- [Agent Context](source-codes/AGENT_CONTEXT.md) — v1.1 goals and implementation notes
- [Contrast Analysis](source-codes/CONTRAST_ANALYSIS.md) — WCAG 2.1 accessibility compliance

## 🎨 Design

The app features a custom design system inspired by Hans Walker's brand:

- **Colors**: Warm cream backgrounds, deep ink text, vibrant green accents
- **Typography**: Krona One for headers, system font for body text
- **Components**: Custom 3D buttons, clean cards, smooth animations
- **Accessibility**: WCAG 2.1 Level AA compliant with proper contrast ratios

## 🔧 Technology Stack

- **Framework**: SwiftUI
- **Platform**: macOS 13+
- **Video Processing**: FFmpeg
- **Architecture**: MVVM pattern
- **Design System**: Custom Hans Walker tokens

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 Changelog

### v1.1.0 (March 6, 2026)

- ✅ Complete Hans Walker brand integration
- ✅ Custom design system with color palette
- ✅ Fixed window width, adaptive height
- ✅ Comprehensive hover effects
- ✅ WCAG 2.1 Level AA accessibility
- ✅ Dark mode support
- ✅ 3D button styling

See [CHANGELOG.md](CHANGELOG.md) for full version history.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **FFmpeg** — The backbone of video processing
- **SwiftUI** — Apple's modern UI framework
- **Hans Walker** — Brand inspiration and design direction
- **Krona One** — Typography from Google Fonts

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/jan-cermak-1/video-shorts-factory/issues)
- **Discussions**: [GitHub Discussions](https://github.com/jan-cermak-1/video-shorts-factory/discussions)
- **YouTube**: [@HansWalker.walking](https://youtube.com/@HansWalker.walking)

---

Made with ❤️ for creators | [Website](website/index.html) | [Download](releases/)
