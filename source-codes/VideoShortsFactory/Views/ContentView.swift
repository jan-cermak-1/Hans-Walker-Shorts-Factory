import SwiftUI
import AppKit
import ObjectiveC

struct ContentView: View {
    @StateObject private var videoManager = VideoManager()
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            // Header - fixed at top
            HeaderView()
            
            // Scrollable body - only cards
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 10) {
                    sourceVideosCard
                    clipSettingsCard
                    outputCard
                }
                .padding(14)
            }
            .background(Color.hwBackground(colorScheme))
            
            // Footer - fixed at bottom, dynamic content
            FooterView(videoManager: videoManager)
        }
        .frame(width: 540)  // Fixní šířka
        .frame(minHeight: 520)
        .background(Color.hwBackground(colorScheme))
        .onAppear {
            configureWindowSize()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("AddVideosAction"))) { _ in
            guard !videoManager.isProcessing else { return }
            openFilePicker()
        }
        .alert(item: $videoManager.errorAlert) { error in
            Alert(
                title: Text(error.title),
                message: Text(error.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func configureWindowSize() {
        DispatchQueue.main.async {
            guard let window = NSApplication.shared.windows.first else { return }
            
            // Vytvoř a nastav window delegate pro kontrolu resize
            let delegate = FixedWidthWindowDelegate()
            window.delegate = delegate
            // Uložíme delegate do window, aby se neuvolnil z paměti
            objc_setAssociatedObject(window, "windowDelegate", delegate, .OBJC_ASSOCIATION_RETAIN)
            
            if let screen = window.screen ?? NSScreen.main {
                let screenHeight = screen.visibleFrame.height
                let idealHeight: CGFloat = 840
                let maxHeight = screenHeight * 0.9
                
                // Použij 840px nebo 90% výšky obrazovky (co je menší)
                let targetHeight = min(idealHeight, maxHeight)
                
                // Nastav velikost okna s fixní šířkou 540px
                var frame = window.frame
                frame.size.height = targetHeight
                frame.size.width = 540
                
                // Vycentruj okno
                window.setFrame(frame, display: true, animate: false)
                window.center()
                
                // ZAKÁZAT horizontální resize - pouze vertikální
                window.styleMask.insert(.resizable)
                window.minSize = NSSize(width: 540, height: 520)
                window.maxSize = NSSize(width: 540, height: CGFloat.greatestFiniteMagnitude)
            }
        }
    }

    // MARK: - (1) Source Videos

    private var sourceVideosCard: some View {
        card(number: "1", title: "Source Videos") {
            VStack(spacing: 8) {
                if videoManager.videos.isEmpty {
                    VStack(spacing: 5) {
                        Image(systemName: "film")
                            .font(.system(size: 32))
                            .foregroundColor(Color.hwTextSecondary(colorScheme).opacity(0.25))
                        Text("No videos added yet")
                            .font(.system(size: 12))
                            .foregroundColor(Color.hwTextSecondary(colorScheme).opacity(0.7))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 20)
                    .padding(.bottom, 12)
                } else {
                    VStack(spacing: 6) {
                        ForEach(videoManager.videos, id: \.id) { video in
                            videoRow(video)
                        }
                    }
                }

                addVideosButton
                    .padding(.top, videoManager.videos.isEmpty ? 0 : 8)
            }
        }
    }

    private func videoRow(_ video: VideoItem) -> some View {
        VideoRowView(video: video, videoManager: videoManager)
    }

    private var addVideosButton: some View {
        AddVideosButtonView(isProcessing: videoManager.isProcessing, action: openFilePicker)
    }

    // MARK: - (2) Clip Settings

    private var clipSettingsCard: some View {
        card(number: "2", title: "Clip Settings") {
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        fieldLabel("CLIPS")
                        editableStepper(
                            value: Binding(
                                get: { videoManager.globalConfiguration.quantity },
                                set: { videoManager.globalConfiguration.quantity = $0; videoManager.saveSettings(); syncConfig() }
                            ),
                            range: 1...99,
                            unit: nil
                        )
                    }
                    .frame(maxWidth: .infinity)

                    VStack(alignment: .leading, spacing: 4) {
                        fieldLabel("DURATION")
                        editableStepper(
                            value: Binding(
                                get: { videoManager.globalConfiguration.duration },
                                set: { videoManager.globalConfiguration.duration = $0; videoManager.saveSettings(); syncConfig() }
                            ),
                            range: 5...300,
                            unit: "sec"
                        )
                    }
                    .frame(maxWidth: .infinity)
                }

                VStack(alignment: .leading, spacing: 4) {
                    fieldLabel("TITLE")
                    styledTextField(
                        placeholder: "Enter title…",
                        text: Binding(
                            get: { videoManager.globalConfiguration.baseTitle },
                            set: { videoManager.globalConfiguration.baseTitle = $0; videoManager.saveSettings(); syncConfig() }
                        )
                    )
                }

                VStack(alignment: .leading, spacing: 4) {
                    fieldLabel("TAGS")
                    styledTextField(
                        placeholder: "#shorts #fyp",
                        text: Binding(
                            get: { videoManager.globalConfiguration.hashtags },
                            set: { videoManager.globalConfiguration.hashtags = $0; videoManager.saveSettings(); syncConfig() }
                        )
                    )
                }
            }
        }
    }

    // MARK: - (3) Output

    @State private var showFolderPicker = false

    private var outputCard: some View {
        card(number: "3", title: "Output") {
            HStack(spacing: 10) {
                Image(systemName: "folder.fill")
                    .font(.system(size: 18))
                    .foregroundColor(Color.hwText(colorScheme))

                VStack(alignment: .leading, spacing: 2) {
                    if let folder = videoManager.globalConfiguration.outputFolder {
                        Text(folder.path)
                            .font(.system(size: 13))
                            .foregroundColor(Color.hwText(colorScheme))
                            .lineLimit(1)
                            .truncationMode(.head)

                        diskSpaceLabel(folder: folder)
                    } else {
                        Text("No output folder selected")
                            .font(.system(size: 13))
                            .foregroundColor(Color.hwTextSecondary(colorScheme))
                    }
                }

                Spacer()

                ChangeButtonView(isProcessing: videoManager.isProcessing) {
                    showFolderPicker = true
                }
            }
        }
        .fileImporter(
            isPresented: $showFolderPicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                videoManager.globalConfiguration.outputFolder = url
                videoManager.saveOutputFolder()
                syncConfig()
            }
        }
    }

    @ViewBuilder
    private func diskSpaceLabel(folder: URL) -> some View {
        let available = DiskSpaceChecker.shared.getAvailableSpaceString(at: folder)
        if !videoManager.videos.isEmpty {
            let required = DiskSpaceChecker.shared.formatBytes(
                DiskSpaceChecker.shared.estimateRequiredSpace(for: videoManager.videos)
            )
            Text("Available: \(available) \u{00B7} Required: ~\(required)")
                .font(.system(size: 11))
                .foregroundColor(Color.hwTextSecondary(colorScheme))
        }
    }

    // MARK: - Card Container

    private func card<Content: View>(
        number: String,
        title: String,
        badgeColor: Color = Color.hwGreen,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Text(number)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 20, height: 20)
                    .background(badgeColor)
                    .clipShape(Circle())

                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color.hwText(colorScheme))

                Spacer()
            }
            .padding(.horizontal, 13)
            .padding(.vertical, 9)
            .background(Color.hwBackgroundMid(colorScheme).opacity(0.5))

            Divider()
                .background(Color.hwSeparator(colorScheme))

            content()
                .padding(.horizontal, 13)
                .padding(.vertical, 12)
        }
        .background(Color.hwBackgroundMid(colorScheme))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.hwSeparator(colorScheme), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
    }

    // MARK: - Editable Stepper

    private func editableStepper(value: Binding<Int>, range: ClosedRange<Int>, unit: String?) -> some View {
        EditableStepperField(value: value, range: range, unit: unit, disabled: videoManager.isProcessing)
    }

    // MARK: - Styled TextField

    private func styledTextField(placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .textFieldStyle(.plain)
            .font(.system(size: 13))
            .foregroundColor(Color.hwText(colorScheme))
            .padding(.horizontal, 10)
            .frame(height: 34)
            .background(Color.hwBackgroundDeep(colorScheme))
            .cornerRadius(7)
            .overlay(
                RoundedRectangle(cornerRadius: 7)
                    .stroke(Color.hwSeparator(colorScheme), lineWidth: 1)
            )
            .disabled(videoManager.isProcessing)
    }

    // MARK: - Field Label

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10.5, weight: .semibold))
            .foregroundColor(Color.hwTextSecondary(colorScheme).opacity(0.7))
            .tracking(0.5)
    }

    // MARK: - Helpers

    private func openFilePicker() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.movie, .mpeg4Movie, .quickTimeMovie]
        panel.message = "Select video files to process"
        panel.prompt = "Add Videos"

        let response = panel.runModal()
        guard response == .OK else { return }

        let manager = videoManager
        for url in panel.urls {
            let ext = url.pathExtension.lowercased()
            guard ext == "mp4" || ext == "mov" else { continue }
            guard !manager.videos.contains(where: { $0.url == url }) else { continue }

            let videoItem = VideoItem(url: url)
            videoItem.configuration = manager.globalConfiguration
            manager.videos.append(videoItem)
        }

        for videoItem in manager.videos where videoItem.durationSeconds == nil {
            Task.detached(priority: .utility) {
                await VideoMetadataLoader.loadMetadata(for: videoItem)
                await MainActor.run {
                    manager.objectWillChange.send()
                }
            }
        }
    }

    private func syncConfig() {
        for video in videoManager.videos {
            video.configuration = videoManager.globalConfiguration
        }
    }
}

