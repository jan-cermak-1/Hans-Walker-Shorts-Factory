import Foundation
import AVFoundation

class FFmpegService {
    
    static let shared = FFmpegService()
    
    private var currentProcess: Process?
    private var ffmpegPath: String
    
    private init() {
        if let bundledPath = Bundle.main.path(forResource: "ffmpeg", ofType: nil) {
            self.ffmpegPath = bundledPath
        } else if FileManager.default.fileExists(atPath: "/opt/homebrew/bin/ffmpeg") {
            self.ffmpegPath = "/opt/homebrew/bin/ffmpeg"
        } else if FileManager.default.fileExists(atPath: "/usr/local/bin/ffmpeg") {
            self.ffmpegPath = "/usr/local/bin/ffmpeg"
        } else {
            self.ffmpegPath = "ffmpeg"
        }
        
        print("FFmpeg path: \(ffmpegPath)")
    }
    
    func generateClip(
        from videoItem: VideoItem,
        clipNumber: Int,
        outputURL: URL,
        progressCallback: @escaping (Double) -> Void,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        // Start accessing security-scoped resources
        let videoAccessStarted = videoItem.url.startAccessingSecurityScopedResource()
        let outputAccessStarted = outputURL.startAccessingSecurityScopedResource()
        
        guard let totalSeconds = videoItem.durationSeconds else {
            if videoAccessStarted { videoItem.url.stopAccessingSecurityScopedResource() }
            if outputAccessStarted { outputURL.stopAccessingSecurityScopedResource() }
            completion(.failure(FFmpegError.invalidDuration))
            return
        }
        
        let clipDuration = videoItem.configuration.duration
        
        guard totalSeconds > Double(clipDuration) else {
            if videoAccessStarted { videoItem.url.stopAccessingSecurityScopedResource() }
            if outputAccessStarted { outputURL.stopAccessingSecurityScopedResource() }
            completion(.failure(FFmpegError.videoTooShort))
            return
        }
        
        let maxStartTime = max(0, totalSeconds - Double(clipDuration))
        let videoStartTime = Double.random(in: 0...maxStartTime)
        
        let outputFileName = String(format: "%@_clip_%03d.mp4", 
                                    videoItem.url.deletingPathExtension().lastPathComponent,
                                    clipNumber)
        let videoOutputURL = outputURL.appendingPathComponent(outputFileName)
        
        let arguments = [
            "-ss", String(format: "%.2f", videoStartTime),
            "-i", videoItem.url.path,
            "-t", "\(clipDuration)",
            "-vf", "crop=ih*9/16:ih,scale=1080:1920",
            "-c:v", "h264_videotoolbox",
            "-b:v", "15M",
            "-c:a", "copy",
            "-y",
            videoOutputURL.path
        ]
        
        let processingStartTime = Date()
        print("🎬 Starting clip \(clipNumber) from \(videoItem.fileName) at \(String(format: "%.2f", videoStartTime))s")
        print("   FFmpeg: \(arguments.joined(separator: " "))")
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: ffmpegPath)
        process.arguments = arguments
        
        let errorPipe = Pipe()
        process.standardError = errorPipe
        process.standardOutput = Pipe()
        
        currentProcess = process
        
        var lastProgress: Double = 0
        var progressUpdateCount = 0
        
        errorPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty,
                  let output = String(data: data, encoding: .utf8) else { return }
            
