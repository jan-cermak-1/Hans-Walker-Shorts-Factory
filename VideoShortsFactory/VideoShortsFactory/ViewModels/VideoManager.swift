import Foundation
import SwiftUI

class VideoManager: ObservableObject {

    @Published var videos: [VideoItem] = []
    @Published var isProcessing: Bool = false
    @Published var masterProgress: Double = 0.0
    @Published var estimatedTimeRemaining: TimeInterval?
    @Published var totalClipsToGenerate: Int = 0
    @Published var clipsCompleted: Int = 0
    @Published var currentOutputURL: URL?
    @Published var globalConfiguration: ClipConfiguration = ClipConfiguration()
    @Published var batchCompleted: Bool = false

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
        UserDefaults.standard.set(globalConfiguration.quantity, forKey: "clipQuantity")
        UserDefaults.standard.set(globalConfiguration.duration, forKey: "clipDuration")
        UserDefaults.standard.set(globalConfiguration.baseTitle, forKey: "clipBaseTitle")
        UserDefaults.standard.set(globalConfiguration.hashtags, forKey: "clipHashtags")
    }

    private func loadSettings() {
        let q = UserDefaults.standard.integer(forKey: "clipQuantity")
        let d = UserDefaults.standard.integer(forKey: "clipDuration")
        globalConfiguration.quantity = q > 0 ? q : 10
        globalConfiguration.duration = d > 0 ? d : 30
        globalConfiguration.baseTitle = UserDefaults.standard.string(forKey: "clipBaseTitle") ?? ""
        globalConfiguration.hashtags = UserDefaults.standard.string(forKey: "clipHashtags") ?? ""
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

    // MARK: - Video Management

    func removeVideo(_ video: VideoItem) {
        videos.removeAll { $0.id == video.id }
    }

    func startNewBatch() {
        videos.removeAll()
        batchCompleted = false
        clipsCompleted = 0
        totalClipsToGenerate = 0
        masterProgress = 0.0
        estimatedTimeRemaining = nil
    }

    // MARK: - Processing

    func startBatchProcessing() {
        guard !isProcessing else { return }
        guard !videos.isEmpty else { return }

        guard let outputURL = globalConfiguration.outputFolder else { return }

        let diskCheck = DiskSpaceChecker.shared.canProcessVideos(videos, at: outputURL)
        guard diskCheck.canProcess else {
            print("Disk space check failed: \(diskCheck.message)")
            return
        }

        batchCompleted = false
        isProcessing = true
        isCancelled = false
        processingStartTime = Date()
        clipProcessingTimes.removeAll()

        totalClipsToGenerate = videos.reduce(0) { $0 + $1.configuration.quantity }
        clipsCompleted = 0
        masterProgress = 0.0
        currentOutputURL = outputURL

        for video in videos {
            video.state = .queued
            video.progress = 0.0
            video.currentClip = 0
            video.totalClips = video.configuration.quantity
        }

        SleepPrevention.shared.beginActivity(reason: "Processing video shorts")

        Task {
            await processVideosSequentially()
        }
    }

    func stopProcessing() {
        guard isProcessing else { return }

        isCancelled = true
        FFmpegService.shared.cancelCurrentProcess()

        for video in videos where video.state == .processing || video.state == .queued {
            video.state = .cancelled
        }

        cleanupProcessing()
    }

    private func processVideosSequentially() async {
        for video in videos {
            guard !isCancelled else { break }

            video.state = .processing

            await withCheckedContinuation { continuation in
                processVideo(video) { _ in
                    continuation.resume()
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
                    case .success:
                        processedClips += 1
                        DispatchQueue.main.async {
                            self.clipsCompleted += 1
                            self.updateMasterProgress()
                            self.updateETA()
                        }
                        processNextClip()

                    case .failure(let error):
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

        estimatedTimeRemaining = avgProcessingTime * Double(remainingClips)
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
