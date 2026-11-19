param(
    [string]$GradleVersion = "9.9.1"
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$workspaceRoot = Split-Path -Parent $projectRoot
$localZip = Join-Path $workspaceRoot ("reference_resources/gradle-{0}-bin.zip" -f $GradleVersion)

if (-not (Test-Path -LiteralPath $localZip)) {
    throw "Local Gradle distribution not found: $localZip"
}

$distributionUrl = ([System.Uri]::new($localZip)).AbsoluteUri.Replace('\', '\\')
$propertiesPath = Join-Path $projectRoot "gradle/wrapper/gradle-wrapper.properties"
$content = Get-Content -LiteralPath $propertiesPath -Raw
$updated = [regex]::Replace($content, '(?m)^distributionUrl=.*$', "distributionUrl=$distributionUrl")

if ($updated -eq $content) {
    throw "distributionUrl was not found in $propertiesPath"
}

Set-Content -LiteralPath $propertiesPath -Value $updated -NoNewline
Write-Host "Gradle wrapper now uses the local distribution: $distributionUrl"
Write-Host "Restore the public URL with: git checkout -- gradle/wrapper/gradle-wrapper.properties"