// MARK: - Fixed Width Window Delegate
class FixedWidthWindowDelegate: NSObject, NSWindowDelegate {
    private let fixedWidth: CGFloat = 540
    
    func windowWillResize(_ sender: NSWindow, to frameSize: NSSize) -> NSSize {
        // Vždy vrať fixní šířku, ale povol změnu výšky
        return NSSize(width: fixedWidth, height: frameSize.height)
    }
}

// MARK: - Video Row with Hover
struct VideoRowView: View {
    let video: VideoItem
    let videoManager: VideoManager
    
    @Environment(\.colorScheme) var colorScheme
    @State private var removeHovered = false
    
    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: "film.fill")
                .font(.system(size: 20))
                .foregroundColor(Color.hwText(colorScheme))

            VStack(alignment: .leading, spacing: 1) {
                Text(video.fileName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.hwText(colorScheme))
                    .lineLimit(1)
                    .truncationMode(.middle)

                Text("\(video.durationString) \u{00B7} \(video.fileSizeString)")
                    .font(.system(size: 11))
                    .foregroundColor(Color.hwTextSecondary(colorScheme))

                if video.state == .processing || video.state == .completed {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.hwSeparator(colorScheme).opacity(0.3))
                                .frame(height: 3)
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.hwAccentGreen(colorScheme))
                                .frame(width: geo.size.width * video.progress, height: 3)
                        }
                    }
                    .frame(width: 72, height: 3)
                    .padding(.top, 4)
                }
            }

            Spacer()

            Button {
                videoManager.removeVideo(video)
            } label: {
                Text("\u{2715}")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(
                        removeHovered && !videoManager.isProcessing
                            ? Color.red.opacity(0.9)
                            : Color.hwTextSecondary(colorScheme).opacity(0.6)
                    )
                    .frame(width: 18, height: 18)
                    .background(
                        removeHovered && !videoManager.isProcessing
                            ? Color.red.opacity(0.15)
                            : Color.hwSeparator(colorScheme).opacity(0.3)
                    )
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(videoManager.isProcessing)
            .onHover { hovering in
                removeHovered = hovering
            }
            .animation(.easeInOut(duration: 0.15), value: removeHovered)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 8)
        .background(Color.hwAccentGreen(colorScheme).opacity(0.08))
        .cornerRadius(7)
        .overlay(
            RoundedRectangle(cornerRadius: 7)
                .stroke(Color.hwAccentGreen(colorScheme).opacity(0.15), lineWidth: 1)
        )
    }
}

