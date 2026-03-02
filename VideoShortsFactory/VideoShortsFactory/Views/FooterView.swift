import SwiftUI
import AppKit

struct FooterView: View {
    @ObservedObject var videoManager: VideoManager
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            // Top border
            Rectangle()
                .fill(Color.hwSeparator(colorScheme))
                .frame(height: 1)
            
            // Footer content - dynamický podle stavu
            VStack(spacing: 12) {
                if videoManager.isProcessing {
                    processingContent
                } else if videoManager.batchCompleted {
                    completedContent
                } else {
                    defaultContent
                }
                
                // YouTube link - vždy přítomen
                youTubeLink
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.hwBackgroundMid(colorScheme))
        }
    }
    
    // MARK: - Default State (Start Button)
    
    private var defaultContent: some View {
        VStack(spacing: 8) {
            HansWalkerButton(
                "Start Batch",
                disabled: !canStartBatch
            ) {
                videoManager.startBatchProcessing()
            }
            
            if !canStartBatch {
                Text(helpText)
                    .font(.system(size: 11))
                    .foregroundColor(Color.hwTextSecondary(colorScheme).opacity(0.7))
            }
        }
    }
    
    private var canStartBatch: Bool {
        !videoManager.videos.isEmpty && videoManager.globalConfiguration.outputFolder != nil
    }
    
    private var helpText: String {
        if videoManager.videos.isEmpty {
            return "⓵ Add source videos to begin"
        } else {
            return "⓶ Select an output folder"
        }
    }
    
    // MARK: - Processing State
    
    private var processingContent: some View {
        VStack(spacing: 10) {
            // Progress info
            HStack {
                Text("\(videoManager.clipsCompleted) / \(videoManager.totalClipsToGenerate) clips")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.hwText(colorScheme))
                
                Spacer()
                
                Text("\(Int(videoManager.masterProgress * 100))%")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.hwAccentGreen(colorScheme))
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.hwSeparator(colorScheme).opacity(0.3))
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.hwAccentGreen(colorScheme))
                        .frame(
                            width: max(0, geometry.size.width * videoManager.masterProgress),
                            height: 6
                        )
                        .shadow(
                            color: Color.hwAccentGreen(colorScheme).opacity(0.4),
                            radius: 4,
                            y: 0
                        )
                }
            }
            .frame(height: 6)
            
            // ETA and Stop button
            HStack {
                HStack(spacing: 6) {
                    ProgressView()
                        .controlSize(.mini)
                        .tint(Color.hwAccentGreen(colorScheme))
                    
                    Text("ETA: ~\(videoManager.estimatedTimeRemainingString)")
                        .font(.system(size: 11))
                        .foregroundColor(Color.hwTextSecondary(colorScheme))
                }
                
                Spacer()
                
                Button {
                    videoManager.stopProcessing()
                } label: {
                    Text("Stop")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.red)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(7)
                        .overlay(
                            RoundedRectangle(cornerRadius: 7)
                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    // MARK: - Completed State
    
    private var completedContent: some View {
        VStack(spacing: 12) {
            // Success header
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Color.hwAccentGreen(colorScheme))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Processing Complete")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color.hwText(colorScheme))
                    
                    Text("\(videoManager.clipsCompleted) clips generated")
                        .font(.system(size: 11))
                        .foregroundColor(Color.hwTextSecondary(colorScheme))
                }
                
                Spacer()
            }
            
            // Action buttons
            HStack(spacing: 12) {
                SecondaryHansWalkerButton("Open Folder", action: {
                    videoManager.openOutputFolder()
                }, icon: {
                    Image(systemName: "folder")
                        .font(.system(size: 13))
                })
                
                HansWalkerButton("New Batch", action: {
                    videoManager.startNewBatch()
                }, icon: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11))
                })
            }
        }
    }
    
    // MARK: - YouTube Link
    
    private var youTubeLink: some View {
        Button {
            if let url = URL(string: "https://www.youtube.com/@HansWalker.walking") {
                NSWorkspace.shared.open(url)
            }
        } label: {
            HStack(spacing: 5) {
                // YouTube icon (simple SVG-like representation)
                Image(systemName: "play.rectangle.fill")
                    .font(.system(size: 10))
                    .foregroundColor(Color.hwTextSecondary(colorScheme).opacity(0.6))
                
                Text("youtube.com/@HansWalker.walking")
                    .font(.system(size: 10))
                    .foregroundColor(Color.hwTextSecondary(colorScheme).opacity(0.6))
            }
            .padding(.top, 4)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}

#Preview("Default State") {
    let manager = VideoManager()
    return FooterView(videoManager: manager)
        .frame(width: 540)
        .background(Color.hwCream)
}

#Preview("With Videos") {
    let manager = VideoManager()
    manager.videos.append(VideoItem(url: URL(fileURLWithPath: "/test.mp4")))
    return FooterView(videoManager: manager)
        .frame(width: 540)
        .background(Color.hwCream)
}

#Preview("Processing - Dark") {
    let manager = VideoManager()
    manager.isProcessing = true
    manager.clipsCompleted = 5
    manager.totalClipsToGenerate = 12
    manager.masterProgress = 0.42
    return FooterView(videoManager: manager)
        .frame(width: 540)
        .background(Color.hwDarkBg)
        .preferredColorScheme(.dark)
}

#Preview("Completed") {
    let manager = VideoManager()
    manager.batchCompleted = true
    manager.clipsCompleted = 12
    return FooterView(videoManager: manager)
        .frame(width: 540)
        .background(Color.hwCream)
}
