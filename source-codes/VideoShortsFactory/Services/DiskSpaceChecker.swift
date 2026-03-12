import Foundation

class DiskSpaceChecker {
    
    static let shared = DiskSpaceChecker()
    
    private init() {}
    
    private let minimumRequiredSpace: Int64 = 5_000_000_000
    
    func checkAvailableSpace(at url: URL) -> Result<Int64, DiskSpaceError> {
        do {
            let values = try url.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
            
            if let availableSpace = values.volumeAvailableCapacityForImportantUsage {
                return .success(availableSpace)
            }
            
            let attributes = try FileManager.default.attributesOfFileSystem(forPath: url.path)
            if let freeSpace = attributes[.systemFreeSize] as? Int64 {
                return .success(freeSpace)
            }
            
            return .failure(.unableToCheck)
        } catch {
            return .failure(.checkFailed(error))
        }
    }
    
    func hasEnoughSpace(at url: URL) -> Bool {
        switch checkAvailableSpace(at: url) {
        case .success(let availableSpace):
            return availableSpace >= minimumRequiredSpace
        case .failure:
            return false
        }
    }
    
    func getAvailableSpaceString(at url: URL) -> String {
        switch checkAvailableSpace(at: url) {
        case .success(let availableSpace):
            return formatBytes(availableSpace)
        case .failure(let error):
            return "Error: \(error.localizedDescription)"
        }
    }
    
    func estimateRequiredSpace(for videoItems: [VideoItem]) -> Int64 {
        var totalEstimate: Int64 = 0
        
        for item in videoItems {
            let clipsCount = Int64(item.configuration.quantity)
            let clipDuration = Double(item.configuration.duration)
            
            guard let totalDuration = item.durationSeconds, totalDuration > 0 else {
                totalEstimate += clipsCount * 50_000_000
                continue
            }
            
            let estimatedBitrate: Int64 = 15_000_000 / 8
            let estimatedClipSize = Int64(clipDuration) * estimatedBitrate
            let audioOverhead: Int64 = 5_000_000
            
            totalEstimate += clipsCount * (estimatedClipSize + audioOverhead)
        }
        
        let safetyMargin = Int64(Double(totalEstimate) * 1.2)
        return safetyMargin
    }
    
    func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB]
        formatter.countStyle = .file
        formatter.includesUnit = true
        return formatter.string(fromByteCount: bytes)
    }
    
    func canProcessVideos(_ videoItems: [VideoItem], at outputURL: URL) -> (canProcess: Bool, message: String) {
        guard !videoItems.isEmpty else {
            return (false, "No videos to process")
        }
        
        let requiredSpace = estimateRequiredSpace(for: videoItems)
        
        switch checkAvailableSpace(at: outputURL) {
        case .success(let availableSpace):
            if availableSpace < requiredSpace {
                let available = formatBytes(availableSpace)
                let required = formatBytes(requiredSpace)
                return (false, "Not enough disk space.\n\nAvailable: \(available)\nRequired: ~\(required)")
            }
            
            return (true, "Sufficient disk space available")
            
        case .failure(let error):
            return (false, "Unable to check disk space: \(error.localizedDescription)")
        }
    }
}

enum DiskSpaceError: LocalizedError {
    case unableToCheck
    case checkFailed(Error)
    case insufficientSpace(available: Int64, required: Int64)
    
    var errorDescription: String? {
        switch self {
        case .unableToCheck:
            return "Unable to check available disk space"
        case .checkFailed(let error):
            return "Disk space check failed: \(error.localizedDescription)"
        case .insufficientSpace(let available, let required):
            let formatter = ByteCountFormatter()
            formatter.allowedUnits = [.useGB, .useMB]
            formatter.countStyle = .file
            let availableStr = formatter.string(fromByteCount: available)
            let requiredStr = formatter.string(fromByteCount: required)
            return "Insufficient disk space. Available: \(availableStr), Required: \(requiredStr)"
        }
    }
}
