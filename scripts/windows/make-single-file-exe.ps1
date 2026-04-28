param(
    [Parameter(Mandatory=$true)] [string]$AppExe,
    [Parameter(Mandatory=$true)] [string]$OutDir,
    [Parameter(Mandatory=$true)] [string]$OutputExe,
    [Parameter(Mandatory=$false)] [string]$SevenZipDir
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Requirements:
# - 7-Zip installed and 7z.exe available in PATH
# - 7z SFX module (7z.sfx). If not found in PATH, set $SfxPath below

function Resolve-7z {
    $candidates = @()
    if([string]::IsNullOrWhiteSpace($SevenZipDir) -eq $false){
        $candidates += (Join-Path $SevenZipDir '7z.exe')
    }
    $candidates += @(
        '7z.exe',
        'C:\\Program Files\\7-Zip\\7z.exe',
        'C:\\Program Files (x86)\\7-Zip\\7z.exe'
    )
    foreach($c in $candidates){ if(Test-Path $c){ return $c } }
    $cmd = Get-Command '7z.exe' -ErrorAction SilentlyContinue
    if($cmd){ return $cmd.Path }
    throw '7z.exe not found. Install 7-Zip or provide -SevenZipDir.'
}

function Resolve-Sfx {
    $candidates = @()
    if([string]::IsNullOrWhiteSpace($SevenZipDir) -eq $false){
        $candidates += (Join-Path $SevenZipDir '7z.sfx')
    }
    $candidates += @(
        '7z.sfx',
        'C:\\Program Files\\7-Zip\\7z.sfx',
        'C:\\Program Files (x86)\\7-Zip\\7z.sfx'
    )
    foreach($c in $candidates){ if(Test-Path $c){ return $c } }
    throw '7z.sfx not found. Provide -SevenZipDir or ensure it is in PATH.'
}

$AppExe = Resolve-Path $AppExe | Select-Object -ExpandProperty Path
$OutDir = Resolve-Path $OutDir | Select-Object -ExpandProperty Path
$OutputExe = [System.IO.Path]::GetFullPath($OutputExe)

if(!(Test-Path $AppExe)){ throw "App exe not found: $AppExe" }
if(!(Test-Path $OutDir)){ throw "Output dir not found: $OutDir" }

$sevenZip = Resolve-7z
$sfxPath = Resolve-Sfx

# Create a staging directory that includes everything next to the app exe
$staging = Join-Path $OutDir 'singlefile_staging'
if(Test-Path $staging){ Remove-Item -Recurse -Force $staging }
New-Item -ItemType Directory -Path $staging | Out-Null

# Copy all runtime artifacts next to the exe into staging
Get-ChildItem -Path $OutDir -Force | ForEach-Object {
    if($_.Name -ne 'singlefile_staging' -and $_.Name -ne 'LabRecorder-single.exe'){
        $dest = Join-Path $staging $_.Name
        if($_.PSIsContainer){ Copy-Item -Recurse -Force $_.FullName $dest }
        else { Copy-Item -Force $_.FullName $dest }
    }
}

# Create config to auto-extract and run the app
$configTxt = @"
;!@Install@!UTF-8!
Title="LabRecorder Single-File"
RunProgram="LabRecorder.exe"
; Extract to %LOCALAPPDATA% subfolder to avoid requiring write access
InstallPath="%LOCALAPPDATA%\\LabRecorder_SFX"
GUIMode="2"
;!@InstallEnd@!
"@

$configFile = Join-Path $staging 'config.txt'
Set-Content -Path $configFile -Value $configTxt -Encoding UTF8

# Build archive in %TEMP% to avoid locked OutDir\LabRecorder.7z from prior runs
$archive = Join-Path ([System.IO.Path]::GetTempPath()) ("LabRecorder_" + [Guid]::NewGuid().ToString("N") + ".7z")
Push-Location $staging
& $sevenZip a -t7z -m0=LZMA2 -mx=5 -mmt=on $archive * | Out-Null
Pop-Location

# Concatenate SFX + config + archive into a self-extracting EXE (build in %TEMP% then copy; avoids locked $OutputExe)
$outTmp = Join-Path ([System.IO.Path]::GetTempPath()) ("LabRecorder_sfx_" + [Guid]::NewGuid().ToString("N") + ".exe")
Get-Content -Path $sfxPath -Encoding Byte | Set-Content -Path $outTmp -Encoding Byte
Get-Content -Path $configFile -Encoding Byte | Add-Content -Path $outTmp -Encoding Byte
Get-Content -Path $archive -Encoding Byte | Add-Content -Path $outTmp -Encoding Byte
Remove-Item -Force $archive -ErrorAction SilentlyContinue
$copied = $false
for($i = 0; $i -lt 20; $i++){
    try {
        Copy-Item -LiteralPath $outTmp -Destination $OutputExe -Force -ErrorAction Stop
        $copied = $true
        break
    } catch {
        Start-Sleep -Milliseconds 350
    }
}
Remove-Item -Force $outTmp -ErrorAction SilentlyContinue
if(-not $copied){ throw "Could not write $OutputExe (file may be locked by another process)." }

Write-Host "Created single-file executable: $OutputExe"


