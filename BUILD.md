# Building Lab Recorder

This file includes quick start recipes. To see general principles, look [here](https://github.com/labstreaminglayer/labstreaminglayer/blob/master/doc/BUILD.md).


## Windows - CMake - Visual Studio 2017

Starting with Visual Studio 2017, Microsoft began to support much closer integration with CMake. Generally, this uses the Visual Studio GUI as a wrapper around the CMake build files, so you should not expect to see most of the Visual Studio Project configuration options that you are familiar with, and CMake projects cannot be directly blended with non-CMake Visual Studio projects. There are also some weird gotchas, described below.

You will need to download and install:<BR/>
 * [The full LabStreamingLayer meta project](https://github.com/labstreaminglayer/labstreaminglayer) -> Clone (include --recursive flag) or download  
 * [Visual Studio Community 2017](https://imagine.microsoft.com/en-us/Catalog/Product/530)
 * [CMake 3.12.1](https://cmake.org/files/v3.12/)
 * [Qt 5.11.1](https://download.qt.io/archive/qt/5.11/) 
 * [Boost 1.65.1](https://sourceforge.net/projects/boost/files/boost-binaries/1.65.1/boost_1_65_1-msvc-14.1-32.exe/download)

# Build liblsl
```powershell
cd ../
mkdir LSL
cd LSL
git clone --recurse-submodules https://github.com/sccn/liblsl.git
## checks out liblsl at '../LSL/liblsl'
cd liblsl
cmake -S . -B build -G "Visual Studio 17 2022" -A x64 -DCMAKE_INSTALL_PREFIX="build/install"
cmake --build build -j --config Release --target install

```

## Build LabRecorder

```
# Recommended: use CMake Presets (see CMakePresets.json)
# Run these commands from the App-LabRecorder repository root (the directory that contains CMakePresets.json).

# Windows (Visual Studio 2022)
cmake --preset win-vs-release
cmake --build --preset win-release --target INSTALL

# Windows (Optional) - Single-file EXE for GUI 
# Requires 7-Zip installed (7z.exe and 7z.sfx in PATH) - e.g. "C:\Users\pho\scoop\apps\7zip\current"
# You can also set SEVENZIP_DIR to the 7-Zip folder if not on PATH
cmake --preset win-vs-release-single
cmake --build --preset win-release-single --target package-single-file-exe
# Result: out/build/win-vs-release-single/ (or target dir) contains LabRecorder-single.exe

# Linux (GCC, Unix Makefiles)
cmake --preset linux-gcc-release
cmake --build --preset linux-release --target install

# macOS (Apple Silicon) — see "macOS (Apple Silicon)" section below
cmake --preset macos-release
cmake --build --preset macos-release --target install


# Notes
# - Ensure Qt and liblsl are discoverable (set Qt6_DIR/Qt5_DIR and LSL_DIR / LSL_INSTALL_ROOT as needed)
# - On Windows, the GUI build runs windeployqt automatically post-build; on macOS, run macdeployqt after install (see macOS section); on Linux, install rules provide a .desktop file and icon
# - For single-file EXE, antivirus tools may flag self-extractors; consider code signing and publishing checksums
```


#### Manual/Old Build steps (Windows)
```
# Qt5
cmake -S . -B build -G "Visual Studio 17 2022" -A x64 -DLSL_INSTALL_ROOT="C:/Users/pho/repos/EmotivEpoc/LSL_REPOS/LSL/liblsl/out/install/x64-Debug" -DQT_DIR="L:\Qt\5.15.2\msvc2019_64\lib\cmake\Qt5" -DQt5_DIR="L:\Qt\5.15.2\msvc2019_64\lib\cmake\Qt5" -DCMAKE_INSTALL_PREFIX="build/install"

#Qt6
cmake -S . -B build -G "Visual Studio 17 2022" -A x64 -DLSL_INSTALL_ROOT="C:/Users/pho/repos/EmotivEpoc/LSL_REPOS/LSL/liblsl/out/install/x64-Debug" -DQT_DIR="L:\Qt\6.8.1\msvc2022_64\lib\cmake\Qt6" -DQt6_DIR="L:\Qt\6.8.1\msvc2022_64\lib\cmake\Qt6" -DCMAKE_INSTALL_PREFIX="build/install"

## for install
cmake --build build -j --config Release --target install
cmake --build build -j --config Debug --target install

## for development
cmake --build build -j --config Release
cmake --build build -j --config Debug

```


## macOS (Apple Silicon)

Tested on arm64 with Homebrew Qt6 + Homebrew `lsl`, Xcode generator, deployment target 12.4.

### Prerequisites

```bash
# Xcode (full app, not just CLT) + CMake
xcode-select -p
brew install cmake qt lsl
```

Confirm arm64 packages (do **not** mix `/usr/local` Intel Qt/LSL into an arm64 build):

```bash
file "$(brew --prefix qt)/lib/QtCore.framework/QtCore"   # expect arm64
file "$(brew --prefix lsl)/lib/liblsl.dylib"              # expect arm64
ls "$(brew --prefix)/lib/cmake/lsl/LSLConfig.cmake"
ls "$(brew --prefix qt)/lib/cmake/Qt6/Qt6Config.cmake"
```

The `macos-release` preset in `CMakePresets.json` points at:

| Variable | Default |
|---|---|
| `LSL_DIR` | `/opt/homebrew/lib/cmake/lsl` |
| `Qt6_DIR` | `/opt/homebrew/opt/qt/lib/cmake/Qt6` |
| `MACDEPLOYQT_EXECUTABLE` | `/opt/homebrew/opt/qt/bin/macdeployqt` |

If your Homebrew prefix differs, override those cache variables when configuring.

### Configure, build, install

From the App-LabRecorder repo root:

```bash
cmake --preset macos-release
cmake --build --preset macos-release --config Release --target LabRecorder LabRecorderCLI
cmake --build --preset macos-release --config Release --target install
```

Outputs:

| Artifact | Location |
|---|---|
| Build tree (Xcode) | `out/build/macos-release/LabRecorder.xcodeproj` |
| GUI app (build) | `out/build/macos-release/Release/LabRecorder.app` |
| CLI (build) | `out/build/macos-release/Release/LabRecorderCLI` |
| Installed GUI | `out/install/macos-release/bin/LabRecorder.app` |
| Installed CLI | `out/install/macos-release/bin/LabRecorderCLI` |

Open the generated project in Xcode if you prefer the IDE:

```bash
open out/build/macos-release/LabRecorder.xcodeproj
```

### Bundle Qt plugins (required for GUI)

`cmake --install` / the `install` target runs `fixup_bundle` for Homebrew dylibs, but does **not** copy Qt platform plugins. After install, run Homebrew’s `macdeployqt` on the installed app:

```bash
"$(brew --prefix qt)/bin/macdeployqt" \
  out/install/macos-release/bin/LabRecorder.app \
  -verbose=1

# optional: re-sign ad-hoc after deploy
codesign --force --deep --sign - out/install/macos-release/bin/LabRecorder.app
```

Then launch:

```bash
open out/install/macos-release/bin/LabRecorder.app
# or CLI:
./out/install/macos-release/bin/LabRecorderCLI out.xdf 'type="EEG"'
```

### Clean reconfigure

If you change `LSL_DIR` / `Qt6_DIR` (or previously configured against `/usr/local` Intel packages), wipe the build tree first:

```bash
rm -rf out/build/macos-release
cmake --preset macos-release
```

### Common failures

- **`char*` vs `int8_t*` in `lsl_cpp.h` / `lsl/outlet.h`** — mixed LSL installs (`/usr/local` vs Homebrew). Use a single arm64 LSL (`LSL_DIR=/opt/homebrew/lib/cmake/lsl`) and reconfigure clean.
- **Missing `liblsl.*.dylib` at link** — `LSL_DIR` points at a build tree that never built Release, or at an x86_64 library while targeting arm64. Prefer Homebrew `lsl`.
- **Qt symbols missing for arm64** — `Qt6_DIR` points at Intel Qt under `/usr/local`. Point at `$(brew --prefix qt)/lib/cmake/Qt6`.
- **Codesign fails on `Contents/MacOS/*.cfg`** — sidecar files belong in `Contents/Resources` (current CMake does this). Delete stale copies under `Contents/MacOS/` and rebuild.
- **App launches but no UI / “could not find platform plugin”** — run `macdeployqt` as above.

### Manual configure (without presets)

```bash
cmake -S . -B out/build/macos-release -G Xcode \
  -DCMAKE_INSTALL_PREFIX="$PWD/out/install/macos-release" \
  -DLSL_DIR="$(brew --prefix)/lib/cmake/lsl" \
  -DQt6_DIR="$(brew --prefix qt)/lib/cmake/Qt6" \
  -DMACDEPLOYQT_EXECUTABLE="$(brew --prefix qt)/bin/macdeployqt" \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=12.4 \
  -DLABRECORDER_XDFZ=OFF

cmake --build out/build/macos-release --config Release --target install
```

CLI-only (no Qt):

```bash
cmake -S . -B out/build/macos-cli -G Xcode \
  -DBUILD_GUI=OFF \
  -DLSL_DIR="$(brew --prefix)/lib/cmake/lsl" \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=12.4
cmake --build out/build/macos-cli --config Release --target LabRecorderCLI
```


### NOTE 2025-09-10 - Had to substantially modify CMakeLists.txt by commenting out the missing `LSLGenerateCPackConfig` and `installLSLApp` commands


From Visual Studio:<BR/> 
 * File -> Open -> CMake -> labstreaminglayer/CMakeLists.txt
 * Wait while CMake configures automatically and until CMake menu turns black
 * Select x86-Release
 * CMake menu -> Change CMake Settings -> LabStreamingLayer

Add the "variable" section to the x86-Release group, so that it looks approximately like this:
```
{
  "name": "x86-Release",
  "generator": "Ninja",
  "configurationType": "RelWithDebInfo",
  "inheritEnvironments": [ "msvc_x86" ],
  "buildRoot": "${env.USERPROFILE}\\CMakeBuilds\\${workspaceHash}\\build\\${name}",
  "installRoot": "${env.USERPROFILE}\\CMakeBuilds\\${workspaceHash}\\install\\${name}",
  "cmakeCommandArgs": "",
  "buildCommandArgs": "-v",
  "ctestCommandArgs": "",
  "variables": [
    {
      "name": "Qt5_DIR",
      "value": "C:\\Qt\\5.11.1\\msvc2015\\lib\\cmake\\Qt5 "
    },
    {
      "name": "BOOST_ROOT",
      "value": "C:\\local\\boost_1_65_1"
    },
    {
      "name": "LSLAPPS_LabRecorder",
      "value": "ON"
    }
  ]
}
```
	
 * Also consider changing the build and install roots, as the default path is obscure. When you save this file, CMake should reconfigure, and show the output in the output window (including any CMake configuration errors).

 * Note that it is not a typo that Qt refers to msvc2015 rather than msvc2017.

 * Select Startup Item (green arrow dropdown) -> LabRecorder.exe (Install)

 * Click the green arrow. The application should launch.

Note that if you change Qt versions, or other significant changes, it will be necessary to do a full rebuild before CMake correctly notices the change. CMake -> Clean All is not sufficient to force this.

Just deleting the build folder causes an unfortunate error (build folder not found) on rebuild. To do a full rebuild, it is necessary to change the build and install folder paths in CMake -> Change CMake Settings -> LabStreamingLayer, build, then delete the old folder, change the path back, and build again.


## Windows - CMake - Legacy

This procedure also works in Visual Studio 2017, if desired. Generally, I'd recommend sticking with the newer procedure and Visual Studio 2017.

This procedure generates a Visual Studio type project from the CMake files, which can then be opened in Visual Studio.

You will need to download and install:<BR/>
 * The full [LabStreamingLayer meta project](https://github.com/labstreaminglayer/labstreaminglayer) -> Clone (include --recursive flag) or download  
 * Desired Visual Studio Version (the example uses 2015).
 * [CMake 3.12.1](https://cmake.org/files/v3.12/)
 * [Qt 5.11.1](https://download.qt.io/archive/qt/5.11/) 
 * [Boost 1.65.1](https://sourceforge.net/projects/boost/files/boost-binaries/1.65.1/boost_1_65_1-msvc-14.1-32.exe/download)

From the command line, from the labstreaminglayer folder:
 * labstreaminglayer\build>cmake .. -G "Visual Studio 17 2022" -DQt5_DIR="C:/Qt/5.11.1/msvc2015/lib/cmake/Qt5" -DBOOST_ROOT=C:\boost\boost_1_65_1 -DLSLAPPS_LabRecorder=ON

 * labstreaminglayer\build>cmake --build . --config Release --target install

To see a list of possible generators, run the command with garbage in the -G option. 

The executable is in labstreaminglayer\build\install\LabRecorder.

You can open the Visual Studio Project with labstreaminglayer\build\LabStreamingLayer.sln.

The command line install feature does not put build products in the sample place as when you build inside of Visual Studio. To get running to work inside of Visual Studio, it is necessary to copy the support files from labstreaminglayer\build\install\LabRecorder to labstreaminglayer\build\Apps\LabRecorder\Release. You must also right click LabRecorder -> Set as Startup Project and select Release and Win32.<BR/>

If any significant changes are made to the project (such as changing Qt or Visual Stuido version) it is recommended that you delete or rename the build folder and start over. Various partial cleaning processes do not work well.


## Linux

    * Ubuntu (/Debian)
        * `sudo apt-get install build-essential cmake qt5-default libboost-all-dev`

1. Open a Command Prompt / Terminal (Windows: MSVC Command Prompt) and change into this directory.
1. Make a build subdirectory: `mkdir build && cd build`
1. Call cmake
    * `cmake ..`
    * If your liblsl binaries are not in `../../LSL/liblsl/build/install`, add the path (`cmake -DLSL_INSTALL_ROOT=/path/to/liblsl/binaries ..`)
    * Optional: Use a [generator](https://cmake.org/cmake/help/latest/manual/cmake-generators.7.html#visual-studio-generators)
1. You may need to specify additional cmake options.
 . Build everything and copy the files to the `install` folder:
    * `cmake --build . --target install`	


## macOS

See **[macOS (Apple Silicon)](#macos-apple-silicon)** above for the current Homebrew + CMake preset workflow.

