# AGENTS.md

## Cursor Cloud specific instructions

LabRecorder is a C++/Qt6 desktop app (plus a `LabRecorderCLI` command-line recorder and an
in-tree `xdfwriter` static library + `testxdfwriter` test exe) for recording Lab Streaming
Layer (LSL) streams to `.xdf` files. There are no databases/servers; "services" here are just
the recorder binaries plus at least one live LSL stream to record. Build is CMake-only;
standard build commands are documented in `BUILD.md` and `CMakePresets.json`.

### Build / configure (Linux)
- Use the `linux-gcc-release` preset:
  - `cmake --preset linux-gcc-release`
  - `cmake --build --preset linux-release -j`
- Binaries land in `out/build/linux-gcc-release/` (`LabRecorder`, `LabRecorderCLI`,
  `xdfwriter/testxdfwriter`).
- `liblsl` is installed system-wide (deb), so `find_package(LSL)` resolves via
  `/usr/lib/cmake/LSL` with no `LSL_INSTALL_ROOT` needed.

### Non-obvious caveats
- The default C++ compiler (`/usr/bin/c++`) is **clang**, which uses the gcc-14 toolchain and
  therefore needs `libstdc++-14-dev` (the update script installs it). Without it, even the
  CMake compiler check fails with `cannot find -lstdc++`.
- The committed `LabRecorder.cfg` (copied next to the GUI binary at build time) has a
  Windows `StudyRoot`/save path (`E:/Dropbox...`) that is not writable on Linux. Before
  recording with the GUI, set the **Study Root** field to a writable dir (e.g. `/tmp/lr_recordings`)
  and a simple **File Name/Template** (e.g. `gui_test.xdf`). The GUI auto-creates the directory.
- `CMakeUserPresets.json` only defines Windows presets; ignore it on Linux.

### Running / testing end-to-end
- A running X display is available at `DISPLAY=:1` (TigerVNC + xfce4); launch the GUI with
  `DISPLAY=:1 ./LabRecorder`.
- To exercise the recorder you need a live LSL stream. There are no bundled example senders,
  so create a tiny one against the installed `liblsl` headers (`/usr/include/lsl_cpp.h`,
  link with `-llsl`) that opens an `lsl::stream_outlet` and pushes samples.
- CLI flow: `./LabRecorderCLI out.xdf 'type="EEG"'` resolves matching streams, records, and
  stops on Enter (so e.g. `(sleep 5; echo) | ./LabRecorderCLI ...` records ~5s).
- Verify a recording by checking the file starts with the `XDF:` magic and contains the
  expected stream name/type.
- Unit check: run `out/build/linux-gcc-release/xdfwriter/testxdfwriter` (exit 0 = pass; it
  writes a sample `test.xdf`).
