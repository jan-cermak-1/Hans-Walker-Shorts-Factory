import SwiftUI
import AppKit

struct ContentView: View {
    @StateObject private var videoManager = VideoManager()

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 10) {
                sourceVideosCard
                clipSettingsCard
                outputCard

                if videoManager.isProcessing {
                    processingCard
                } else if videoManager.batchCompleted {
                    completionCard
                } else {
                    startBatchButton
                }
            }
            .padding(14)
        }
        .frame(minWidth: 500, idealWidth: 500, maxWidth: 500)
        .frame(minHeight: 520)
        .background(Color(nsColor: .windowBackgroundColor))
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("AddVideosAction"))) { _ in
            guard !videoManager.isProcessing else { return }
            openFilePicker()
        }
    }

    // MARK: - (1) Source Videos

    private var sourceVideosCard: some View {
        card(number: "1", title: "Source Videos") {
            VStack(spacing: 8) {
                if videoManager.videos.isEmpty {
                    VStack(spacing: 5) {
                        Text("🎬")
                            .font(.system(size: 32))
                            .opacity(0.25)
                        Text("No videos added yet")
                            .font(.system(size: 12))
                            .foregroundColor(Color(nsColor: .secondaryLabelColor))
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
        HStack(spacing: 9) {
            Text("🎬")
                .font(.system(size: 22))

            VStack(alignment: .leading, spacing: 1) {
                Text(video.fileName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(nsColor: .labelColor))
                    .lineLimit(1)
                    .truncationMode(.middle)

                Text("\(video.durationString) \u{00B7} \(video.fileSizeString)")
                    .font(.system(size: 11))
                    .foregroundColor(Color(nsColor: .secondaryLabelColor))

                if video.state == .processing || video.state == .completed {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color(nsColor: .separatorColor))
                                .frame(height: 3)
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color(nsColor: .systemBlue))
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
                    .foregroundColor(Color(nsColor: .tertiaryLabelColor))
                    .frame(width: 18, height: 18)
                    .background(Color(nsColor: .separatorColor).opacity(0.5))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(videoManager.isProcessing)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 8)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        .cornerRadius(7)
        .overlay(
            RoundedRectangle(cornerRadius: 7)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
        )
    }

    private var addVideosButton: some View {
        Button {
            openFilePicker()
        } label: {
            HStack(spacing: 5) {
                Text("+")
                    .font(.system(size: 14, weight: .medium))
                Text("Add Videos")
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(Color(nsColor: .systemBlue))
            .frame(maxWidth: .infinity)
            .frame(height: 32)
            .background(Color.clear)
            .cornerRadius(7)
            .overlay(
                RoundedRectangle(cornerRadius: 7)
                    .stroke(Color(nsColor: .systemBlue).opacity(0.4), style: StrokeStyle(lineWidth: 1.5, dash: [5, 3]))
            )
        }
        .buttonStyle(.plain)
        .disabled(videoManager.isProcessing)
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
                Text("📁")
                    .font(.system(size: 20))

                VStack(alignment: .leading, spacing: 2) {
                    if let folder = videoManager.globalConfiguration.outputFolder {
                        Text(folder.path)
                            .font(.system(size: 13))
                            .foregroundColor(Color(nsColor: .labelColor))
                            .lineLimit(1)
                            .truncationMode(.head)

                        diskSpaceLabel(folder: folder)
                    } else {
                        Text("No output folder selected")
                            .font(.system(size: 13))
                            .foregroundColor(Color(nsColor: .secondaryLabelColor))
                    }
                }

                Spacer()

                Button("Change") {
                    showFolderPicker = true
                }
                .font(.system(size: 12))
                .foregroundColor(Color(nsColor: .secondaryLabelColor))
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                )
                .buttonStyle(.plain)
                .disabled(videoManager.isProcessing)
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
                .foregroundColor(Color(nsColor: .secondaryLabelColor))
        }
    }

    // MARK: - Start Batch

    private var startBatchButton: some View {
        let canStart = !videoManager.videos.isEmpty
            && videoManager.globalConfiguration.outputFolder != nil

        return VStack(spacing: 0) {
            Button {
                videoManager.startBatchProcessing()
            } label: {
                HStack(spacing: 8) {
                    Text("\u{25B6}")
                        .font(.system(size: 11))
                    Text("Start Batch")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(canStart ? .white : Color(nsColor: .tertiaryLabelColor))
                .frame(maxWidth: .infinity)
                .frame(height: 42)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(canStart ? Color(nsColor: .systemBlue) : Color(nsColor: .controlColor))
                )
            }
            .buttonStyle(.plain)
            .disabled(!canStart)

            if videoManager.videos.isEmpty || videoManager.globalConfiguration.outputFolder == nil {
                Group {
                    if videoManager.videos.isEmpty {
                        Text("\u{24D8} Add source videos to begin")
                    } else {
                        Text("\u{24D8} Select an output folder")
                    }
                }
                .font(.system(size: 11))
                .foregroundColor(Color(nsColor: .tertiaryLabelColor))
                .padding(.top, 4)
            }
        }
    }

    // MARK: - (4) Processing

    private var processingCard: some View {
        card(number: "4", title: "Processing", badgeColor: Color(red: 245/255, green: 158/255, blue: 11/255)) {
            VStack(spacing: 0) {
                HStack {
                    Text("\(videoManager.clipsCompleted) / \(videoManager.totalClipsToGenerate) clips done")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(nsColor: .labelColor))
                    Spacer()
                    Text("\(Int(videoManager.masterProgress * 100))%")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(nsColor: .systemBlue))
                }
                .padding(.bottom, 8)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(nsColor: .separatorColor))
                            .frame(height: 7)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(nsColor: .systemBlue))
                            .frame(width: max(0, geo.size.width * videoManager.masterProgress), height: 7)
                    }
                }
                .frame(height: 7)
                .padding(.bottom, 9)

                HStack {
                    HStack(spacing: 4) {
                        ProgressView()
                            .controlSize(.mini)
                        Text("ETA: ~\(videoManager.estimatedTimeRemainingString)")
                            .font(.system(size: 11))
                            .foregroundColor(Color(nsColor: .secondaryLabelColor))
                    }

                    Spacer()

                    Button {
                        videoManager.stopProcessing()
                    } label: {
                        Text("Stop")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(nsColor: .systemRed))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 5)
                            .background(Color(nsColor: .systemRed).opacity(0.1))
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color(nsColor: .systemRed).opacity(0.25), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Completion

    private var completionCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Text("\u{2705}")
                    .font(.system(size: 22))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Processing Complete")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(nsColor: .labelColor))
                    Text("\(videoManager.clipsCompleted) clips generated")
                        .font(.system(size: 11))
                        .foregroundColor(Color(nsColor: .secondaryLabelColor))
                }
                Spacer()
            }

            HStack(spacing: 12) {
                Button {
                    videoManager.openOutputFolder()
                } label: {
                    HStack(spacing: 5) {
                        Text("📂")
                            .font(.system(size: 12))
                        Text("Open Folder")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(Color(nsColor: .labelColor))
                    .frame(maxWidth: .infinity)
                    .frame(height: 34)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(7)
                    .overlay(
                        RoundedRectangle(cornerRadius: 7)
                            .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)

                Button {
                    videoManager.startNewBatch()
                } label: {
                    HStack(spacing: 5) {
                        Text("🔄")
                            .font(.system(size: 12))
                        Text("New Batch")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 34)
                    .background(Color(nsColor: .systemBlue))
                    .cornerRadius(7)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
    }

    // MARK: - Card Container

    private func card<Content: View>(
        number: String,
        title: String,
        badgeColor: Color = Color(nsColor: .systemBlue),
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
                    .foregroundColor(Color(nsColor: .labelColor))

                Spacer()
            }
            .padding(.horizontal, 13)
            .padding(.vertical, 9)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.3))

            Divider()
                .background(Color(nsColor: .separatorColor))

            content()
                .padding(.horizontal, 13)
                .padding(.vertical, 12)
        }
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
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
            .foregroundColor(Color(nsColor: .labelColor))
            .padding(.horizontal, 10)
            .frame(height: 34)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(7)
            .overlay(
                RoundedRectangle(cornerRadius: 7)
                    .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
            )
            .disabled(videoManager.isProcessing)
    }

    // MARK: - Field Label

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10.5, weight: .semibold))
            .foregroundColor(Color(nsColor: .tertiaryLabelColor))
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

