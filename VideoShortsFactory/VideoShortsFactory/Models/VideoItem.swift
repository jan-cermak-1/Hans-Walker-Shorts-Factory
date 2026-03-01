import Foundation

class VideoItem: Identifiable {
    let id: UUID
    let url: URL
    let fileName: String
    var fileSize: Int64 = 0
    var bookmarkData: Data?
    
    var stateRaw: String = "Idle"
    var progress: Double = 0.0
    var currentClip: Int = 0
    var totalClips: Int = 0
    var errorMessage: String?
    
    var clipQuantity: Int = 10
    var clipDuration: Int = 30
    var baseTitle: String = ""
    var hashtags: String = ""
    var outputFolder: URL?
    var selectionMode: ClipSelectionMode = .random
    var resolution: OutputResolution = .hd1080
    var bitrate: VideoBitrate = .high
    var includeAudio: Bool = true
    var namingTemplate: String = "{name}_clip_{clip}"
    var hasCustomConfig: Bool = false
    
    var durationSeconds: Double?
    var videoWidth: Double?
    var videoHeight: Double?
    
    init(url: URL) {
        self.id = UUID()
        self.url = url
        self.fileName = url.lastPathComponent
    }
    
    var state: ProcessingState {
        get { ProcessingState(rawValue: stateRaw) ?? .idle }
        set { stateRaw = newValue.rawValue }
    }
    
    var configuration: ClipConfiguration {
        get {
            ClipConfiguration(
                quantity: clipQuantity,
                duration: clipDuration,
                baseTitle: baseTitle,
                hashtags: hashtags,
                outputFolder: outputFolder,
                selectionMode: selectionMode,
                resolution: resolution,
                bitrate: bitrate,
                includeAudio: includeAudio,
                namingTemplate: namingTemplate
            )
        }
        set {
            clipQuantity = newValue.quantity
            clipDuration = newValue.duration
            baseTitle = newValue.baseTitle
            hashtags = newValue.hashtags
            outputFolder = newValue.outputFolder
            selectionMode = newValue.selectionMode
            resolution = newValue.resolution
            bitrate = newValue.bitrate
            includeAudio = newValue.includeAudio
            namingTemplate = newValue.namingTemplate
        }
    }
    
    var durationString: String {
        guard let dur = durationSeconds else { return "Unknown" }
        let seconds = Int(dur)
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
    
    var fileSizeString: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }
}
