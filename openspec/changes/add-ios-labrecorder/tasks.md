## 1. Implementation

- [x] 1.1 Create Xcode project and basic SwiftUI shell (single screen, stream list placeholder, path/template, Start/Stop)
- [x] 1.2 Implement or integrate LSL (resolve streams, stream_info, inlet for pulling samples)
- [x] 1.3 Implement Swift XDF writer (file header, stream headers/footers, sample chunks, clock offset, boundary; same format as C++ xdfwriter)
- [x] 1.4 Implement recording engine (multi-stream, phases, boundary timer, serialized file writes)
- [x] 1.5 Wire SwiftUI: stream list with refresh and selection, path/template with preview, Start/Stop with recording status (elapsed, file size)
- [x] 1.6 Add template token replacement (%date, %time, %datetime, %hostname) and file path preview; default study root to Documents
- [x] 1.7 Add OpenSpec proposal and spec deltas for ios-recorder capability
