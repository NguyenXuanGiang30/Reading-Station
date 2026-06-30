param(
    [Parameter(Mandatory = $true)]
    [string]$AppId,

    [Parameter(Mandatory = $true)]
    [string]$StorePassword,

    [Parameter(Mandatory = $true)]
    [string]$KeyPassword,

    [string]$AppName = "Tram Doc",
    [string]$KeyAlias = "release",
    [string]$KeystorePath = "android\\app-release.jks",
    [int]$ValidityDays = 3650,
    [string]$DistinguishedName = "CN=Tram Doc, OU=Mobile, O=Tram Doc, L=HCM, S=HCM, C=VN"
)

$ErrorActionPreference = "Stop"

function Resolve-Keytool {
    $command = Get-Command keytool -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }

    if ($env:JAVA_HOME) {
        $candidate = Join-Path $env:JAVA_HOME "bin\\keytool.exe"
        if (Test-Path $candidate) {
            return $candidate
        }
    }

    throw "Cannot find keytool.exe. Install a JDK or set JAVA_HOME first."
}

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$keystoreAbsolutePath = Join-Path $projectRoot $KeystorePath
$keystoreDirectory = Split-Path $keystoreAbsolutePath -Parent
$keystorePropertiesPath = Join-Path $projectRoot "android\\keystore.properties"
$keytool = Resolve-Keytool

New-Item -ItemType Directory -Force -Path $keystoreDirectory | Out-Null

if (!(Test-Path $keystoreAbsolutePath)) {
    & $keytool `
        -genkeypair `
        -v `
        -storetype PKCS12 `
        -keystore $keystoreAbsolutePath `
        -storepass $StorePassword `
        -keypass $KeyPassword `
        -alias $KeyAlias `
        -keyalg RSA `
        -keysize 2048 `
        -validity $ValidityDays `
        -dname $DistinguishedName
}

$escapedKeystorePath = $keystoreAbsolutePath.Replace("\", "\\")
@(
    "APP_ID=$AppId"
    "APP_NAME=$AppName"
    "storeFile=$escapedKeystorePath"
    "storePassword=$StorePassword"
    "keyAlias=$KeyAlias"
    "keyPassword=$KeyPassword"
) | Set-Content -Path $keystorePropertiesPath -Encoding ASCII

Write-Output "Created/updated:"
Write-Output " - $keystoreAbsolutePath"
Write-Output " - $keystorePropertiesPath"
Write-Output ""
Write-Output "Next steps:"
Write-Output "1. Add the Firebase Android app with package name $AppId."
Write-Output "2. Download google-services.json and replace frontend/android/app/google-services.json."
Write-Output "3. Build with:"
Write-Output "   flutter build appbundle --release --dart-define=PROD_API_BASE_URL=https://your-api-domain"
