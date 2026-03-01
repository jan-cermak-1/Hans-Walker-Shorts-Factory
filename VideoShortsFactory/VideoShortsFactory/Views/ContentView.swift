import SwiftUI
import AppKit
import UniformTypeIdentifiers
import UserNotifications

struct ContentView: View {
    @StateObject private var videoManager = VideoManager()
    @State private var isDragTargeted = false

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
        .overlay(dragOverlay)
        .onDrop(of: [.movie, .mpeg4Movie, .quickTimeMovie, .fileURL], isTargeted: $isDragTargeted) { providers in
            handleDrop(providers)
            return true
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("AddVideosAction"))) { _ in
            guard !videoManager.isProcessing else { return }
            openFilePicker()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ClearAllVideos"))) { _ in
            guard !videoManager.isProcessing else { return }
            videoManager.videos.removeAll()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("StartBatchAction"))) { _ in
            videoManager.startBatchProcessing()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("StopBatchAction"))) { _ in
            videoManager.stopProcessing()
        }
        .onChange(of: videoManager.batchCompleted) { completed in
            if completed {
                sendCompletionNotification()
            }
        }
        .alert(
            "Cannot Start Processing",
            isPresented: $videoManager.showErrorAlert,
            actions: { Button("OK") {} },
            message: { Text(videoManager.errorMessage) }
        )
        .onAppear {
            requestNotificationPermission()
        }
    }

    @ViewBuilder
    private var dragOverlay: some View {
        if isDragTargeted && !videoManager.isProcessing {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 2, dash: [8]))
                .background(Color.accentColor.opacity(0.08))
                .cornerRadius(8)
                .overlay(
                    VStack(spacing: 8) {
                        Image(systemName: "arrow.down.doc.fill")
                            .font(.largeTitle)
                            .foregroundColor(.accentColor)
                        Text("Drop video files here")
                            .font(.headline)
                            .foregroundColor(.accentColor)
                    }
                )
                .padding(4)
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) {
        guard !videoManager.isProcessing else { return }

        for provider in providers {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { data, _ in
                guard let data = data as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil) else { return }

                let ext = url.pathExtension.lowercased()
                guard ext == "mp4" || ext == "mov" else { return }

                DispatchQueue.main.async {
                    addVideo(url: url)
                }
            }
        }
    }

    private func addVideo(url: URL) {
        guard !videoManager.videos.contains(where: { $0.url == url }) else { return }

        let videoItem = VideoItem(url: url)
        videoItem.configuration = videoManager.globalConfiguration
        videoManager.videos.append(videoItem)

        Task.detached(priority: .utility) { [weak videoManager] in
            await VideoMetadataLoader.loadMetadata(for: videoItem)
            await MainActor.run {
                videoManager?.objectWillChange.send()
            }
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
            addVideo(url: url)
        }
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func sendCompletionNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Video Shorts Factory"
        content.body = "\(videoManager.clipsCompleted) clips generated successfully."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
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
    @State private var showOverride = false

    private var statusIcon: String {
        switch video.state {
        case .completed: return "checkmark.circle.fill"
        case .failed: return "exclamationmark.circle.fill"
        case .processing: return "circle.dotted"
        case .queued: return "clock"
        default: return "film"
        }
    }

    private var statusColor: Color {
        switch video.state {
        case .completed: return .green
        case .failed: return .red
        case .processing: return .orange
        case .queued: return .blue
        default: return .secondary
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 8) {
                Image(systemName: statusIcon)
                    .font(.caption)
                    .foregroundColor(statusColor)
                    .frame(width: 16)

                Text(video.fileName)
                    .font(.system(.caption, design: .monospaced))
                    .lineLimit(1)
                    .truncationMode(.middle)

                if video.hasCustomConfig {
                    Image(systemName: "slider.horizontal.3")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }

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
                    showOverride.toggle()
                } label: {
                    Image(systemName: "gearshape")
                        .font(.caption2)
                        .foregroundColor(video.hasCustomConfig ? .orange : Color(nsColor: .tertiaryLabelColor))
                }
                .buttonStyle(.plain)
                .disabled(videoManager.isProcessing)

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

            if video.state == .failed, let error = video.errorMessage {
                Text(error)
                    .font(.caption2)
                    .foregroundColor(.red)
                    .lineLimit(1)
                    .padding(.leading, 24)
            }

            if showOverride && !videoManager.isProcessing {
                VideoOverridePanel(video: video, videoManager: videoManager)
                    .padding(.leading, 24)
                    .padding(.top, 4)
            }
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

private struct VideoOverridePanel: View {
    let video: VideoItem
    @ObservedObject var videoManager: VideoManager

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Text("Clips")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Stepper("\(video.clipQuantity)", value: $videoQuantity, in: 1...50)
                        .font(.caption2)
                }

                HStack(spacing: 4) {
                    Text("Duration")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Stepper("\(video.clipDuration)s", value: $videoDuration, in: 5...60)
                        .font(.caption2)
                }

                Spacer()

                Button("Reset") {
                    video.configuration = videoManager.globalConfiguration
                    video.hasCustomConfig = false
                    videoManager.objectWillChange.send()
                }
                .font(.caption2)
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
            }
        }
        .padding(6)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(4)
    }

    private var videoQuantity: Binding<Int> {
        Binding(
            get: { video.clipQuantity },
            set: {
                video.clipQuantity = $0
                video.hasCustomConfig = true
                videoManager.objectWillChange.send()
            }
        )
    }

    private var videoDuration: Binding<Int> {
        Binding(
            get: { video.clipDuration },
            set: {
                video.clipDuration = $0
                video.hasCustomConfig = true
                videoManager.objectWillChange.send()
            }
        )
    }
}

