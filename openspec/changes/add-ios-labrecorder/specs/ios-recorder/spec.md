## ADDED Requirements

### Requirement: iOS LSL stream discovery
The iOS app SHALL discover LSL streams on the local network (e.g. via UDP multicast on the standard LSL discovery port) and display them in a list with name, type, and host, and SHALL support a user-initiated refresh to re-resolve streams.

#### Scenario: User taps Update and streams are present
- **WHEN** the user taps Update and one or more LSL outlets are advertising on the network
- **THEN** the stream list shows each discovered stream (name and host)
- **AND** the user can toggle selection per stream for recording

#### Scenario: No streams on network
- **WHEN** the user taps Update and no LSL streams are found
- **THEN** the stream list is empty or unchanged and the UI indicates that no streams were found

### Requirement: iOS XDF recording
The iOS app SHALL record selected LSL streams into a single XDF file with correct chunk ordering (file header, stream headers, sample chunks, optional clock offsets, boundary chunks, stream footers) so that the file is readable by existing XDF tools (e.g. Python, MATLAB).

#### Scenario: Start recording with selected streams
- **WHEN** the user selects one or more streams and taps Start
- **THEN** the app creates the output file at the resolved path (study root + template with tokens replaced)
- **AND** stream headers are written first, then sample data and periodic boundary chunks until the user taps Stop
- **AND** on Stop, stream footers are written and the file is closed

#### Scenario: Filename template tokens
- **WHEN** the user sets a filename template containing %date, %time, %datetime, or %hostname
- **THEN** at recording start those tokens are replaced with UTC date/time or device hostname (filename-safe) to form the final path

### Requirement: iOS recording UI and status
The iOS app SHALL provide a single main screen with: stream list (with refresh and per-stream selection), study root and filename template fields, a “Saving to” preview of the resolved path, Start and Stop buttons, and while recording the elapsed time and output file size.

#### Scenario: Recording in progress
- **WHEN** recording has been started and not yet stopped
- **THEN** the status section shows the output path, elapsed time (e.g. m:ss), and file size in kb
- **AND** Start is disabled and Stop is enabled until the user taps Stop
