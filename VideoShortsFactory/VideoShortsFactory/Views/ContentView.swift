import SwiftUI
import AppKit

struct ContentView: View {
    @StateObject private var videoManager = VideoManager()

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 16) {
                    SourceVideosSection(videoManager: videoManager)
                    ClipSettingsSection(videoManager: videoManager)
                    OutputSection(videoManager: videoManager)
                    BatchActionSection(videoManager: videoManager)
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

        for url in panel.urls {
            let ext = url.pathExtension.lowercased()
            guard ext == "mp4" || ext == "mov" else { continue }
            guard !videoManager.videos.contains(where: { $0.url == url }) else { continue }

            let videoItem = VideoItem(url: url)
            videoItem.configuration = videoManager.globalConfiguration
            videoManager.videos.append(videoItem)
        }

        for videoItem in videoManager.videos where videoItem.durationSeconds == nil {
            Task.detached(priority: .utility) { [weak videoManager] in
                await VideoMetadataLoader.loadMetadata(for: videoItem)
                await MainActor.run {
                    videoManager?.objectWillChange.send()
                }
            }
        }
    }
}

// MARK: - (1) Source Videos

private struct SourceVideosSection: View {
    @ObservedObject var videoManager: VideoManager

    var body: some View {
        WizardSection(
            number: 1,
            title: "Source Videos",
            state: videoManager.videos.isEmpty ? .pending : .ready
        ) {
            VStack(spacing: 8) {
                if videoManager.videos.isEmpty {
                    emptyState
                } else {
                    videoList
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
                        NotificationCenter.default.post(
                            name: NSNotification.Name("AddVideosAction"),
                            object: nil
                        )
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

    private var emptyState: some View {
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
    }

    private var videoList: some View {
        VStack(spacing: 2) {
            ForEach(videoManager.videos, id: \.id) { video in
                VideoRow(video: video, videoManager: videoManager)
            }
        }
    }
}

private struct VideoRow: View {
    let video: VideoItem
    @ObservedObject var videoManager: VideoManager

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "film")
                .font(.caption)
                .foregroundColor(.secondary)
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
                Text(formatDuration(dur))
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

    private func formatDuration(_ seconds: Double) -> String {
        let m = Int(seconds) / 60
        let s = Int(seconds) % 60
        return String(format: "%d:%02d", m, s)
    }
}

// MARK: - (2) Clip Settings

private struct ClipSettingsSection: View {
    @ObservedObject var videoManager: VideoManager

    var body: some View {
        WizardSection(
            number: 2,
            title: "Clip Settings",
            state: .ready
        ) {
            VStack(spacing: 10) {
                HStack(spacing: 16) {
                    HStack(spacing: 6) {
                        Text("Clips")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Stepper(
                            "\(videoManager.globalConfiguration.quantity)",
                            value: quantityBinding,
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
                            value: durationBinding,
                            in: 5...60
                        )
                        .font(.caption)
                        .disabled(videoManager.isProcessing)
                    }

                    Spacer()
                }

                HStack(spacing: 16) {
                    HStack(spacing: 6) {
                        Text("Title")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 32, alignment: .leading)
                        TextField("Optional title", text: titleBinding)
                            .textFieldStyle(.roundedBorder)
                            .font(.caption)
                            .disabled(videoManager.isProcessing)
                    }
                }

                HStack(spacing: 6) {
                    Text("Tags")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 32, alignment: .leading)
                    TextField("#shorts #fyp", text: hashtagsBinding)
                        .textFieldStyle(.roundedBorder)
                        .font(.caption)
                        .disabled(videoManager.isProcessing)
                }
            }
        }
    }

    private var quantityBinding: Binding<Int> {
        Binding(
            get: { videoManager.globalConfiguration.quantity },
            set: { newValue in
                videoManager.globalConfiguration.quantity = newValue
                videoManager.saveSettings()
                syncConfigToVideos()
            }
        )
    }

    private var durationBinding: Binding<Int> {
        Binding(
            get: { videoManager.globalConfiguration.duration },
            set: { newValue in
                videoManager.globalConfiguration.duration = newValue
                videoManager.saveSettings()
                syncConfigToVideos()
            }
        )
    }

    private var titleBinding: Binding<String> {
        Binding(
            get: { videoManager.globalConfiguration.baseTitle },
            set: { newValue in
                videoManager.globalConfiguration.baseTitle = newValue
                videoManager.saveSettings()
                syncConfigToVideos()
            }
        )
    }

    private var hashtagsBinding: Binding<String> {
        Binding(
            get: { videoManager.globalConfiguration.hashtags },
            set: { newValue in
                videoManager.globalConfiguration.hashtags = newValue
                videoManager.saveSettings()
                syncConfigToVideos()
            }
        )
    }

    private func syncConfigToVideos() {
        for video in videoManager.videos {
            video.configuration = videoManager.globalConfiguration
        }
    }
}

// MARK: - (3) Output

private struct OutputSection: View {
    @ObservedObject var videoManager: VideoManager
    @State private var showFolderPicker = false

