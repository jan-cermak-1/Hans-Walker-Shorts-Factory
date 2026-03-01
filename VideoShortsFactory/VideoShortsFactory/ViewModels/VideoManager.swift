import Foundation
import SwiftUI

class VideoManager: ObservableObject {

    @Published var videos: [VideoItem] = []
    @Published var isProcessing: Bool = false
    @Published var masterProgress: Double = 0.0
    @Published var estimatedTimeRemaining: TimeInterval?
    @Published var totalClipsToGenerate: Int = 0
    @Published var clipsCompleted: Int = 0
    @Published var clipsFailed: Int = 0
    @Published var currentOutputURL: URL?
    @Published var globalConfiguration: ClipConfiguration = ClipConfiguration()
    @Published var batchCompleted: Bool = false
    @Published var showErrorAlert: Bool = false
    @Published var errorMessage: String = ""
    @Published var generatedClipPaths: [URL] = []
    @Published var concurrentJobs: Int = 2

    private var isCancelled = false
    private var processingStartTime: Date?
    private var clipProcessingTimes: [TimeInterval] = []
    private let maxHistorySize = 5
    private let initialSpeedFactor: Double = 5.0

    init() {
        loadSettings()
        loadOutputFolder()
    }

    // MARK: - Persistence

    func saveSettings() {
        let ud = UserDefaults.standard
        ud.set(globalConfiguration.quantity, forKey: "clipQuantity")
        ud.set(globalConfiguration.duration, forKey: "clipDuration")
        ud.set(globalConfiguration.baseTitle, forKey: "clipBaseTitle")
        ud.set(globalConfiguration.hashtags, forKey: "clipHashtags")
        ud.set(globalConfiguration.selectionMode.rawValue, forKey: "selectionMode")
        ud.set(globalConfiguration.resolution.rawValue, forKey: "resolution")
        ud.set(globalConfiguration.bitrate.rawValue, forKey: "bitrate")
        ud.set(globalConfiguration.includeAudio, forKey: "includeAudio")
        ud.set(globalConfiguration.namingTemplate, forKey: "namingTemplate")
        ud.set(concurrentJobs, forKey: "concurrentJobs")
    }

    private func loadSettings() {
        let ud = UserDefaults.standard
        let q = ud.integer(forKey: "clipQuantity")
        let d = ud.integer(forKey: "clipDuration")
        globalConfiguration.quantity = q > 0 ? q : 10
        globalConfiguration.duration = d > 0 ? d : 30
        globalConfiguration.baseTitle = ud.string(forKey: "clipBaseTitle") ?? ""
        globalConfiguration.hashtags = ud.string(forKey: "clipHashtags") ?? ""

        if let mode = ud.string(forKey: "selectionMode"),
           let parsed = ClipSelectionMode(rawValue: mode) {
            globalConfiguration.selectionMode = parsed
        }
        if let res = ud.string(forKey: "resolution"),
           let parsed = OutputResolution(rawValue: res) {
            globalConfiguration.resolution = parsed
        }
        if let br = ud.string(forKey: "bitrate"),
           let parsed = VideoBitrate(rawValue: br) {
            globalConfiguration.bitrate = parsed
        }
        if ud.object(forKey: "includeAudio") != nil {
            globalConfiguration.includeAudio = ud.bool(forKey: "includeAudio")
        }
        if let tmpl = ud.string(forKey: "namingTemplate"), !tmpl.isEmpty {
            globalConfiguration.namingTemplate = tmpl
        }
        let jobs = ud.integer(forKey: "concurrentJobs")
        concurrentJobs = jobs > 0 ? min(jobs, 4) : 2
    }

    func saveOutputFolder() {
        if let folder = globalConfiguration.outputFolder {
            do {
                let bookmark = try folder.bookmarkData(
                    options: .withSecurityScope,
                    includingResourceValuesForKeys: nil,
                    relativeTo: nil
                )
                UserDefaults.standard.set(bookmark, forKey: "outputFolderBookmark")
            } catch {
                UserDefaults.standard.set(folder.path, forKey: "outputFolderPath")
            }
        }
    }

    private func loadOutputFolder() {
        if let bookmarkData = UserDefaults.standard.data(forKey: "outputFolderBookmark") {
            var isStale = false
            if let url = try? URL(
                resolvingBookmarkData: bookmarkData,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            ) {
                _ = url.startAccessingSecurityScopedResource()
                globalConfiguration.outputFolder = url
                return
            }
        }

        if let path = UserDefaults.standard.string(forKey: "outputFolderPath") {
            let url = URL(fileURLWithPath: path)
            if FileManager.default.fileExists(atPath: path) {
                globalConfiguration.outputFolder = url
            }
        }
    }

    // MARK: - Presets

    func applyPreset(_ preset: ConfigPreset) {
        globalConfiguration.quantity = preset.quantity
        globalConfiguration.duration = preset.duration
        globalConfiguration.resolution = preset.resolution
        globalConfiguration.bitrate = preset.bitrate
        globalConfiguration.includeAudio = preset.includeAudio
        saveSettings()

        for video in videos where !video.hasCustomConfig {
            video.configuration = globalConfiguration
        }

        objectWillChange.send()
    }

