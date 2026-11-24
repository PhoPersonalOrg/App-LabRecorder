import Foundation
import Testing
@testable import LabRecorderiOSFeature

@Test func xdfWriterWritesMagicAndStreamHeader() throws {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("test_\(UUID().uuidString).xdf")
    defer { try? FileManager.default.removeItem(at: url) }

    let writer = try XDFWriter(fileURL: url)
    writer.writeStreamHeader(streamId: 1, content: "<?xml version=\"1.0\"?><info><name>Test</name><type>EEG</type></info>")
    let timestamps: [Double] = [1.0, 1.01]
    let samples: [Float] = [0.1, 0.2, 0.3, 0.4]
    try writer.writeDataChunk(streamId: 1, timestamps: timestamps, samples: samples, nChannels: 2)
    writer.writeBoundaryChunk()
    writer.writeStreamFooter(streamId: 1, content: "<?xml version=\"1.0\"?><info><sample_count>2</sample_count></info>")
    try writer.close()

    let data = try Data(contentsOf: url)
    #expect(data.starts(with: Data("XDF:".utf8)))
    #expect(data.range(of: Data("Test".utf8)) != nil)
    #expect(data.count > 64)
}

@Test func filenameTemplateTokensReplace() {
    let template = "LabRecorder_%date_%time_%hostname.xdf"
    let date = "2026-01-02"
    let time = "03-04-05"
    let host = "test-host"
    let replaced = template
        .replacingOccurrences(of: "%date", with: date)
        .replacingOccurrences(of: "%time", with: time)
        .replacingOccurrences(of: "%hostname", with: host)
    #expect(replaced == "LabRecorder_2026-01-02_03-04-05_test-host.xdf")
}

@Test func recordingFileStoreListsAndDeletesXDF() throws {
    let fm = FileManager.default
    let root = fm.temporaryDirectory.appendingPathComponent("lr_store_\(UUID().uuidString)", isDirectory: true)
    try fm.createDirectory(at: root, withIntermediateDirectories: true)
    defer { try? fm.removeItem(at: root) }

    let nested = root.appendingPathComponent("sub", isDirectory: true)
    try fm.createDirectory(at: nested, withIntermediateDirectories: true)
    let older = nested.appendingPathComponent("older.xdf")
    let newer = root.appendingPathComponent("newer.xdf")
    try Data("old".utf8).write(to: older)
    try Data("new".utf8).write(to: newer)
    try Data("skip".utf8).write(to: root.appendingPathComponent("notes.txt"))
    try fm.setAttributes([.modificationDate: Date(timeIntervalSince1970: 1_000)], ofItemAtPath: older.path)
    try fm.setAttributes([.modificationDate: Date(timeIntervalSince1970: 2_000)], ofItemAtPath: newer.path)

    let store = RecordingFileStore(rootURL: root)
    let listed = try store.listXDFFiles()
    #expect(listed.map(\.name) == ["newer.xdf", "older.xdf"])
    #expect(listed[1].relativePath == "sub/older.xdf")

    try store.delete(listed[0])
    #expect(try store.listXDFFiles().map(\.name) == ["older.xdf"])
}

@Test func recordingFileStoreRefusesDeleteWhileRecording() throws {
    let fm = FileManager.default
    let root = fm.temporaryDirectory.appendingPathComponent("lr_store_busy_\(UUID().uuidString)", isDirectory: true)
    try fm.createDirectory(at: root, withIntermediateDirectories: true)
    defer { try? fm.removeItem(at: root) }

    let fileURL = root.appendingPathComponent("live.xdf")
    try Data("xdf".utf8).write(to: fileURL)
    let store = RecordingFileStore(rootURL: root)
    let item = try store.listXDFFiles()[0]

    #expect(throws: RecordingFileStoreError.fileInUse) {
        try store.delete(item, activeRecordingPath: fileURL.path)
    }
    #expect(fm.fileExists(atPath: fileURL.path))
}
