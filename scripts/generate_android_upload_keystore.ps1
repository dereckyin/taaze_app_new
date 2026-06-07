# Generates an upload keystore and android/key.properties for Play Console.
# Run from repo root:  powershell -ExecutionPolicy Bypass -File scripts/generate_android_upload_keystore.ps1

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$androidDir = Join-Path $repoRoot "android"
$appDir = Join-Path $androidDir "app"
$keyProperties = Join-Path $androidDir "key.properties"
$keystorePath = Join-Path $appDir "upload-keystore.jks"
$keytool = Join-Path ${env:ProgramFiles} "Android\Android Studio\jbr\bin\keytool.exe"

if (-not (Test-Path $keytool)) {
    Write-Error "找不到 keytool。請確認已安裝 Android Studio，或手動設定 JAVA_HOME。"
}

if (Test-Path $keystorePath) {
    Write-Host "Keystore 已存在: $keystorePath"
    $overwrite = Read-Host "是否覆寫？(y/N)"
    if ($overwrite -ne "y" -and $overwrite -ne "Y") {
        Write-Host "已取消。"
        exit 0
    }
}

Write-Host ""
Write-Host "請設定 upload keystore 密碼（請妥善保存，Play Console 上傳金鑰需要用到）："
$storePassword = Read-Host "Keystore 密碼" -AsSecureString
$keyPasswordSecure = Read-Host "Key 密碼（直接 Enter 表示與 Keystore 相同）" -AsSecureString

function ConvertTo-PlainText([Security.SecureString] $secure) {
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try {
        return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
    } finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    }
}

$storePassPlain = ConvertTo-PlainText $storePassword
$keyPassPlain = if ($keyPasswordSecure.Length -eq 0) { $storePassPlain } else { ConvertTo-PlainText $keyPasswordSecure }

& $keytool -genkeypair `
    -v `
    -keystore $keystorePath `
    -alias upload `
    -keyalg RSA `
    -keysize 2048 `
    -validity 10000 `
    -storepass $storePassPlain `
    -keypass $keyPassPlain `
    -dname "CN=TAAZE Bookstore, OU=Mobile, O=TAAZE, L=Taipei, ST=Taiwan, C=TW"

$propsContent = @"
storePassword=$storePassPlain
keyPassword=$keyPassPlain
keyAlias=upload
storeFile=upload-keystore.jks
"@
[System.IO.File]::WriteAllText($keyProperties, $propsContent.TrimStart(), [System.Text.UTF8Encoding]::new($false))

Write-Host ""
Write-Host "✓ 已建立 keystore: $keystorePath"
Write-Host "✓ 已建立 key.properties: $keyProperties"
Write-Host ""
Write-Host "Release SHA-1（請加到 Google Cloud OAuth / Firebase）："
& $keytool -list -v -keystore $keystorePath -alias upload -storepass $storePassPlain -keypass $keyPassPlain 2>&1 | Select-String -Pattern "SHA1|SHA256"
Write-Host ""
Write-Host "下一步："
Write-Host "  flutter build appbundle --release"
Write-Host "  產出：build/app/outputs/bundle/release/app-release.aab"
