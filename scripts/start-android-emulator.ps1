# Launch Android emulator and wait until ADB reports it as ready.
# Usage:
#   .\scripts\start-android-emulator.ps1
#   .\scripts\start-android-emulator.ps1 -AvdName Pixel_8
#   .\scripts\start-android-emulator.ps1 -List

param(
    [string]$AvdName = "",
    [switch]$List,
    [int]$BootTimeoutSeconds = 180
)

$ErrorActionPreference = "Stop"

function Get-AndroidSdkRoot {
    foreach ($name in @("ANDROID_SDK_ROOT", "ANDROID_HOME")) {
        $value = [Environment]::GetEnvironmentVariable($name, "Process")
        if (-not $value) {
            $value = [Environment]::GetEnvironmentVariable($name, "User")
        }
        if (-not $value) {
            $value = [Environment]::GetEnvironmentVariable($name, "Machine")
        }
        if ($value -and (Test-Path $value)) {
            return $value
        }
    }

    $defaultSdk = Join-Path $env:LOCALAPPDATA "Android\Sdk"
    if (Test-Path $defaultSdk) {
        return $defaultSdk
    }

    throw "Android SDK not found. Set ANDROID_SDK_ROOT or install Android SDK."
}

function Get-SdkToolPath {
    param(
        [string]$SdkRoot,
        [string]$RelativePath
    )

    $toolPath = Join-Path $SdkRoot $RelativePath
    if (-not (Test-Path $toolPath)) {
        throw "Tool not found: $toolPath"
    }
    return $toolPath
}

$sdkRoot = Get-AndroidSdkRoot
$emulatorExe = Get-SdkToolPath -SdkRoot $sdkRoot -RelativePath "emulator\emulator.exe"
$adbExe = Get-SdkToolPath -SdkRoot $sdkRoot -RelativePath "platform-tools\adb.exe"

$avds = & $emulatorExe -list-avds
if (-not $avds -or $avds.Count -eq 0) {
    throw "No Android Virtual Devices found. Create one in Android Studio (Device Manager)."
}

if ($List) {
    Write-Host "Available AVDs:"
    $avds | ForEach-Object { Write-Host "  $_" }
    exit 0
}

if ([string]::IsNullOrWhiteSpace($AvdName)) {
    $AvdName = $avds[0]
    if ($avds.Count -gt 1 -and ($avds -contains "Pixel_8")) {
        $AvdName = "Pixel_8"
    }
}

if ($avds -notcontains $AvdName) {
    Write-Host "AVD '$AvdName' not found. Available AVDs:"
    $avds | ForEach-Object { Write-Host "  $_" }
    exit 1
}

Write-Host "Starting emulator: $AvdName"

$runningEmulators = & $adbExe devices | Select-String "emulator-\d+\s+device"
if ($runningEmulators) {
    Write-Host "An emulator is already running:"
    & $adbExe devices
    exit 0
}

$emulatorProcess = Start-Process `
    -FilePath $emulatorExe `
    -ArgumentList @("-avd", $AvdName, "-no-snapshot-load") `
    -PassThru

Write-Host "Waiting for ADB device (timeout: ${BootTimeoutSeconds}s)..."
$deadline = (Get-Date).AddSeconds($BootTimeoutSeconds)
$deviceReady = $false

while ((Get-Date) -lt $deadline) {
    if ($emulatorProcess.HasExited) {
        throw "Emulator process exited unexpectedly (exit code $($emulatorProcess.ExitCode))."
    }

    & $adbExe wait-for-device 2>$null | Out-Null

    $bootCompleted = & $adbExe shell getprop sys.boot_completed 2>$null
    if ($bootCompleted -match "1") {
        $deviceReady = $true
        break
    }

    Start-Sleep -Seconds 2
}

if (-not $deviceReady) {
    Write-Warning "Emulator started but boot did not finish within ${BootTimeoutSeconds}s."
} else {
    Write-Host "Emulator is ready."
}

Write-Host ""
Write-Host "Connected devices:"
& $adbExe devices
