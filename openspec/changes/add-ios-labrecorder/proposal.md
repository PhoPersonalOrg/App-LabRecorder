## Why
Researchers and experimenters need to record LSL streams on iOS devices (e.g. iPad in the field, iPhone as a secondary recorder). The existing LabRecorder is a C++/Qt desktop application and does not run on iOS. An iOS-compatible variant enables mobile and tablet recording with the same XDF format and LSL protocol.

## What Changes
- Add a native iOS app (Xcode project, SwiftUI) that discovers LSL streams on the local network, lets the user select streams, and records them to a single XDF file with correct chunk ordering (headers, streaming, footers, boundaries).
- Implement a minimal LSL client in Swift (UDP multicast resolve, TCP inlet for samples) and a Swift XDF writer compatible with the existing XDF specification.
- Provide a single main screen: stream list with refresh and selection, study root and filename template with token replacement, Start/Stop recording, and status (elapsed time, file size). Output is stored under app Documents or user-configured path; template tokens include %date, %time, %datetime, %hostname.
- No changes to the existing C++/Qt/CMake desktop build.

Out of scope for this change: TCP remote control (RCS), config file (.cfg) load/save, XDFZ compression, BIDS template builder UI.

## Impact
- Affected specs: new capability `ios-recorder`
- Affected code: new directory `ios/` containing Xcode workspace, app target, and Swift package (LSL client, XDF writer, recording engine, SwiftUI views). No edits to `src/`, `xdfwriter/`, or CMake.
