import Foundation

enum ProcessingState: String, Codable {
    case idle = "Idle"
    case queued = "Queued"
    case processing = "Processing"
    case completed = "Completed"
    case failed = "Failed"
    case cancelled = "Cancelled"
    
    var color: String {
        switch self {
        case .idle: return "gray"
        case .queued: return "blue"
        case .processing: return "orange"
        case .completed: return "green"
        case .failed: return "red"
        case .cancelled: return "gray"
        }
    }
}
