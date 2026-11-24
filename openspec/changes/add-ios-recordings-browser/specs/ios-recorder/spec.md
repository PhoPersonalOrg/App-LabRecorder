## MODIFIED Requirements

### Requirement: iOS recording UI and status
The iOS app SHALL provide a Record tab with: stream list (with refresh and per-stream selection), study root and filename template fields, a “Saving to” preview of the resolved path, Start and Stop buttons, and while recording the elapsed time and output file size. The app SHALL also provide a Recordings tab for browsing recorded files.

#### Scenario: Recording in progress
- **WHEN** recording has been started and not yet stopped
- **THEN** the status section shows the output path, elapsed time (e.g. m:ss), and file size in kb
- **AND** Start is disabled and Stop is enabled until the user taps Stop

#### Scenario: Two-tab navigation
- **WHEN** the user opens the app
- **THEN** a TabView presents Record and Recordings tabs
- **AND** the Record tab contains the stream list, path/template, and Start/Stop controls

## ADDED Requirements

### Requirement: Recordings browser
The iOS app SHALL list `.xdf` files under the app Documents directory (recursively), show name, size, and modification date, and SHALL allow the user to share a recording via the system share sheet and to delete a recording after confirmation. Deleting the file currently being recorded SHALL be refused or blocked.

#### Scenario: List recordings after stop
- **WHEN** the user has finished a recording that wrote an `.xdf` under Documents
- **AND** the user opens or refreshes the Recordings tab
- **THEN** the recording appears in the list with filename, size, and date

#### Scenario: Share a recording
- **WHEN** the user taps Share on a listed recording
- **THEN** the system share sheet is presented for that file URL

#### Scenario: Delete a recording
- **WHEN** the user confirms delete on a listed recording that is not the active recording file
- **THEN** the file is removed from disk and from the list

#### Scenario: Empty recordings
- **WHEN** no `.xdf` files exist under Documents
- **THEN** the Recordings tab shows an empty-state message

### Requirement: Documents File Sharing
The iOS app SHALL set `UIFileSharingEnabled` and `LSSupportsOpeningDocumentsInPlace` so the Documents folder is visible in the Files app and in Finder/iTunes File Sharing when the device is connected to a computer.

#### Scenario: Files app access
- **WHEN** the app is installed with File Sharing enabled
- **THEN** the user can browse the app Documents folder via Files (On My iPhone/iPad → LabRecorderiOS)

#### Scenario: Finder File Sharing
- **WHEN** the device is connected to a Mac and the user opens the device Files section in Finder
- **THEN** the app Documents contents (including `.xdf` recordings) are listed for transfer
