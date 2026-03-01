import SwiftUI
import AppKit

struct ContentView: View {
    @StateObject private var videoManager = VideoManager()

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 16) {
                    sourceVideosSection
                    clipSettingsSection
                    outputSection
                    batchSection
                }
                .padding(20)
            }
        }
        .frame(width: 520, height: 480)
        .background(Color(nsColor: .windowBackgroundColor))
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("AddVideosAction"))) { _ in
            guard !videoManager.isProcessing else { return }
            openFilePicker()
        }
    }

    // MARK: - (1) Source Videos

    private var sourceVideosSection: some View {
        wizardSection(number: 1, title: "Source Videos", isReady: !videoManager.videos.isEmpty) {
            VStack(spacing: 8) {
                if videoManager.videos.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: 4) {
                            Image(systemName: "video.badge.plus")
                                .font(.title2)
                                .foregroundColor(Color(nsColor: .tertiaryLabelColor))
                            Text("No videos added yet")
                                .font(.caption)
                                .foregroundColor(Color(nsColor: .tertiaryLabelColor))
                        }
                        .padding(.vertical, 16)
                        Spacer()
                    }
                } else {
                    VStack(spacing: 2) {
                        ForEach(videoManager.videos, id: \.id) { video in
                            videoRow(video)
                        }
                    }
                }

                HStack(spacing: 8) {
                    if !videoManager.videos.isEmpty {
                        Button("Clear All") {
                            videoManager.videos.removeAll()
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.secondary)
                        .font(.caption)
                        .disabled(videoManager.isProcessing)
                    }

                    Spacer()

                    Button {
                        openFilePicker()
                    } label: {
                        Label("Add Videos", systemImage: "plus.circle.fill")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled(videoManager.isProcessing)
                }
            }
        }
    }

    private func videoRow(_ video: VideoItem) -> some View {
        HStack(spacing: 8) {
            Image(systemName: iconName(for: video.state))
                .font(.caption)
                .foregroundColor(iconColor(for: video.state))
                .frame(width: 16)

            Text(video.fileName)
                .font(.system(.caption, design: .monospaced))
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer()

            if video.state == .processing || video.state == .completed {
                ProgressView(value: video.progress)
                    .frame(width: 50)
            }

            if let dur = video.durationSeconds {
                let m = Int(dur) / 60
                let s = Int(dur) % 60
                Text(String(format: "%d:%02d", m, s))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(width: 36, alignment: .trailing)
            }

            Text(video.fileSizeString)
                .font(.caption2)
                .foregroundColor(.secondary)
                .frame(width: 50, alignment: .trailing)

            Button {
                videoManager.removeVideo(video)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption2)
                    .foregroundColor(Color(nsColor: .tertiaryLabelColor))
            }
            .buttonStyle(.plain)
            .disabled(videoManager.isProcessing)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        .cornerRadius(4)
    }

    // MARK: - (2) Clip Settings

    private var clipSettingsSection: some View {
        wizardSection(number: 2, title: "Clip Settings", isReady: true) {
            VStack(spacing: 10) {
                HStack(spacing: 16) {
                    HStack(spacing: 6) {
                        Text("Clips")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Stepper(
                            "\(videoManager.globalConfiguration.quantity)",
                            value: Binding(
                                get: { videoManager.globalConfiguration.quantity },
                                set: { videoManager.globalConfiguration.quantity = $0; videoManager.saveSettings(); syncConfig() }
                            ),
                            in: 1...50
                        )
                        .font(.caption)
                        .disabled(videoManager.isProcessing)
                    }

                    HStack(spacing: 6) {
                        Text("Duration")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Stepper(
                            "\(videoManager.globalConfiguration.duration)s",
                            value: Binding(
                                get: { videoManager.globalConfiguration.duration },
                                set: { videoManager.globalConfiguration.duration = $0; videoManager.saveSettings(); syncConfig() }
                            ),
                            in: 5...60
                        )
                        .font(.caption)
                        .disabled(videoManager.isProcessing)
                    }

                    Spacer()
                }

                HStack(spacing: 6) {
                    Text("Title")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 32, alignment: .leading)
                    TextField("Optional title", text: Binding(
                        get: { videoManager.globalConfiguration.baseTitle },
                        set: { videoManager.globalConfiguration.baseTitle = $0; videoManager.saveSettings(); syncConfig() }
                    ))
                    .textFieldStyle(.roundedBorder)
                    .font(.caption)
                    .disabled(videoManager.isProcessing)
                }

                HStack(spacing: 6) {
                    Text("Tags")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 32, alignment: .leading)
                    TextField("#shorts #fyp", text: Binding(
                        get: { videoManager.globalConfiguration.hashtags },
                        set: { videoManager.globalConfiguration.hashtags = $0; videoManager.saveSettings(); syncConfig() }
                    ))
                    .textFieldStyle(.roundedBorder)
                    .font(.caption)
                    .disabled(videoManager.isProcessing)
                }
            }
        }
    }

    // MARK: - (3) Output

    @State private var showFolderPicker = false

    private var outputSection: some View {
        wizardSection(number: 3, title: "Output", isReady: videoManager.globalConfiguration.outputFolder != nil) {
            VStack(spacing: 6) {
                HStack {
                    if let folder = videoManager.globalConfiguration.outputFolder {
                        Image(systemName: "folder.fill")
                            .font(.caption)
                            .foregroundColor(.accentColor)
                        Text(folder.path)
                            .font(.caption)
                            .lineLimit(1)
                            .truncationMode(.head)
                    } else {
                        Image(systemName: "folder.badge.questionmark")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Text("No output folder selected")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button("Change") {
                        showFolderPicker = true
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .font(.caption)
                    .disabled(videoManager.isProcessing)
                }

                if let folder = videoManager.globalConfiguration.outputFolder,
                   !videoManager.videos.isEmpty {
                    HStack {
                        Text("Available: \(DiskSpaceChecker.shared.getAvailableSpaceString(at: folder))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("Required: ~\(DiskSpaceChecker.shared.formatBytes(DiskSpaceChecker.shared.estimateRequiredSpace(for: videoManager.videos)))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
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

    // MARK: - (4) Start / Progress / Completion

    private var batchSection: some View {
        Group {
            if videoManager.batchCompleted {
                completionView
            } else if videoManager.isProcessing {
                progressView
            } else {
                startView
            }
        }
    }

    private var startView: some View {
        let canStart = !videoManager.isProcessing
            && !videoManager.videos.isEmpty
            && videoManager.globalConfiguration.outputFolder != nil

        return VStack(spacing: 8) {
            Button {
                videoManager.startBatchProcessing()
            } label: {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Start Batch")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 32)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!canStart)

            if videoManager.videos.isEmpty {
                hintLabel("Add source videos to begin", icon: "1.circle")
            } else if videoManager.globalConfiguration.outputFolder == nil {
                hintLabel("Select an output folder", icon: "3.circle")
            }
        }
    }

    private var progressView: some View {
        wizardSection(number: 4, title: "Processing", isReady: false, isActive: true) {
            VStack(spacing: 8) {
                ProgressView(value: videoManager.masterProgress)

                HStack {
                    Text("\(videoManager.clipsCompleted)/\(videoManager.totalClipsToGenerate) clips")
                        .font(.caption)
                        .fontWeight(.medium)
                    Spacer()
                    Text("\(Int(videoManager.masterProgress * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Image(systemName: "clock")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("ETA: \(videoManager.estimatedTimeRemainingString)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button("Stop") {
                        videoManager.stopProcessing()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .font(.caption)
                    .tint(.red)
                }
            }
        }
    }

    private var completionView: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Processing Complete")
                        .font(.headline)
                    Text("\(videoManager.clipsCompleted) clips generated")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }

            HStack(spacing: 12) {
                Button {
                    videoManager.openOutputFolder()
                } label: {
                    HStack {
                        Image(systemName: "folder")
                        Text("Open Folder")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    videoManager.startNewBatch()
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("New Batch")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(12)
        .background(Color.green.opacity(0.08))
        .cornerRadius(8)
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

    private func hintLabel(_ text: String, icon: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.caption2)
        }
        .foregroundColor(.secondary)
    }

    private func iconName(for state: ProcessingState) -> String {
        switch state {
        case .completed: return "checkmark.circle.fill"
        case .failed: return "exclamationmark.circle.fill"
        case .processing: return "circle.dotted"
        case .queued: return "clock"
        default: return "film"
        }
    }

    private func iconColor(for state: ProcessingState) -> Color {
        switch state {
        case .completed: return .green
        case .failed: return .red
        case .processing: return .orange
        case .queued: return .blue
        default: return .secondary
        }
    }

    // MARK: - Wizard Section

    private func wizardSection<Content: View>(
        number: Int,
        title: String,
        isReady: Bool,
        isActive: Bool = false,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                if isActive {
                    Image(systemName: "\(number).circle.fill")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                } else if isReady {
                    Image(systemName: "\(number).circle.fill")
                        .font(.subheadline)
                        .foregroundColor(.accentColor)
                } else {
                    Image(systemName: "\(number).circle")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            content()
                .padding(10)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(6)
        }
    }
}

#Preview {
    ContentView()
}
