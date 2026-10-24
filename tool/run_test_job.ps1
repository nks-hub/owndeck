param([Parameter(Mandatory)][string]$ConfigFile)

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
$config = Get-Content -LiteralPath $ConfigFile -Raw | ConvertFrom-Json
$started = [DateTime]::UtcNow.ToString('o')
$phase = 'setup'
$code = 1
$failure = $null
try {
    $head = (& git -C $config.sourceRoot rev-parse HEAD).Trim()
    if ($LASTEXITCODE -ne 0 -or $head -ne $config.revision) {
        throw 'snapshot_revision_changed'
    }
    $env:CI = 'true'
    $env:FLUTTER_SUPPRESS_ANALYTICS = 'true'
    Set-Location -LiteralPath $config.packageRoot
    $runner = if ($config.flutterPath) { $config.flutterPath } else { $config.dartPath }
    & $runner pub get --enforce-lockfile *> $config.setupLog
    $code = $LASTEXITCODE
    if ($code -eq 0) {
        $phase = 'tests'
        & $runner test --reporter=json --timeout=60s *> $config.testLog
        $code = $LASTEXITCODE
    }
} catch {
    $code = 1
    $failure = $_.Exception.GetType().Name
    $_ | Out-String | Add-Content -LiteralPath $config.setupLog -Encoding utf8
} finally {
    [ordered]@{
        revision = $config.revision
        package = $config.package
        sourceRoot = $config.sourceRoot
        pid = $PID
        startedUtc = $started
        finishedUtc = [DateTime]::UtcNow.ToString('o')
        phase = $phase
        exitCode = $code
        failure = $failure
    } | ConvertTo-Json | Set-Content -LiteralPath $config.resultFile -Encoding utf8
}
exit $code
