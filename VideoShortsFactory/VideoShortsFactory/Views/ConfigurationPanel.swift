import SwiftUI

struct ConfigurationPanel: View {
    @ObservedObject var videoManager: VideoManager
    @State private var isOutputFolderPickerPresented = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Configuration")
                    .font(.headline)
                
                Divider()
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Clip Settings")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    HStack {
                        Text("Quantity:")
                            .frame(width: 80, alignment: .leading)
                        
                        Stepper(
                            "\(videoManager.globalConfiguration.quantity) clips",
                            value: Binding(
                                get: { videoManager.globalConfiguration.quantity },
                                set: { newValue in
                                    videoManager.globalConfiguration.quantity = newValue
                                    updateAllVideosConfiguration()
                                }
                            ),
                            in: 1...50
                        )
                        .disabled(videoManager.isProcessing)
                    }
                    
                    HStack {
                        Text("Duration:")
                            .frame(width: 80, alignment: .leading)
                        
                        Stepper(
                            "\(videoManager.globalConfiguration.duration) seconds",
                            value: Binding(
                                get: { videoManager.globalConfiguration.duration },
                                set: { newValue in
                                    videoManager.globalConfiguration.duration = newValue
                                    updateAllVideosConfiguration()
                                }
                            ),
                            in: 5...60
                        )
                        .disabled(videoManager.isProcessing)
                    }
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(8)
                
                Divider()
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Metadata")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Base Title")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("Enter title", text: Binding(
                            get: { videoManager.globalConfiguration.baseTitle },
                            set: { newValue in
                                videoManager.globalConfiguration.baseTitle = newValue
                                updateAllVideosConfiguration()
                            }
                        ))
                        .textFieldStyle(.roundedBorder)
                        .disabled(videoManager.isProcessing)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Hashtags")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextEditor(text: Binding(
                            get: { videoManager.globalConfiguration.hashtags },
                            set: { newValue in
                                videoManager.globalConfiguration.hashtags = newValue
                                updateAllVideosConfiguration()
                            }
                        ))
                        .font(.body)
                        .frame(height: 80)
                        .scrollContentBackground(.hidden)
                        .background(Color(nsColor: .textBackgroundColor))
                        .cornerRadius(4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color(nsColor: .separatorColor), lineWidth: 0.5)
                        )
                        .disabled(videoManager.isProcessing)
                    }
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(8)
                
                Divider()
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Output")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Button(action: {
                        isOutputFolderPickerPresented = true
                    }) {
                        HStack {
                            Image(systemName: "folder.badge.plus")
                            Text("Select Output Folder")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(videoManager.isProcessing)
                    
                    if let outputURL = videoManager.globalConfiguration.outputFolder {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Selected Path:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(outputURL.path)
                                .font(.caption)
                                .foregroundColor(.primary)
                                .lineLimit(3)
                                .truncationMode(.middle)
                                .padding(8)
                                .background(Color(nsColor: .textBackgroundColor))
                                .cornerRadius(4)
                            
                            if !videoManager.videos.isEmpty {
                                let availableSpace = DiskSpaceChecker.shared.getAvailableSpaceString(at: outputURL)
                                let requiredSpace = DiskSpaceChecker.shared.formatBytes(
                                    DiskSpaceChecker.shared.estimateRequiredSpace(for: videoManager.videos)
                                )
                                
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Available:")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                        Text(availableSpace)
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text("Required:")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                        Text("~\(requiredSpace)")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                    }
                                }
                                .padding(8)
                                .background(Color(nsColor: .controlBackgroundColor))
                                .cornerRadius(4)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(8)
                
                Spacer()
            }
            .padding()
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .fileImporter(
            isPresented: $isOutputFolderPickerPresented,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    videoManager.globalConfiguration.outputFolder = url
                    updateAllVideosConfiguration()
                }
            case .failure(let error):
                print("Failed to select output folder: \(error)")
            }
        }
    }
    
    private func updateAllVideosConfiguration() {
        for video in videoManager.videos {
            video.configuration = videoManager.globalConfiguration
        }
    }
}
