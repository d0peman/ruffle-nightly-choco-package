# chocolateyinstall.ps1
$ErrorActionPreference = 'Stop'

$toolsDir = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$params = Get-PackageParameters

# URLs and checksums updated by update.ps1
$url32 = 'URL32_REPLACED_BY_UPDATER'
$url64 = 'URL64_REPLACED_BY_UPDATER'

$checksum32 = 'CHECKSUM32_REPLACED_BY_UPDATER'
$checksum64 = 'CHECKSUM64_REPLACED_BY_UPDATER'

$zipFile = Join-Path $toolsDir "ruffle.zip"

# Download appropriate file
Get-ChocolateyWebFile `
  -PackageName $env:ChocolateyPackageName `
  -FileFullPath $zipFile `
  -Url $url32 `
  -Url64bit $url64 `
  -Checksum $checksum32 `
  -ChecksumType 'sha256' `
  -Checksum64 $checksum64 `
  -ChecksumType64 'sha256'

# Unzip to tools directory
Get-ChocolateyUnzip `
  -FileFullPath $zipFile `
  -Destination $toolsDir

# Install either portable or MSI
if ($params.portable) {
    Install-BinFile `
        -Name "ruffle" `
        -Path (Join-Path $toolsDir "ruffle.exe")
} else {
    $msi = Join-Path $toolsDir "setup.msi"

    $packageArgs = @{
        packageName    = $env:ChocolateyPackageName
        fileType       = "MSI"
        file           = $msi
        silentArgs     = "/qn /norestart"
        validExitCodes = @(0)
    }

    Install-ChocolateyInstallPackage @packageArgs
}