    // MARK: - Video Management

    func removeVideo(_ video: VideoItem) {
        videos.removeAll { $0.id == video.id }
    }

    func startNewBatch() {
        videos.removeAll()
        batchCompleted = false
        clipsCompleted = 0
        clipsFailed = 0
        totalClipsToGenerate = 0
        masterProgress = 0.0
        estimatedTimeRemaining = nil
        generatedClipPaths.removeAll()
    }

    // MARK: - Export

    func exportMetadataJSON(to url: URL) {
        let items = generatedClipPaths.enumerated().map { idx, path -> [String: Any] in
            [
                "index": idx + 1,
                "file": path.lastPathComponent,
                "path": path.path,
                "title": globalConfiguration.baseTitle.isEmpty
                    ? "Clip \(idx + 1)"
                    : "\(globalConfiguration.baseTitle) - Clip \(idx + 1)",
                "hashtags": globalConfiguration.hashtags,
                "resolution": globalConfiguration.resolution.rawValue,
                "bitrate": globalConfiguration.bitrate.rawValue
            ]
        }

        if let data = try? JSONSerialization.data(withJSONObject: items, options: .prettyPrinted) {
            try? data.write(to: url)
        }
    }

    func exportMetadataCSV(to url: URL) {
        var csv = "index,file,title,hashtags,resolution,bitrate\n"
        for (idx, path) in generatedClipPaths.enumerated() {
            let title = globalConfiguration.baseTitle.isEmpty
                ? "Clip \(idx + 1)"
                : "\(globalConfiguration.baseTitle) - Clip \(idx + 1)"
            let escaped = title.replacingOccurrences(of: "\"", with: "\"\"")
            let tagsEscaped = globalConfiguration.hashtags.replacingOccurrences(of: "\"", with: "\"\"")
            csv += "\(idx + 1),\(path.lastPathComponent),\"\(escaped)\",\"\(tagsEscaped)\",\(globalConfiguration.resolution.rawValue),\(globalConfiguration.bitrate.rawValue)\n"
        }
        try? csv.write(to: url, atomically: true, encoding: .utf8)
    }

    // MARK: - Processing

    func startBatchProcessing() {
        guard !isProcessing else { return }

        guard !videos.isEmpty else {
            errorMessage = "Add at least one video before starting."
            showErrorAlert = true
            return
        }

        guard let outputURL = globalConfiguration.outputFolder else {
            errorMessage = "Please select an output folder first."
            showErrorAlert = true
            return
        }

        let tooShortVideos = videos.filter { video in
            if let dur = video.durationSeconds {
                return dur < Double(video.configuration.duration)
            }
            return false
        }
        if !tooShortVideos.isEmpty {
            let names = tooShortVideos.map(\.fileName).joined(separator: ", ")
            errorMessage = "These videos are shorter than the clip duration (\(globalConfiguration.duration)s): \(names)"
            showErrorAlert = true
            return
        }

        let diskCheck = DiskSpaceChecker.shared.canProcessVideos(videos, at: outputURL)
        guard diskCheck.canProcess else {
            errorMessage = diskCheck.message
            showErrorAlert = true
            return
        }

        batchCompleted = false
        isProcessing = true
        isCancelled = false
        processingStartTime = Date()
        clipProcessingTimes.removeAll()
        generatedClipPaths.removeAll()

        totalClipsToGenerate = videos.reduce(0) { $0 + $1.configuration.quantity }
        clipsCompleted = 0
        clipsFailed = 0
        masterProgress = 0.0
        currentOutputURL = outputURL

        for video in videos {
            video.state = .queued
            video.progress = 0.0
            video.currentClip = 0
            video.totalClips = video.configuration.quantity
            video.errorMessage = nil
        }

        SleepPrevention.shared.beginActivity(reason: "Processing video shorts")

        Task {
            await processVideosWithConcurrency()
        }
    }

    func retryFailed() {
        let failedVideos = videos.filter { $0.state == .failed }
        guard !failedVideos.isEmpty, let outputURL = globalConfiguration.outputFolder else { return }

        batchCompleted = false
        isProcessing = true
        isCancelled = false
        processingStartTime = Date()
        clipProcessingTimes.removeAll()
        currentOutputURL = outputURL

        let retryClips = failedVideos.reduce(0) { $0 + $1.configuration.quantity }
        totalClipsToGenerate = clipsCompleted + retryClips
        clipsFailed = 0

        for video in failedVideos {
            video.state = .queued
            video.progress = 0.0
            video.currentClip = 0
            video.errorMessage = nil
        }

        SleepPrevention.shared.beginActivity(reason: "Retrying failed video shorts")

        Task {
            await processVideosWithConcurrency(only: failedVideos)
        }
    }

    func stopProcessing() {
        guard isProcessing else { return }

        isCancelled = true
        FFmpegService.shared.cancelAllProcesses()

        for video in videos where video.state == .processing || video.state == .queued {
            video.state = .cancelled
        }

        cleanupProcessing()
    }