// MARK: - Editable Stepper Field

struct EditableStepperField: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    let unit: String?
    let disabled: Bool

    @State private var textValue: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 0) {
            Button {
                if value > range.lowerBound { value -= 1 }
                textValue = "\(value)"
            } label: {
                Text("\u{2212}")
                    .font(.system(size: 15))
                    .foregroundColor(Color(nsColor: .secondaryLabelColor))
                    .frame(width: 30, height: 34)
                    .background(Color(nsColor: .separatorColor).opacity(0.3))
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(disabled)

            Rectangle()
                .fill(Color(nsColor: .separatorColor))
                .frame(width: 1, height: 34)

            TextField("", text: $textValue)
                .textFieldStyle(.plain)
                .multilineTextAlignment(.center)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(nsColor: .labelColor))
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
                    .foregroundColor(Color(nsColor: .tertiaryLabelColor))
                    .padding(.trailing, 7)
            }

            Rectangle()
                .fill(Color(nsColor: .separatorColor))
                .frame(width: 1, height: 34)

            Button {
                if value < range.upperBound { value += 1 }
                textValue = "\(value)"
            } label: {
                Text("+")
                    .font(.system(size: 15))
                    .foregroundColor(Color(nsColor: .secondaryLabelColor))
                    .frame(width: 30, height: 34)
                    .background(Color(nsColor: .separatorColor).opacity(0.3))
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(disabled)
        }
        .frame(height: 34)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(7)
        .overlay(
            RoundedRectangle(cornerRadius: 7)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
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

#Preview {
    ContentView()
}
