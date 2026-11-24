import SwiftUI

public struct RootView: View {
    @State private var activeRecordingPath = ""

    public init() {}

    public var body: some View {
        TabView {
            SegmentedLayoutScreen(activeRecordingPath: $activeRecordingPath)
                .tabItem {
                    Label("Record", systemImage: "record.circle")
                }

            RecordingsView(activeRecordingPath: activeRecordingPath)
                .tabItem {
                    Label("Recordings", systemImage: "folder")
                }
        }
    }
}

#Preview {
    RootView()
}