// MARK: - Add Videos Button with Hover
struct AddVideosButtonView: View {
    let isProcessing: Bool
    let action: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    @State private var isHovered = false
    
    var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: 5) {
                Text("+")
                    .font(.system(size: 14, weight: .medium))
                Text("Add Videos")
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(
                isHovered 
                    ? Color.hwAccentGreen(colorScheme)
                    : Color.hwAccentGreen(colorScheme).opacity(0.8)
            )
            .frame(maxWidth: .infinity)
            .frame(height: 32)
            .background(
                isHovered 
                    ? Color.hwAccentGreen(colorScheme).opacity(0.08)
                    : Color.clear
            )
            .cornerRadius(7)
            .overlay(
                RoundedRectangle(cornerRadius: 7)
                    .stroke(
                        Color.hwAccentGreen(colorScheme).opacity(isHovered ? 0.7 : 0.45),
                        style: StrokeStyle(lineWidth: isHovered ? 2 : 1.5, dash: [5, 3])
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(isProcessing)
        .onHover { hovering in
            isHovered = hovering && !isProcessing
        }
        .animation(.easeInOut(duration: 0.15), value: isHovered)
    }
}

// MARK: - Editable Stepper Field

struct EditableStepperField: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    let unit: String?
    let disabled: Bool
    
    @Environment(\.colorScheme) var colorScheme

    @State private var textValue: String = ""
    @FocusState private var isFocused: Bool
    @State private var minusHovered = false
    @State private var plusHovered = false

    var body: some View {
        HStack(spacing: 0) {
            Button {
                if value > range.lowerBound { value -= 1 }
                textValue = "\(value)"
            } label: {
                Text("\u{2212}")
                    .font(.system(size: 15))
                    .foregroundColor(
                        minusHovered && !disabled
                            ? Color.hwAccentGreen(colorScheme)
                            : Color.hwTextSecondary(colorScheme)
                    )
                    .frame(width: 30, height: 34)
                    .background(
                        minusHovered && !disabled
                            ? Color.hwAccentGreen(colorScheme).opacity(0.12)
                            : Color.hwSeparator(colorScheme).opacity(0.2)
                    )
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(disabled)
            .onHover { hovering in
                minusHovered = hovering
            }
            .animation(.easeInOut(duration: 0.15), value: minusHovered)

            Rectangle()
                .fill(Color.hwSeparator(colorScheme))
                .frame(width: 1, height: 34)

            TextField("", text: $textValue)
                .textFieldStyle(.plain)
                .multilineTextAlignment(.center)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color.hwText(colorScheme))
                .frame(maxWidth: .infinity)
                .frame(height: 34)
                .focused($isFocused)
                .disabled(disabled)
                .onSubmit { commitValue() }
                .onChange(of: isFocused) { focused in
                    if !focused { commitValue() }
                }

            if let unit = unit {
                Text(unit)
                    .font(.system(size: 11))
                    .foregroundColor(Color.hwTextSecondary(colorScheme).opacity(0.6))
                    .padding(.trailing, 7)
            }

            Rectangle()
                .fill(Color.hwSeparator(colorScheme))
                .frame(width: 1, height: 34)

            Button {
                if value < range.upperBound { value += 1 }
                textValue = "\(value)"
            } label: {
                Text("+")
                    .font(.system(size: 15))
                    .foregroundColor(
                        plusHovered && !disabled
                            ? Color.hwAccentGreen(colorScheme)
                            : Color.hwTextSecondary(colorScheme)
                    )
                    .frame(width: 30, height: 34)
                    .background(
                        plusHovered && !disabled
                            ? Color.hwAccentGreen(colorScheme).opacity(0.12)
                            : Color.hwSeparator(colorScheme).opacity(0.2)
                    )
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(disabled)
            .onHover { hovering in
                plusHovered = hovering
            }
            .animation(.easeInOut(duration: 0.15), value: plusHovered)
        }
        .frame(height: 34)
        .background(Color.hwBackgroundDeep(colorScheme))
        .cornerRadius(7)
        .overlay(
            RoundedRectangle(cornerRadius: 7)
                .stroke(Color.hwSeparator(colorScheme), lineWidth: 1)
        )
        .onAppear { textValue = "\(value)" }
        .onChange(of: value) { newVal in
            if !isFocused { textValue = "\(newVal)" }
        }
    }

    private func commitValue() {
        if let parsed = Int(textValue) {
            value = min(max(parsed, range.lowerBound), range.upperBound)
        }
        textValue = "\(value)"
    }
}

// MARK: - Change Button with Hover
struct ChangeButtonView: View {
    let isProcessing: Bool
    let action: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    @State private var isHovered = false
    
    var body: some View {
        Button("Change") {
            action()
        }
        .font(.system(size: 12))
        .foregroundColor(
            isHovered
                ? Color.hwAccentGreen(colorScheme)
                : Color.hwTextSecondary(colorScheme)
        )
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .background(
            isHovered
                ? Color.hwAccentGreen(colorScheme).opacity(0.08)
                : Color.hwBackgroundDeep(colorScheme)
        )
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(
                    isHovered
                        ? Color.hwAccentGreen(colorScheme)
                        : Color.hwSeparator(colorScheme),
                    lineWidth: 1
                )
        )
        .buttonStyle(.plain)
        .disabled(isProcessing)
        .onHover { hovering in
            isHovered = hovering && !isProcessing
        }
        .animation(.easeInOut(duration: 0.15), value: isHovered)
    }
}

#Preview {
    ContentView()
}
