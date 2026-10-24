param([Parameter(Mandatory)][string]$ConfigFile)

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
$config = Get-Content -LiteralPath $ConfigFile -Raw | ConvertFrom-Json
$started = [DateTime]::UtcNow.ToString('o')
$phase = 'setup'
$code = 1
$apk = $null
$sha256 = $null
$failure = $null
$telemetryConfigured = $false
try {
    $head = (& git -C $config.sourceRoot rev-parse HEAD).Trim()
    if ($LASTEXITCODE -ne 0 -or $head -ne $config.revision) { throw 'snapshot_revision_changed' }
    $env:CI = 'true'
    $env:FLUTTER_SUPPRESS_ANALYTICS = 'true'
    $env:ANDROID_HOME = $config.androidHome
    $env:ANDROID_SDK_ROOT = $config.androidHome
    $env:JAVA_HOME = $config.javaHome
    # Kotlin's incremental path converter cannot relativize plugin sources across volumes.
    $env:PUB_CACHE = if ($config.pubCache) { $config.pubCache } else { Join-Path (Split-Path $config.sourceRoot -Parent) 'pub-cache' }
    if (-not [string]::Equals([IO.Path]::GetPathRoot($env:PUB_CACHE), [IO.Path]::GetPathRoot($config.sourceRoot), [StringComparison]::OrdinalIgnoreCase)) {
        throw 'pub_cache_volume_mismatch'
    }
    New-Item -ItemType Directory -Path $env:PUB_CACHE -Force | Out-Null
    $env:GRADLE_OPTS = '-Dorg.gradle.workers.max=2 -Dorg.gradle.jvmargs=-Xmx3G -Dorg.gradle.daemon=false'
    Set-Location -LiteralPath (Join-Path $config.sourceRoot 'apps\mobile')
    & $config.flutterPath pub get --enforce-lockfile *> $config.setupLog
    $code = $LASTEXITCODE
    if ($code -eq 0) {
        $phase = 'build'
        $buildArguments = @('build', 'apk', '--debug', '--target-platform', 'android-arm64', '--android-project-arg=candidate=true')
        if ($config.telemetryFile) {
            try { $definitions = Get-Content -LiteralPath $config.telemetryFile -Raw | ConvertFrom-Json }
            catch { throw 'invalid_telemetry_configuration' }
            foreach ($key in @('SENTRY_DSN', 'RYBBIT_HOST', 'RYBBIT_SITE_ID')) {
                if ([string]::IsNullOrWhiteSpace($definitions.$key)) { throw 'missing_telemetry_configuration' }
            }
            if ([string]$definitions.TELEMETRY_RELEASE_PROBE -eq 'true') { throw 'probe_build_not_allowed' }
            $buildArguments += "--dart-define-from-file=$($config.telemetryFile)"
            $telemetryConfigured = $true
        }
        & $config.flutterPath @buildArguments *> $config.buildLog
        $code = $LASTEXITCODE
    }
    if ($code -eq 0) {
        $phase = 'artifact'
        $apk = Join-Path (Get-Location).Path 'build\app\outputs\flutter-apk\app-debug.apk'
        if (-not (Test-Path -LiteralPath $apk)) { throw 'apk_missing' }
        $badging = & $config.aaptPath dump badging $apk
        if ($LASTEXITCODE -ne 0 -or -not ($badging -match "package: name='com.nkshub.nextclouddeck.candidate'")) {
            throw 'unexpected_application_id'
        }
        $changes = @(& git -C $config.sourceRoot diff --name-only)
        if ($LASTEXITCODE -ne 0 -or $changes.Count -ne 0) { throw 'tracked_source_changed_during_build' }
        $sha256 = (Get-FileHash -LiteralPath $apk -Algorithm SHA256).Hash.ToLowerInvariant()
        $phase = 'built'
    }
} catch {
    $code = 1
    $failure = $_.Exception.Message
} finally {
    [ordered]@{
        revision = $config.revision
        sourceRoot = $config.sourceRoot
        pid = $PID
        startedUtc = $started
        finishedUtc = [DateTime]::UtcNow.ToString('o')
        phase = $phase
        exitCode = $code
        failure = $failure
        apk = $apk
        sha256 = $sha256
        applicationId = 'com.nkshub.nextclouddeck.candidate'
        buildMode = 'debug'
        telemetryConfigured = $telemetryConfigured
    } | ConvertTo-Json | Set-Content -LiteralPath $config.resultFile -Encoding utf8
}
exit $code
