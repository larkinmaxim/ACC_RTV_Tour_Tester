# PowerShell Start Script for ACC RTV Tour Builder
# Builds and runs the RTV Tour Builder container (Podman).
# API credentials are prompted during setup (or passed via parameters); none are stored in code.
param(
    [switch]$BuildOnly,
    [switch]$RunOnly,
    [switch]$Clean,
    [switch]$Help,
    [switch]$NoPause,
    [string]$ContainerName = "rtv-tester",
    [string]$ImageName = "acc-rtv-tester",
    [string]$ImageTag = "latest",
    [int]$Port = 3110,
    [string]$ApiTarget = "https://telemetry.mock.sixfold.com",
    [string]$ApiUsername = "",
    [string]$ApiPassword = ""
)

# Script-scoped credentials (updated by Get-APICredentials when prompting)
$script:ApiTarget = $ApiTarget
$script:ApiUsername = $ApiUsername
$script:ApiPassword = $ApiPassword

function Write-Info { param($Message); Write-Host "[INFO] $Message" -ForegroundColor Green }
function Write-Warn { param($Message); Write-Host "[WARN] $Message" -ForegroundColor Yellow }
function Write-Err { param($Message); Write-Host "[ERROR] $Message" -ForegroundColor Red }
function Write-Step { param($Message); Write-Host "`n=== $Message ===" -ForegroundColor Cyan }

function Pause-IfNeeded {
    if ($NoPause) { return }
    Write-Host "`nPress Enter to continue..." -ForegroundColor Gray
    $null = Read-Host
}