    private func processVideosWithConcurrency(only subset: [VideoItem]? = nil) async {
        let videosToProcess = subset ?? videos
        let semaphore = DispatchSemaphore(value: concurrentJobs)

        await withTaskGroup(of: Void.self) { group in
            for video in videosToProcess {
                guard !isCancelled else { break }

                group.addTask { [weak self] in
                    semaphore.wait()
                    defer { semaphore.signal() }

                    guard let self = self, !self.isCancelled else { return }

                    await MainActor.run {
                        video.state = .processing
                        self.objectWillChange.send()
                    }

                    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                        self.processVideo(video) { _ in
                            continuation.resume()
                        }
                    }
                }
            }
        }

        await MainActor.run {
            cleanupProcessing()
        }
    }

    private func processVideo(_ video: VideoItem, completion: @escaping (Bool) -> Void) {
        guard let outputURL = currentOutputURL else {
            video.state = .failed
            video.errorMessage = "Output folder not set"
            completion(false)
            return
        }

        let totalClips = video.configuration.quantity
        var processedClips = 0

        func processNextClip() {
            guard !isCancelled else {
                video.state = .cancelled
                completion(false)
                return
            }

            guard processedClips < totalClips else {
                video.state = .completed
                video.progress = 1.0
                completion(true)
                return
            }

            let clipNumber = processedClips + 1
            let clipStartTime = Date()

            video.currentClip = clipNumber

            FFmpegService.shared.generateClip(
                from: video,
                clipNumber: clipNumber,
                outputURL: outputURL,
                progressCallback: { [weak self] clipProgress in
                    guard let self = self else { return }

                    let videoProgress = (Double(processedClips) + clipProgress) / Double(totalClips)
                    video.progress = videoProgress

                    DispatchQueue.main.async {
                        self.updateMasterProgress()
                    }
                },
                completion: { [weak self] result in
                    guard let self = self else { return }

                    let clipDuration = Date().timeIntervalSince(clipStartTime)

                    self.clipProcessingTimes.append(clipDuration)
                    if self.clipProcessingTimes.count > self.maxHistorySize {
                        self.clipProcessingTimes.removeFirst()
                    }

                    switch result {
                    case .success(let clipURL):
                        processedClips += 1
                        DispatchQueue.main.async {
                            self.clipsCompleted += 1
                            self.generatedClipPaths.append(clipURL)
                            self.updateMasterProgress()
                            self.updateETA()
                        }
                        processNextClip()

                    case .failure(let error):
                        DispatchQueue.main.async {
                            self.clipsFailed += 1
                        }
                        video.state = .failed
                        video.errorMessage = error.localizedDescription
                        completion(false)
                    }
                }
            )
        }

        processNextClip()
    }

    private func updateMasterProgress() {
        guard totalClipsToGenerate > 0 else { return }
        masterProgress = Double(clipsCompleted) / Double(totalClipsToGenerate)
    }

    private func updateETA() {
        guard let _ = processingStartTime else { return }

        let remainingClips = totalClipsToGenerate - clipsCompleted
        guard remainingClips > 0 else {
            estimatedTimeRemaining = 0
            return
        }

        let avgProcessingTime: TimeInterval
        if clipProcessingTimes.isEmpty {
            let avgClipDuration = videos.reduce(0.0) { sum, video in
                sum + Double(video.configuration.duration)
            } / Double(videos.count)
            avgProcessingTime = avgClipDuration / initialSpeedFactor
        } else {
            avgProcessingTime = clipProcessingTimes.reduce(0, +) / Double(clipProcessingTimes.count)
        }

        let parallelFactor = Double(concurrentJobs)
        estimatedTimeRemaining = (avgProcessingTime * Double(remainingClips)) / parallelFactor
    }

    private func cleanupProcessing() {
        isProcessing = false
        SleepPrevention.shared.endActivity()

        if !isCancelled && clipsCompleted > 0 {
            batchCompleted = true
        }

        processingStartTime = nil
    }

    func openOutputFolder() {
        guard let outputURL = globalConfiguration.outputFolder else { return }
        NSWorkspace.shared.open(outputURL)
    }

    var estimatedTimeRemainingString: String {
        guard let eta = estimatedTimeRemaining else {
            return "Calculating..."
        }

        if eta < 60 {
            return String(format: "%.0f seconds", eta)
        } else if eta < 3600 {
            let minutes = Int(eta / 60)
            let seconds = Int(eta.truncatingRemainder(dividingBy: 60))
            return String(format: "%d min %d sec", minutes, seconds)
        } else {
            let hours = Int(eta / 3600)
            let minutes = Int((eta.truncatingRemainder(dividingBy: 3600)) / 60)
            return String(format: "%d hr %d min", hours, minutes)
        }
    }

    var processingStatusString: String {
        if !isProcessing {
            return "Ready"
        }
        return "Processing \(clipsCompleted) of \(totalClipsToGenerate) clips"
    }
}
