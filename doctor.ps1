# Workflow MCP Server — Installation Doctor
# Run: .\doctor.ps1

$ErrorActionPreference = "Continue"
$pass = 0
$fail = 0

Write-Host "`nWorkflow MCP Server — Doctor`n" -ForegroundColor Cyan
Write-Host "=" * 50

# Check 1: Binary exists
Write-Host "`n[1/4] Checking workflow binary..." -NoNewline
$binaryPaths = @(
    "C:\CPC\servers\workflow.exe",
    (Join-Path $PSScriptRoot "workflow.exe"),
    (Get-Command workflow.exe -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -ErrorAction SilentlyContinue)
) | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1

if ($binaryPaths) {
    $info = Get-Item $binaryPaths
    $sizeMB = [math]::Round($info.Length / 1MB, 1)
    Write-Host " PASS" -ForegroundColor Green
    Write-Host "   Found: $binaryPaths ($sizeMB MB)"
    $pass++
} else {
    Write-Host " FAIL" -ForegroundColor Red
    Write-Host "   workflow.exe not found in C:\CPC\servers\, script directory, or PATH"
    $fail++
}

# Check 2: DPAPI available
Write-Host "`n[2/4] Checking DPAPI availability..." -NoNewline
try {
    $testBytes = [System.Text.Encoding]::UTF8.GetBytes("dpapi-test")
    $encrypted = [System.Security.Cryptography.ProtectedData]::Protect(
        $testBytes, $null,
        [System.Security.Cryptography.DataProtectionScope]::CurrentUser
    )
    $decrypted = [System.Security.Cryptography.ProtectedData]::Unprotect(
        $encrypted, $null,
        [System.Security.Cryptography.DataProtectionScope]::CurrentUser
    )
    $result = [System.Text.Encoding]::UTF8.GetString($decrypted)
    if ($result -eq "dpapi-test") {
        Write-Host " PASS" -ForegroundColor Green
        Write-Host "   DPAPI encrypt/decrypt roundtrip successful"
        $pass++
    } else {
        Write-Host " FAIL" -ForegroundColor Red
        Write-Host "   DPAPI roundtrip mismatch"
        $fail++
    }
} catch {
    Write-Host " FAIL" -ForegroundColor Red
    Write-Host "   DPAPI not available: $($_.Exception.Message)"
    $fail++
}

# Check 3: Storage directory writable
Write-Host "`n[3/4] Checking storage directory..." -NoNewline
$storageDir = "C:\CPC\workflows"
if (-not (Test-Path $storageDir)) {
    try {
        New-Item -ItemType Directory -Path $storageDir -Force | Out-Null
        Write-Host " PASS" -ForegroundColor Green
        Write-Host "   Created $storageDir"
        $pass++
    } catch {
        Write-Host " FAIL" -ForegroundColor Red
        Write-Host "   Cannot create $storageDir — $($_.Exception.Message)"
        $fail++
    }
} else {
    $testFile = Join-Path $storageDir ".doctor_test"
    try {
        "test" | Out-File -FilePath $testFile -Force
        Remove-Item $testFile -Force
        Write-Host " PASS" -ForegroundColor Green
        Write-Host "   $storageDir exists and is writable"
        $pass++
    } catch {
        Write-Host " FAIL" -ForegroundColor Red
        Write-Host "   $storageDir exists but is not writable"
        $fail++
    }
}

# Check 4: Architecture
Write-Host "`n[4/4] Checking architecture..." -NoNewline
$arch = [System.Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture
Write-Host " INFO" -ForegroundColor Yellow
Write-Host "   Running on: $arch"
if ($arch -eq "Arm64") {
    Write-Host "   Ensure you have the ARM64 build of workflow.exe"
} else {
    Write-Host "   Ensure you have the x64 build of workflow.exe"
}
$pass++

# Summary
Write-Host "`n" + ("=" * 50)
Write-Host "`nResults: " -NoNewline
Write-Host "$pass passed" -ForegroundColor Green -NoNewline
if ($fail -gt 0) {
    Write-Host ", $fail failed" -ForegroundColor Red
} else {
    Write-Host ""
}

if ($fail -eq 0) {
    Write-Host "`nWorkflow MCP server is ready." -ForegroundColor Green
} else {
    Write-Host "`nFix the issues above before using workflow." -ForegroundColor Yellow
}

Write-Host ""
