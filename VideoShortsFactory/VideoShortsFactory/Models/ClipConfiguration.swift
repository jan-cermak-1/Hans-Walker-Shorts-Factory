import Foundation

enum ClipSelectionMode: String, Codable, CaseIterable {
    case random = "Random"
    case uniform = "Uniform"
}

enum OutputResolution: String, Codable, CaseIterable {
    case hd1080 = "1080x1920"
    case hd720 = "720x1280"

    var width: Int {
        switch self {
        case .hd1080: return 1080
        case .hd720: return 720
        }
    }

    var height: Int {
        switch self {
        case .hd1080: return 1920
        case .hd720: return 1280
        }
    }

    var label: String {
        switch self {
        case .hd1080: return "1080p"
        case .hd720: return "720p"
        }
    }
}

enum VideoBitrate: String, Codable, CaseIterable {
    case low = "8M"
    case medium = "12M"
    case high = "15M"
    case ultra = "20M"

    var label: String {
        switch self {
        case .low: return "8 Mbps"
        case .medium: return "12 Mbps"
        case .high: return "15 Mbps"
        case .ultra: return "20 Mbps"
        }
    }
}

struct ClipConfiguration: Codable {
    var quantity: Int = 10
    var duration: Int = 30
    var baseTitle: String = ""
    var hashtags: String = ""
    var outputFolder: URL?
    var selectionMode: ClipSelectionMode = .random
    var resolution: OutputResolution = .hd1080
    var bitrate: VideoBitrate = .high
    var includeAudio: Bool = true
    var namingTemplate: String = "{name}_clip_{clip}"

    init(
        quantity: Int = 10,
        duration: Int = 30,
        baseTitle: String = "",
        hashtags: String = "",
        outputFolder: URL? = nil,
        selectionMode: ClipSelectionMode = .random,
        resolution: OutputResolution = .hd1080,
        bitrate: VideoBitrate = .high,
        includeAudio: Bool = true,
        namingTemplate: String = "{name}_clip_{clip}"
    ) {
        self.quantity = quantity
        self.duration = duration
        self.baseTitle = baseTitle
        self.hashtags = hashtags
        self.outputFolder = outputFolder
        self.selectionMode = selectionMode
        self.resolution = resolution
        self.bitrate = bitrate
        self.includeAudio = includeAudio
        self.namingTemplate = namingTemplate
    }

    func resolveFileName(videoName: String, clipNumber: Int) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let dateStr = dateFormatter.string(from: Date())

        return namingTemplate
            .replacingOccurrences(of: "{name}", with: videoName)
            .replacingOccurrences(of: "{date}", with: dateStr)
            .replacingOccurrences(of: "{clip}", with: String(format: "%03d", clipNumber))
    }
}
