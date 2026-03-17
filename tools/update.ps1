# update.ps1
$repoOwner = "ruffle-rs"
$repoName  = "ruffle"
$apiUrl    = "https://api.github.com/repos/$repoOwner/$repoName/releases"

# Path variables
$templateFile = ".\tools\chocolateyinstall.ps1.template"
$targetFile   = ".\tools\chocolateyinstall.ps1"

# Ensure the target file exists
if (-Not (Test-Path $targetFile)) {
    Copy-Item -Path $templateFile -Destination $targetFile
} else {
    Copy-Item -Path $templateFile -Destination $targetFile -Force
}

# Fetch releases
$headers = @{
    Authorization = "Bearer $env:GITHUB_TOKEN"
    Accept        = "application/vnd.github+json"
}

$releases = Invoke-RestMethod -Uri $apiUrl -Headers $headers

# Pick the latest nightly (prerelease)
$latest = $releases | Where-Object { $_.prerelease -eq $true } | Select-Object -First 1
if (-not $latest) { throw "No nightly (prerelease) found." }

# Find assets and their digests
$asset64 = $latest.assets | Where-Object { $_.name -match "windows-x86_64.zip" } | Select-Object -First 1
$asset32 = $latest.assets | Where-Object { $_.name -match "windows-x86_32.zip" } | Select-Object -First 1

if (-not $asset64 -or -not $asset32) { throw "Could not find required 32-bit or 64-bit assets." }

$url64 = $asset64.browser_download_url
$url32 = $asset32.browser_download_url

$checksum64 = $asset64.digest -replace '^sha256:',''
$checksum32 = $asset32.digest -replace '^sha256:',''

# Extract version number from URL
$version = ($url64 -split "ruffle-nightly-")[1] -replace "-windows.*","" -replace "_","."

(Get-Content .\tools\chocolateyinstall.ps1) |
    ForEach-Object {
        $_ -replace 'URL32_REPLACED_BY_UPDATER', $url32 `
           -replace 'URL64_REPLACED_BY_UPDATER', $url64 `
           -replace 'CHECKSUM32_REPLACED_BY_UPDATER', $checksum32 `
           -replace 'CHECKSUM64_REPLACED_BY_UPDATER', $checksum64
    } | Set-Content .\tools\chocolateyinstall.ps1

$nuspecPath = ".\ruffle-nightly.nuspec"

if (-not (Test-Path $nuspecPath)) {
    throw "Cannot find ruffle-nightly.nuspec at $nuspecPath"
}

# Read the nuspec content
$nuspecContent = Get-Content $nuspecPath

# Replace the <version> element with the latest nightly version
$nuspecContent = $nuspecContent -replace '<version>.*?</version>', "<version>$($version)</version>"

# Write back
Set-Content -Path $nuspecPath -Value $nuspecContent

Write-Host "Updated nuspec version to $($version)"
Write-Host "Updated chocolateyinstall.ps1 to Ruffle nightly version $($version)"
