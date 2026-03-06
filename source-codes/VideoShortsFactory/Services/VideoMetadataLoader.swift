import Foundation
import AVFoundation

enum VideoMetadataLoader {
    
    static func loadMetadata(for videoItem: VideoItem) async {
        let fileURL = videoItem.url
        let fileName = videoItem.fileName
        
        NSLog("📊 Starting metadata load for: %@", fileName)
        
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
            if let size = attributes[.size] as? Int64 {
                videoItem.fileSize = size
                NSLog("📦 File size loaded: %lld bytes", size)
            }
        } catch {
            NSLog("❌ Failed to load file size: %@", error.localizedDescription)
        }
        
        await loadVideoTracks(for: videoItem)
        NSLog("✅ Metadata load complete for: %@", fileName)
    }
    
    private static func loadVideoTracks(for videoItem: VideoItem) async {
        let asset = AVAsset(url: videoItem.url)
        
        do {
            let duration = try await asset.load(.duration)
            videoItem.durationSeconds = duration.seconds
            NSLog("⏱️ Duration loaded: %.1f seconds", duration.seconds)
            
            let tracks = try await asset.loadTracks(withMediaType: .video)
            
            if let videoTrack = tracks.first {
                let size = try await videoTrack.load(.naturalSize)
                let transform = try await videoTrack.load(.preferredTransform)
                
                let isPortrait = abs(transform.b) == 1.0 || abs(transform.d) == 1.0
                if isPortrait {
                    videoItem.videoWidth = Double(size.height)
                    videoItem.videoHeight = Double(size.width)
                } else {
                    videoItem.videoWidth = Double(size.width)
                    videoItem.videoHeight = Double(size.height)
                }
                NSLog("📹 Video size loaded: %.0fx%.0f", videoItem.videoWidth ?? 0, videoItem.videoHeight ?? 0)
            }
        } catch {
            NSLog("❌ Failed to load video metadata for %@: %@", videoItem.fileName, error.localizedDescription)
        }
    }
}
