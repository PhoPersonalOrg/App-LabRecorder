import SwiftUI

public struct RecordingsView: View {
    var activeRecordingPath: String = ""

    @State private var items: [RecordingFileItem] = []
    @State private var loadError: String?
    @State private var pendingDelete: RecordingFileItem?
    @State private var alertMessage: String?

    public init(activeRecordingPath: String = "") {
        self.activeRecordingPath = activeRecordingPath
    }

    public var body: some View {
        NavigationStack {
            Group {
                if let loadError {
                    ContentUnavailableView(
                        "Couldn’t load recordings",
                        systemImage: "exclamationmark.triangle",
                        description: Text(loadError)
                    )
                } else if items.isEmpty {
                    ContentUnavailableView(
                        "No recordings",
                        systemImage: "folder",
                        description: Text("XDF files saved under Documents will appear here.")
                    )
                } else {
                    List {
                        ForEach(items) { item in
                            RecordingRowView(item: item)
                        }
                        .onDelete(perform: requestDelete)
                    }
                }
            }
            .navigationTitle("Recordings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        reload()
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .accessibilityIdentifier("refreshRecordings")
                }
            }
            .refreshable { reload() }
            .onAppear { reload() }
            .confirmationDialog(
                "Delete recording?",
                isPresented: Binding(
                    get: { pendingDelete != nil },
                    set: { if !$0 { pendingDelete = nil } }
                ),
                titleVisibility: .visible,
                presenting: pendingDelete
            ) { item in
                Button("Delete", role: .destructive) {
                    performDelete(item)
                }
                Button("Cancel", role: .cancel) {
                    pendingDelete = nil
                }
            } message: { item in
                Text("Remove \(item.name)? This cannot be undone.")
            }
            .alert(
                "Unable to delete",
                isPresented: Binding(
                    get: { alertMessage != nil },
                    set: { if !$0 { alertMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) { alertMessage = nil }
            } message: {
                Text(alertMessage ?? "")
            }
        }
    }

    private func store() -> RecordingFileStore? {
        guard let root = RecordingFileStore.documentsDirectory() else { return nil }
        return RecordingFileStore(rootURL: root)
    }

    private func reload() {
        guard let store = store() else {
            loadError = "Documents directory unavailable."
            items = []
            return
        }
        do {
            items = try store.listXDFFiles()
            loadError = nil
        } catch {
            loadError = error.localizedDescription
            items = []
        }
    }

    private func requestDelete(at offsets: IndexSet) {
        guard let index = offsets.first, items.indices.contains(index) else { return }
        pendingDelete = items[index]
    }

    private func performDelete(_ item: RecordingFileItem) {
        pendingDelete = nil
        guard let store = store() else { return }
        do {
            try store.delete(item, activeRecordingPath: activeRecordingPath)
            items.removeAll { $0.id == item.id }
        } catch RecordingFileStoreError.fileInUse {
            alertMessage = "This file is currently being recorded and cannot be deleted."
        } catch {
            alertMessage = error.localizedDescription
            reload()
        }
    }
}

private struct RecordingRowView: View {
    let item: RecordingFileItem

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.body.weight(.medium))
                    .lineLimit(2)
                if item.relativePath != item.name {
                    Text(item.relativePath)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Text("\(item.sizeKB) kb · \(Self.dateFormatter.string(from: item.modificationDate))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            ShareLink(item: item.url) {
                Image(systemName: "square.and.arrow.up")
            }
            .accessibilityLabel("Share \(item.name)")
            .accessibilityIdentifier("shareRecording")
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    RecordingsView()
}