function Show-Usage {
    Write-Host @"
PowerShell Start Script for ACC RTV Tour Builder

Usage: .\Start-RTVTourBuilder.ps1 [OPTIONS]

Options:
    -BuildOnly          Only build the container image (no run)
    -RunOnly            Only run container (assume image exists)
    -Clean              Clean up existing container/image first
    -Help               Show this help message
    -NoPause            Do not pause at end (for automation/IDE)

Parameters (optional):
    -ContainerName      Container name (default: rtv-tester)
    -ImageName          Image name (default: acc-rtv-tester)
    -ImageTag           Image tag (default: latest)
    -Port               Host/container port (default: 3110)
    -ApiTarget          Telemetry API base URL (default: https://telemetry.mock.sixfold.com)
    -ApiUsername        Basic Auth username (required; or enter when prompted)
    -ApiPassword        Basic Auth password (required; or enter when prompted)

Examples:
    .\Start-RTVTourBuilder.ps1                  # Full: build + run
    .\Start-RTVTourBuilder.ps1 -RunOnly         # Run only (image already built)
    .\Start-RTVTourBuilder.ps1 -BuildOnly       # Build image only
    .\Start-RTVTourBuilder.ps1 -Clean           # Clean then build + run

"@ -ForegroundColor Cyan
}

function Test-Requirements {
    Write-Step "Checking Requirements"

    if (-not (Test-Path "Dockerfile") -and -not (Test-Path "package.json")) {
        Write-Err "Not in project directory. Run from RTV Tour Builder root (where Dockerfile/package.json are)."
        Pause-IfNeeded
        exit 1
    }

    try {
        podman --version | Out-Null
        Write-Info "[OK] Podman found"
    } catch {
        Write-Err "Podman is required but not found. Please install Podman first."
        Pause-IfNeeded
        exit 1
    }
}

function Get-APICredentials {
    # Prompt for API credentials during installation (when running interactively).
    if ($NoPause) { return }
    Write-Step "API Credentials (Telemetry API)"
    Write-Host "Enter your API credentials (Basic Auth). Use Ctrl+Shift+V to paste in terminal." -ForegroundColor Gray
    do {
        $u = Read-Host "Username (required)"
        if ($u -ne "") { $script:ApiUsername = $u; break }
        Write-Warn "Username cannot be empty."
    } while ($true)
    do {
        $p = Read-Host "Password (required)"
        if ($p -ne "") { $script:ApiPassword = $p; break }
        Write-Warn "Password cannot be empty."
    } while ($true)
    Write-Info "Using API: $script:ApiTarget (user: $script:ApiUsername)"
}

function Remove-ExistingSetup {
    Write-Step "Cleaning Up"

    podman stop $ContainerName 2>$null
    podman rm $ContainerName 2>$null

    $shortRef = "${ImageName}:${ImageTag}"
    $fullRef = "localhost/${shortRef}"
    $image = podman images --format "{{.Repository}}:{{.Tag}}" 2>$null | Where-Object { $_ -eq $shortRef -or $_ -eq $fullRef }
    if ($image) {
        podman rmi $fullRef 2>$null
        podman rmi $shortRef 2>$null
    }

    Write-Info "Cleaning up dangling images..."
    podman image prune -f | Out-Null

    Write-Info "[OK] Cleanup complete"
}

function New-ContainerImage {
    Write-Step "Building Container Image"

    if (-not (Test-Path "Dockerfile")) {
        Write-Err "Dockerfile not found in current directory."
        Pause-IfNeeded
        exit 1
    }

    Write-Info "Building image ${ImageName}:${ImageTag}..."
    podman build -t "${ImageName}:${ImageTag}" .
    if ($LASTEXITCODE -ne 0) {
        Write-Err "Container build failed."
        Pause-IfNeeded
        exit 1
    }

    Write-Info "Cleaning up dangling images..."
    podman image prune -f | Out-Null
    Write-Info "[OK] Container image built successfully"
}

function Start-Container {
    Write-Step "Starting Container"

    # Stop and remove existing container if present
    $existing = podman ps -a --format "{{.Names}}" 2>$null | Where-Object { $_ -eq $ContainerName }
    if ($existing) {
        Write-Info "Stopping and removing existing container..."
        podman stop $ContainerName 2>$null
        podman rm $ContainerName 2>$null
    }

    # Credentials required (no defaults in code)
    if (-not $script:ApiUsername -or -not $script:ApiPassword) {
        Write-Err "API username and password are required. Run without -NoPause to enter them, or pass -ApiUsername and -ApiPassword."
        Pause-IfNeeded
        exit 1
    }

    # Check image exists (Podman tags as localhost/name:tag)
    $shortRef = "${ImageName}:${ImageTag}"
    $fullRef = "localhost/${shortRef}"
    $imageExists = podman images --format "{{.Repository}}:{{.Tag}}" 2>$null | Where-Object { $_ -eq $shortRef -or $_ -eq $fullRef }
    if (-not $imageExists) {
        Write-Err "Image ${shortRef} not found. Run without -RunOnly first to build."
        Pause-IfNeeded
        exit 1
    }

    # Use full reference so Podman finds the image (localhost/acc-rtv-tester:latest)
    $imageRef = $fullRef
    Write-Info "Starting container (port ${Port})..."
    Write-Info "API: $script:ApiTarget (Basic Auth: $script:ApiUsername)"
    podman run -d `
        -p "${Port}:${Port}" `
        --name $ContainerName `
        -e "PORT=$Port" `
        -e "RTV_API_TARGET=$script:ApiTarget" `
        -e "RTV_API_USERNAME=$script:ApiUsername" `
        -e "RTV_API_PASSWORD=$script:ApiPassword" `
        $imageRef

    if ($LASTEXITCODE -ne 0) {
        Write-Err "Failed to start container."
        Pause-IfNeeded
        exit 1
    }

    Start-Sleep -Seconds 2
    $running = podman ps --format "{{.Names}}" | Where-Object { $_ -eq $ContainerName }
    if ($running) {
        Write-Info "[OK] Container is running"
    } else {
        Write-Warn "[!] Container may have failed. Check logs:"
        podman logs $ContainerName
        Pause-IfNeeded
    }
}

function Test-Deployment {
    Write-Step "Verifying Deployment"

    $running = podman ps --format "{{.Names}}" | Where-Object { $_ -eq $ContainerName }
    if (-not $running) {
        Write-Err "[X] Container not running."
        podman logs $ContainerName
        Pause-IfNeeded
        exit 1
    }

    Write-Info "[OK] Container is running"

    # Optional: quick check that the app responds
    $appUrl = "http://localhost:${Port}/index.html"
    Write-Info "Checking application at $appUrl ..."
    Start-Sleep -Seconds 1
    try {
        $response = Invoke-WebRequest -Uri $appUrl -Method GET -UseBasicParsing -TimeoutSec 5
        if ($response.StatusCode -eq 200) {
            Write-Info "[OK] Application is reachable"
        } else {
            Write-Warn "[!] Application returned status: $($response.StatusCode)"
        }
    } catch {
        Write-Warn "[!] Could not reach application: $($_.Exception.Message)"
    }

    Write-Info "[SUCCESS] RTV Tour Builder is ready!"
    Write-Info "[ENDPOINTS]"
    Write-Host "  http://localhost:${Port}/index.html    # Open in browser" -ForegroundColor White
    Write-Info "[TOOLS] Management commands:"
    Write-Host "  podman logs -f $ContainerName    # View logs" -ForegroundColor White
    Write-Host "  podman stop $ContainerName       # Stop" -ForegroundColor White
    Write-Host "  podman start $ContainerName     # Start" -ForegroundColor White
    Write-Host "  podman restart $ContainerName   # Restart" -ForegroundColor White
    Pause-IfNeeded
}

# Main execution
if ($Help) {
    Show-Usage
    return
}

Write-Host @"

================================================================
           ACC RTV Tour Builder - Start (PowerShell)
================================================================
  [*] Build and run the RTV Tour Builder container (Podman)
  [*] Port: $Port  |  Container: $ContainerName  |  Image: ${ImageName}:${ImageTag}
  [*] API: $ApiTarget  (credentials entered at run or via parameters)
================================================================

"@ -ForegroundColor Blue

Test-Requirements

if ($Clean) {
    Remove-ExistingSetup
}

if (-not $RunOnly) {
    New-ContainerImage
}

if (-not $BuildOnly) {
    Get-APICredentials
    Start-Container
    Test-Deployment
} else {
    Write-Step "Build Complete"
    Write-Info "[OK] Image built. Run with: .\Start-RTVTourBuilder.ps1 -RunOnly"
    Pause-IfNeeded
}
