import SwiftUI

struct ContentView: View {
    @StateObject private var videoManager = VideoManager()
    
    var body: some View {
        NavigationSplitView(
            columnVisibility: .constant(.all),
            sidebar: {
                DashboardView(videoManager: videoManager)
            },
            content: {
                SourceTableView(videoManager: videoManager)
            },
            detail: {
                ConfigurationPanel(videoManager: videoManager)
            }
        )
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: 900, minHeight: 600)
    }
}

#Preview {
    ContentView()
}
