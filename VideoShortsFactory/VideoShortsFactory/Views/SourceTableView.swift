import SwiftUI
import AppKit

struct SourceTableView: View {
    @ObservedObject var videoManager: VideoManager
    @State private var selection = Set<VideoItem.ID>()
    
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
        
        processSelectedFiles(panel.urls)
    }
    
    private func processSelectedFiles(_ urls: [URL]) {
        let videoManager = self.videoManager
        
        for url in urls {
            let ext = url.pathExtension.lowercased()
            guard ext == "mp4" || ext == "mov" else { continue }
            
            guard !videoManager.videos.contains(where: { $0.url == url }) else { continue }
            
            let videoItem = VideoItem(url: url)
            videoItem.configuration = videoManager.globalConfiguration
            videoManager.videos.append(videoItem)
        }
        
        // Load metadata in background, refresh UI on main thread when done
        for videoItem in videoManager.videos where videoItem.durationSeconds == nil {
            Task.detached(priority: .utility) { [weak videoManager] in
                await VideoMetadataLoader.loadMetadata(for: videoItem)
                
                await MainActor.run {
                    videoManager?.objectWillChange.send()
                }
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Source Videos")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    openFilePicker()
                }) {
                    Label("Add Videos", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.bordered)
                .disabled(videoManager.isProcessing)
            }
            .padding()
            
            ZStack {
                Table(videoManager.videos, selection: $selection) {
                    TableColumn("File Name") { video in
                        HStack(spacing: 8) {
                            Image(systemName: "film")
                                .foregroundColor(.blue)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(video.fileName)
                                    .font(.body)
                                
                                HStack(spacing: 8) {
                                    Text(video.fileSizeString)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    if video.durationSeconds != nil {
                                        Text("•")
                                            .foregroundColor(.secondary)
                                        Text(video.durationString)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                    .width(min: 250, ideal: 350, max: 500)
                    
                    TableColumn("Progress") { video in
                        VStack(spacing: 4) {
                            if video.state == .processing || video.state == .completed {
                                ProgressView(value: video.progress) {
                                    HStack {
                                        Text("\(Int(video.progress * 100))%")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        Spacer()
                                        
                                        if video.totalClips > 0 {
                                            Text("\(video.currentClip)/\(video.totalClips) clips")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            } else if video.state == .queued {
                                HStack {
                                    ProgressView()
                                        .controlSize(.small)
                                    Text("Queued")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .width(min: 150, ideal: 200, max: 250)
                    
                    TableColumn("Status") { video in
                        HStack {
                            Circle()
                                .fill(statusColor(for: video.state))
                                .frame(width: 8, height: 8)
                            
                            Text(video.state.rawValue)
                                .font(.caption)
                        }
                    }
                    .width(min: 100, ideal: 120, max: 150)
                }
                
                if videoManager.videos.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "video.badge.plus")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        
                        Text("No videos added")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        
                        Text("Click 'Add Videos' or drag video files here")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Button("Add Videos") {
                            openFilePicker()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(nsColor: .controlBackgroundColor))
                }
            }
        }
        .background(Color(nsColor: .controlBackgroundColor))
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("AddVideosAction"))) { _ in
            openFilePicker()
        }
    }
    
    private func statusColor(for state: ProcessingState) -> Color {
        switch state {
        case .idle: return .gray
        case .queued: return .blue
        case .processing: return .orange
        case .completed: return .green
        case .failed: return .red
        case .cancelled: return .gray
        }
    }
}
