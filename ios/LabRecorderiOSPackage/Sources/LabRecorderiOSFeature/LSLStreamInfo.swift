import Foundation
import lsl

/// LSL channel format; matches liblsl `cft_*` values for XDF compatibility.
public enum LSLChannelFormat: String, Sendable {
    case int8
    case int16
    case int32
    case float32
    case double64
    case string
    case undefined

    public init(from channelFormatString: String?) {
        guard let s = channelFormatString?.lowercased() else {
            self = .undefined
            return
        }
        switch s {
        case "int8": self = .int8
        case "int16": self = .int16
        case "int32": self = .int32
        case "float32": self = .float32
        case "double64": self = .double64
        case "string": self = .string
        default: self = .undefined
        }
    }

    init(cFormat: lsl_channel_format_t) {
        switch cFormat {
        case cft_float32: self = .float32
        case cft_double64: self = .double64
        case cft_string: self = .string
        case cft_int32: self = .int32
        case cft_int16: self = .int16
        case cft_int8: self = .int8
        case cft_int64: self = .double64 // XDF writer has no int64 path; promote later if needed
        default: self = .undefined
        }
    }
}

/// Owns an `lsl_streaminfo` handle from liblsl.
public final class LSLStreamInfoHandle: @unchecked Sendable {
    let raw: lsl_streaminfo

    init(consuming raw: lsl_streaminfo) {
        self.raw = raw
    }

    deinit {
        lsl_destroy_streaminfo(raw)
    }
}

/// Represents an LSL stream advertisement (discovered via resolve).
public struct LSLStreamInfo: Sendable {
    public let name: String
    public let type: String
    public let sourceId: String
    public let hostname: String
    public let channelCount: UInt32
    public let nominalSrate: Double
    public let channelFormat: LSLChannelFormat
    public let asXml: String
    /// Retained native handle used to open an inlet. Nil for synthetic/test infos.
    public let handle: LSLStreamInfoHandle?

    public init(
        name: String,
        type: String,
        sourceId: String,
        hostname: String,
        channelCount: UInt32,
        nominalSrate: Double,
        channelFormat: LSLChannelFormat,
        asXml: String,
        handle: LSLStreamInfoHandle? = nil
    ) {
        self.name = name
        self.type = type
        self.sourceId = sourceId
        self.hostname = hostname
        self.channelCount = channelCount
        self.nominalSrate = nominalSrate
        self.channelFormat = channelFormat
        self.asXml = asXml
        self.handle = handle
    }

    /// Build from a resolved liblsl streaminfo (takes ownership of the handle).
    public init(consuming raw: lsl_streaminfo) {
        let handle = LSLStreamInfoHandle(consuming: raw)
        let name = String(cString: lsl_get_name(raw))
        let type = String(cString: lsl_get_type(raw))
        let sourceId = String(cString: lsl_get_source_id(raw))
        let hostname = String(cString: lsl_get_hostname(raw))
        let channelCount = UInt32(lsl_get_channel_count(raw))
        let nominalSrate = lsl_get_nominal_srate(raw)
        let channelFormat = LSLChannelFormat(cFormat: lsl_get_channel_format(raw))
        var xml = ""
        if let xmlPtr = lsl_get_xml(raw) {
            xml = String(cString: xmlPtr)
            lsl_destroy_string(xmlPtr)
        }
        self.init(
            name: name,
            type: type,
            sourceId: sourceId,
            hostname: hostname,
            channelCount: channelCount,
            nominalSrate: nominalSrate,
            channelFormat: channelFormat,
            asXml: xml,
            handle: handle
        )
    }

    public var listName: String { "\(name) (\(hostname))" }
}