// MARK: - (2) Clip Settings

private struct ClipSettingsSection: View {
    @ObservedObject var videoManager: VideoManager
    @State private var showAdvanced = false

    var body: some View {
        WizardSection(
            number: 2,
            title: "Clip Settings",
            state: .ready
        ) {
            VStack(spacing: 10) {
                HStack(spacing: 6) {
                    ForEach(ConfigPreset.builtIn) { preset in
                        Button {
                            videoManager.applyPreset(preset)
                        } label: {
                            HStack(spacing: 3) {
                                Image(systemName: preset.icon)
                                Text(preset.name)
                            }
                            .font(.caption2)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.mini)
                        .disabled(videoManager.isProcessing)
                    }
                    Spacer()
                }

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

                HStack(spacing: 6) {
                    Text("Title")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 50, alignment: .leading)
                    TextField("Optional title", text: titleBinding)
                        .textFieldStyle(.roundedBorder)
                        .font(.caption)
                        .disabled(videoManager.isProcessing)
                }

                HStack(spacing: 6) {
                    Text("Tags")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 50, alignment: .leading)
                    TextField("#shorts #fyp", text: hashtagsBinding)
                        .textFieldStyle(.roundedBorder)
                        .font(.caption)
                        .disabled(videoManager.isProcessing)
                }

                Divider()

                DisclosureGroup("Advanced", isExpanded: $showAdvanced) {
                    VStack(spacing: 8) {
                        HStack(spacing: 16) {
                            HStack(spacing: 6) {
                                Text("Selection")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Picker("", selection: selectionModeBinding) {
                                    ForEach(ClipSelectionMode.allCases, id: \.self) { mode in
                                        Text(mode.rawValue).tag(mode)
                                    }
                                }
                                .labelsHidden()
                                .pickerStyle(.segmented)
                                .frame(width: 140)
                                .disabled(videoManager.isProcessing)
                            }

                            Spacer()
                        }

                        HStack(spacing: 16) {
                            HStack(spacing: 6) {
                                Text("Resolution")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Picker("", selection: resolutionBinding) {
                                    ForEach(OutputResolution.allCases, id: \.self) { res in
                                        Text(res.label).tag(res)
                                    }
                                }
                                .labelsHidden()
                                .frame(width: 80)
                                .disabled(videoManager.isProcessing)
                            }

                            HStack(spacing: 6) {
                                Text("Bitrate")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Picker("", selection: bitrateBinding) {
                                    ForEach(VideoBitrate.allCases, id: \.self) { br in
                                        Text(br.label).tag(br)
                                    }
                                }
                                .labelsHidden()
                                .frame(width: 90)
                                .disabled(videoManager.isProcessing)
                            }

                            Toggle("Audio", isOn: audioBinding)
                                .font(.caption)
                                .toggleStyle(.checkbox)
                                .disabled(videoManager.isProcessing)

                            Spacer()
                        }

                        HStack(spacing: 6) {
                            Text("Naming")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(width: 50, alignment: .leading)
                            TextField("{name}_clip_{clip}", text: namingBinding)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(.caption, design: .monospaced))
                                .disabled(videoManager.isProcessing)
                        }

                        Text("Tokens: {name} {date} {clip}")
                            .font(.caption2)
                            .foregroundColor(Color(nsColor: .tertiaryLabelColor))
                            .frame(maxWidth: .infinity, alignment: .trailing)

                        HStack(spacing: 6) {
                            Text("Parallel jobs")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Stepper(
                                "\(videoManager.concurrentJobs)",
                                value: concurrentJobsBinding,
                                in: 1...4
                            )
                            .font(.caption)
                            .disabled(videoManager.isProcessing)
                            Spacer()
                        }
                    }
                    .padding(.top, 6)
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
    }

