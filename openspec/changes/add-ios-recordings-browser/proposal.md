## Why
Users need to browse, share, and delete XDF recordings made on device without a computer, and transfer files via Files/Finder when connected. The recorder already writes to Documents but has no in-app file UI and File Sharing is disabled, so recordings are trapped in the sandbox.

## What Changes
- Add a second **Recordings** tab that lists `.xdf` files under the app Documents directory (including subfolders), with share (system share sheet) and delete.
- Enable Documents File Sharing via `UIFileSharingEnabled` and `LSSupportsOpeningDocumentsInPlace` so Files and Finder/iTunes can access the Documents folder.
- Replace the single-screen app root with a two-tab `TabView` (Record + Recordings). Recording UX on the first tab is unchanged.

Out of scope: iCloud Drive container, in-app XDF preview/rename/bulk ops, changing the default save location.

## Impact
- Affected specs: `ios-recorder` (modify UI requirement; add recordings browser and File Sharing)
- Affected code: `ios/LabRecorderiOSPackage` (RootView, RecordingsView, RecordingFileStore), `ios/LabRecorderiOS/LabRecorderiOSApp.swift`, `ios/Config/Shared.xcconfig`, `ios/LabRecorderiOS.xcodeproj/project.pbxproj`, `ios/README.md`
