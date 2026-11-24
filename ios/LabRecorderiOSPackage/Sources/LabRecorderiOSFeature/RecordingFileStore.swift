import Foundation

public struct RecordingFileItem: Identifiable, Equatable, Sendable {
    public var id: String { url.path }
    public let url: URL
    public let name: String
    public let relativePath: String
    public let sizeBytes: Int64
    public let modificationDate: Date

    public init(url: URL, root: URL, sizeBytes: Int64, modificationDate: Date) {
        self.url = url
        self.name = url.lastPathComponent
        let rootPath = root.standardizedFileURL.path
        let filePath = url.standardizedFileURL.path
        if filePath.hasPrefix(rootPath) {
            let trimmed = String(filePath.dropFirst(rootPath.count))
                .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            self.relativePath = trimmed.isEmpty ? url.lastPathComponent : trimmed
        } else {
            self.relativePath = url.lastPathComponent
        }
        self.sizeBytes = sizeBytes
        self.modificationDate = modificationDate
    }

    public var sizeKB: Int64 { sizeBytes / 1024 }
}

public enum RecordingFileStoreError: Error, Equatable, Sendable {
    case fileInUse
    case notFound
}

public struct RecordingFileStore: Sendable {
    public let rootURL: URL

    public init(rootURL: URL) {
        self.rootURL = rootURL
    }

    public static func documentsDirectory() -> URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    }

    public func listXDFFiles() throws -> [RecordingFileItem] {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: rootURL.path) else { return [] }

        let resourceKeys: [URLResourceKey] = [.isRegularFileKey, .fileSizeKey, .contentModificationDateKey]
        guard let enumerator = fileManager.enumerator(
            at: rootURL,
            includingPropertiesForKeys: resourceKeys,
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        var items: [RecordingFileItem] = []
        for case let fileURL as URL in enumerator {
            guard fileURL.pathExtension.lowercased() == "xdf" else { continue }
            let values = try fileURL.resourceValues(forKeys: Set(resourceKeys))
            guard values.isRegularFile == true else { continue }
            let size = Int64(values.fileSize ?? 0)
            let date = values.contentModificationDate ?? .distantPast
            items.append(RecordingFileItem(url: fileURL, root: rootURL, sizeBytes: size, modificationDate: date))
        }

        return items.sorted { $0.modificationDate > $1.modificationDate }
    }

    public func delete(_ item: RecordingFileItem, activeRecordingPath: String? = nil) throws {
        if let active = activeRecordingPath, !active.isEmpty,
           item.url.standardizedFileURL.path == (active as NSString).standardizingPath {
            throw RecordingFileStoreError.fileInUse
        }
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: item.url.path) else {
            throw RecordingFileStoreError.notFound
        }
        try fileManager.removeItem(at: item.url)
    }
}
