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