    var body: some View {
        WizardSection(
            number: 3,
            title: "Output",
            state: videoManager.globalConfiguration.outputFolder != nil ? .ready : .pending
        ) {
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
                        let available = DiskSpaceChecker.shared.getAvailableSpaceString(at: folder)
                        let required = DiskSpaceChecker.shared.formatBytes(
                            DiskSpaceChecker.shared.estimateRequiredSpace(for: videoManager.videos)
                        )
                        Text("Available: \(available)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("Required: ~\(required)")
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
                for video in videoManager.videos {
                    video.configuration = videoManager.globalConfiguration
                }
            }
        }
    }
}

// MARK: - (4) Batch Action / Progress / Completion

private struct BatchActionSection: View {
    @ObservedObject var videoManager: VideoManager

    private var canStart: Bool {
        !videoManager.isProcessing &&
        !videoManager.videos.isEmpty &&
        videoManager.globalConfiguration.outputFolder != nil
    }

    var body: some View {
        if videoManager.batchCompleted {
            completionView
        } else if videoManager.isProcessing {
            progressView
        } else {
            startView
        }
    }

    private var startView: some View {
        VStack(spacing: 8) {
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

            if !canStart {
                missingStepsHint
            }
        }
    }

    @ViewBuilder
    private var missingStepsHint: some View {
        if videoManager.videos.isEmpty {
            hintLabel("Add source videos to begin", icon: "1.circle")
        } else if videoManager.globalConfiguration.outputFolder == nil {
            hintLabel("Select an output folder", icon: "3.circle")
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

    private var progressView: some View {
        WizardSection(
            number: 4,
            title: "Processing",
            state: .active
        ) {
            VStack(spacing: 8) {
                ProgressView(value: videoManager.masterProgress)
                    .progressViewStyle(.linear)

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
                .controlSize(.regular)

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
                .controlSize(.regular)
            }
        }
        .padding(12)
        .background(Color.green.opacity(0.08))
        .cornerRadius(8)
    }
}

// MARK: - Wizard Section Container

private enum StepState {
    case pending, ready, active
}

private struct WizardSection<Content: View>: View {
    let number: Int
    let title: String
    let state: StepState
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                stepBadge
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

    @ViewBuilder
    private var stepBadge: some View {
        switch state {
        case .pending:
            Image(systemName: "\(number).circle")
                .font(.subheadline)
                .foregroundColor(.secondary)
        case .ready:
            Image(systemName: "\(number).circle.fill")
                .font(.subheadline)
                .foregroundColor(.accentColor)
        case .active:
            Image(systemName: "\(number).circle.fill")
                .font(.subheadline)
                .foregroundColor(.orange)
        }
    }
}

#Preview {
    ContentView()
}