            if let progress = self.parseProgress(from: output, totalDuration: Double(clipDuration)) {
                if progress > lastProgress {
                    lastProgress = progress
                    progressUpdateCount += 1
                    DispatchQueue.main.async {
                        progressCallback(progress)
                    }
                }
            }
        }
        
        process.terminationHandler = { process in
            errorPipe.fileHandleForReading.readabilityHandler = nil
            
            let elapsed = Date().timeIntervalSince(processingStartTime)
            
            // Stop accessing security-scoped resources
            if videoAccessStarted { videoItem.url.stopAccessingSecurityScopedResource() }
            if outputAccessStarted { outputURL.stopAccessingSecurityScopedResource() }
            
            if process.terminationStatus == 0 {
                print("✅ Clip \(clipNumber) completed in \(String(format: "%.2f", elapsed))s (\(progressUpdateCount) progress updates)")
                
                self?.createMetadataFile(
                    for: videoOutputURL,
                    clipNumber: clipNumber,
                    configuration: videoItem.configuration
                )
                
                DispatchQueue.main.async {
                    completion(.success(videoOutputURL))
                }
            } else {
                let errorDescription = process.terminationReason == .exit 
                    ? "FFmpeg process failed with exit code \(process.terminationStatus)"
                    : "FFmpeg process was interrupted"
                
                print("❌ Clip \(clipNumber) failed after \(String(format: "%.2f", elapsed))s: \(errorDescription)")
                
                DispatchQueue.main.async {
                    completion(.failure(FFmpegError.processingFailed(errorDescription)))
                }
            }
        }
        
        do {
            try process.run()
        } catch {
            if videoAccessStarted { videoItem.url.stopAccessingSecurityScopedResource() }
            if outputAccessStarted { outputURL.stopAccessingSecurityScopedResource() }
            completion(.failure(FFmpegError.failedToStart(error)))
        }
    }
    
    func cancelCurrentProcess() {
        currentProcess?.terminate()
        currentProcess = nil
    }
    
    private func parseProgress(from output: String, totalDuration: Double) -> Double? {
        let pattern = "time=(\\d{2}):(\\d{2}):(\\d{2})\\.(\\d{2})"
        
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: output, range: NSRange(output.startIndex..., in: output)) else {
            return nil
        }
        
        guard let hoursRange = Range(match.range(at: 1), in: output),
              let minutesRange = Range(match.range(at: 2), in: output),
              let secondsRange = Range(match.range(at: 3), in: output),
              let millisecondsRange = Range(match.range(at: 4), in: output) else {
            return nil
        }
        
        let hours = Double(output[hoursRange]) ?? 0
        let minutes = Double(output[minutesRange]) ?? 0
        let seconds = Double(output[secondsRange]) ?? 0
        let milliseconds = Double(output[millisecondsRange]) ?? 0
        
        let currentTime = hours * 3600 + minutes * 60 + seconds + milliseconds / 100
        let progress = min(currentTime / totalDuration, 1.0)
        
        return progress
    }
    
    private func createMetadataFile(for videoURL: URL, clipNumber: Int, configuration: ClipConfiguration) {
        let metadataURL = videoURL.deletingPathExtension().appendingPathExtension("txt")
        
        let title = configuration.baseTitle.isEmpty 
            ? "Clip \(clipNumber)" 
            : "\(configuration.baseTitle) - Clip \(clipNumber)"
        
        var content = title + "\n"
        
        if !configuration.hashtags.isEmpty {
            content += "\n" + configuration.hashtags
        }
        
        do {
            try content.write(to: metadataURL, atomically: true, encoding: .utf8)
            print("Created metadata file: \(metadataURL.path)")
        } catch {
            print("Failed to create metadata file: \(error)")
        }
    }
    
    func verifyFFmpegAvailability() -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: ffmpegPath)
        process.arguments = ["-version"]
        process.standardOutput = Pipe()
        process.standardError = Pipe()
        
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            print("FFmpeg verification failed: \(error)")
            return false
        }
    }
}

enum FFmpegError: LocalizedError {
    case invalidDuration
    case videoTooShort
    case processingFailed(String)
    case failedToStart(Error)
    case ffmpegNotFound
    
    var errorDescription: String? {
        switch self {
        case .invalidDuration:
            return "Unable to determine video duration"
        case .videoTooShort:
            return "Video is shorter than the requested clip duration"
        case .processingFailed(let message):
            return "Processing failed: \(message)"
        case .failedToStart(let error):
            return "Failed to start FFmpeg: \(error.localizedDescription)"
        case .ffmpegNotFound:
            return "FFmpeg binary not found"
        }
    }
}
