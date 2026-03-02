import SwiftUI
import AppKit

@main
struct VideoShortsFactoryApp: App {

    init() {
        verifyFFmpegAvailability()
        configureInitialWindowSize()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentMinSize)
        .defaultSize(width: 540, height: 760)
        .commands {
            CommandGroup(after: .newItem) {
                Button("Add Videos...") {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("AddVideosAction"),
                        object: nil
                    )
                }
                .keyboardShortcut("o", modifiers: [.command])
            }
        }
    }
    
    private func configureInitialWindowSize() {
        DispatchQueue.main.async {
            if let screen = NSScreen.main {
                let screenHeight = screen.visibleFrame.height
                let idealHeight: CGFloat = 840
                let maxHeight = screenHeight * 0.9
                
                // Použij 840px nebo 90% výšky obrazovky (co je menší)
                let windowHeight = min(idealHeight, maxHeight)
                
                // Uložíme do UserDefaults pro příští spuštění
                UserDefaults.standard.set(windowHeight, forKey: "preferredWindowHeight")
            }
        }
    }

    private func verifyFFmpegAvailability() {
        if FFmpegService.shared.verifyFFmpegAvailability() {
            print("FFmpeg is available and ready to use")
        } else {
            DispatchQueue.main.async {
                showFFmpegWarning()
            }
        }
    }

    private func showFFmpegWarning() {
        let alert = NSAlert()
        alert.messageText = "FFmpeg Not Found"
        alert.informativeText = """
        FFmpeg binary was not found in the application bundle or system.

        The app requires FFmpeg to process videos. Please:
        1. Install FFmpeg via Homebrew: brew install ffmpeg
        2. Or add the FFmpeg binary to the app bundle

        The app may not work properly without FFmpeg.
        """
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