    private var quantityBinding: Binding<Int> {
        Binding(
            get: { videoManager.globalConfiguration.quantity },
            set: { videoManager.globalConfiguration.quantity = $0; save() }
        )
    }

    private var durationBinding: Binding<Int> {
        Binding(
            get: { videoManager.globalConfiguration.duration },
            set: { videoManager.globalConfiguration.duration = $0; save() }
        )
    }

    private var titleBinding: Binding<String> {
        Binding(
            get: { videoManager.globalConfiguration.baseTitle },
            set: { videoManager.globalConfiguration.baseTitle = $0; save() }
        )
    }

    private var hashtagsBinding: Binding<String> {
        Binding(
            get: { videoManager.globalConfiguration.hashtags },
            set: { videoManager.globalConfiguration.hashtags = $0; save() }
        )
    }

    private var selectionModeBinding: Binding<ClipSelectionMode> {
        Binding(
            get: { videoManager.globalConfiguration.selectionMode },
            set: { videoManager.globalConfiguration.selectionMode = $0; save() }
        )
    }

    private var resolutionBinding: Binding<OutputResolution> {
        Binding(
            get: { videoManager.globalConfiguration.resolution },
            set: { videoManager.globalConfiguration.resolution = $0; save() }
        )
    }

    private var bitrateBinding: Binding<VideoBitrate> {
        Binding(
            get: { videoManager.globalConfiguration.bitrate },
            set: { videoManager.globalConfiguration.bitrate = $0; save() }
        )
    }

    private var audioBinding: Binding<Bool> {
        Binding(
            get: { videoManager.globalConfiguration.includeAudio },
            set: { videoManager.globalConfiguration.includeAudio = $0; save() }
        )
    }

    private var namingBinding: Binding<String> {
        Binding(
            get: { videoManager.globalConfiguration.namingTemplate },
            set: { videoManager.globalConfiguration.namingTemplate = $0; save() }
        )
    }

    private var concurrentJobsBinding: Binding<Int> {
        Binding(
            get: { videoManager.concurrentJobs },
            set: { videoManager.concurrentJobs = $0; videoManager.saveSettings() }
        )
    }

    private func save() {
        videoManager.saveSettings()
        for video in videoManager.videos where !video.hasCustomConfig {
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
                    HStack(spacing: 8) {
                        Text("\(videoManager.clipsCompleted) clips generated")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        if videoManager.clipsFailed > 0 {
                            Text("\(videoManager.clipsFailed) failed")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
                Spacer()
            }

            HStack(spacing: 8) {
                Button {
                    videoManager.openOutputFolder()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "folder")
                        Text("Open")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                if videoManager.clipsFailed > 0 {
                    Button {
                        videoManager.retryFailed()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.clockwise")
                            Text("Retry")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .tint(.orange)
                }

                Menu {
                    Button("Export JSON") { exportJSON() }
                    Button("Export CSV") { exportCSV() }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "square.and.arrow.up")
                        Text("Export")
                    }
                    .frame(maxWidth: .infinity)
                }
                .menuStyle(.borderlessButton)
                .frame(maxWidth: .infinity)

                Button {
                    videoManager.startNewBatch()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle")
                        Text("New Batch")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding(12)
        .background(Color.green.opacity(0.08))
        .cornerRadius(8)
    }

    private func exportJSON() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "clips_metadata.json"
        if panel.runModal() == .OK, let url = panel.url {
            videoManager.exportMetadataJSON(to: url)
        }
    }

    private func exportCSV() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.commaSeparatedText]
        panel.nameFieldStringValue = "clips_metadata.csv"
        if panel.runModal() == .OK, let url = panel.url {
            videoManager.exportMetadataCSV(to: url)
        }
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
