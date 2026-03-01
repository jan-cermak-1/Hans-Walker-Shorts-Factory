import SwiftUI

struct DashboardView: View {
    @ObservedObject var videoManager: VideoManager
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Dashboard")
                .font(.headline)
            
            Divider()
            
            VStack(spacing: 16) {
                if !videoManager.videos.isEmpty {
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "film.stack")
                                .foregroundColor(.blue)
                            Text("\(videoManager.videos.count)")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("videos")
                                .foregroundColor(.secondary)
                        }
                        
                        if videoManager.totalClipsToGenerate > 0 {
                            HStack {
                                Image(systemName: "scissors")
                                    .foregroundColor(.orange)
                                Text("\(videoManager.totalClipsToGenerate)")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                Text("clips total")
                                    .foregroundColor(.secondary)
                            }
                            .font(.caption)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(8)
                }
                
                VStack(spacing: 12) {
                    Button(action: {
                        videoManager.startBatchProcessing()
                    }) {
                        HStack {
                            Image(systemName: "play.circle.fill")
                                .font(.title3)
                            Text("Start Batch")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(
                        videoManager.isProcessing ||
                        videoManager.videos.isEmpty ||
                        videoManager.globalConfiguration.outputFolder == nil
                    )
                    
                    if videoManager.isProcessing {
                        Button(action: {
                            videoManager.stopProcessing()
                        }) {
                            HStack {
                                Image(systemName: "stop.circle.fill")
                                    .font(.title3)
                                Text("Stop")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .tint(.red)
                    }
                }
            }
            
            if videoManager.isProcessing {
                Divider()
                
                VStack(spacing: 12) {
                    Text("Progress")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    VStack(spacing: 8) {
                        ProgressView(value: videoManager.masterProgress) {
                            HStack {
                                Text("Overall Progress")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(Int(videoManager.masterProgress * 100))%")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                        }
                        
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(.secondary)
                                .font(.caption)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Estimated Time")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text(videoManager.estimatedTimeRemainingString)
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            
                            Spacer()
                        }
                        
                        HStack {
                            Image(systemName: "checkmark.circle")
                                .foregroundColor(.green)
                                .font(.caption)
                            
                            Text(videoManager.processingStatusString)
                                .font(.caption)
                            
                            Spacer()
                        }
                    }
                    .padding()
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(8)
                }
            } else if videoManager.clipsCompleted > 0 {
                Divider()
                
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.green)
                    
                    Text("Processing Complete")
                        .font(.headline)
                    
                    Text("\(videoManager.clipsCompleted) clips generated")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if videoManager.globalConfiguration.outputFolder != nil {
                        Button(action: {
                            videoManager.openOutputFolder()
                        }) {
                            HStack {
                                Image(systemName: "folder")
                                Text("Open Output Folder")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(8)
            }
            
            if videoManager.globalConfiguration.outputFolder == nil {
                Divider()
                
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Please select an output folder")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
            
            Spacer()
        }
        .padding()
        .frame(width: 200)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
