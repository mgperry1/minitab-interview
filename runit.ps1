[CmdletBinding()]
param(
    [string]$Port =$(if ($env:PORT) {$env:PORT } else { "3000" }),
    [string]$HostPort =$(if ($env:HOST_PORT) {$env:HOST_PORT } else { "3000" }),
    [string]$ImageName =$(if ($env:IMAGE_NAME) {$env:IMAGE_NAME } else { "stats-service" }),
    [string]$AppVersion =$(if ($env:APP_VERSION) {$env:APP_VERSION } else { "1.0.0" }),
    [string]$ContainerName =$(if ($env:CONTAINER_NAME) {$env:CONTAINER_NAME } else { "stats-service-app" })
)

$ErrorActionPreference = "Stop"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host " Starting Build, Test & Run Pipeline (PowerShell)" -ForegroundColor Cyan
Write-Host " Image:          $ImageName"
Write-Host " Container:      $ContainerName"
Write-Host " Host Port:      $HostPort"
Write-Host " Container Port: $Port"
Write-Host " App Version:    $AppVersion"   
Write-Host "=================================================="

# Step 1: Build Docker image
Write-Host "==> Building Docker image..." -ForegroundColor Yellow
docker build -t $ImageName .
if ($LASTEXITCODE -ne 0) { throw "Docker build failed." }

# Step 2: Run pytest unit tests inside container
Write-Host "==> Running pytest unit tests inside container..." -ForegroundColor Yellow
docker run --rm $ImageName pytest -v tests/
if ($LASTEXITCODE -ne 0) { throw "Pytest unit tests failed." }
Write-Host "==> Unit tests passed successfully." -ForegroundColor Green

# Step 3: Remove existing container if currently running
$existing = docker ps -a --filter "name=^/${ContainerName}$" --format "{{.Names}}"
if ($existing) {
    Write-Host "==> Stopping and removing existing container '$ContainerName'..." -ForegroundColor Yellow
    docker rm -f $ContainerName | Out-Null
}

# Step 4: Run the application container
Write-Host "==> Starting container '$ContainerName' on port ${HostPort}:${Port}..." -ForegroundColor Yellow
docker run -d `
    --name $ContainerName `
    -e PORT=$Port `
    -e APP_VERSION=$AppVersion `
    -p "${HostPort}:${Port}" `
    $ImageName | Out-Null

if ($LASTEXITCODE -ne 0) { throw "Failed to start container." }

# Step 5: Wait and verify health check endpoint
Write-Host "==> Verifying service health..." -ForegroundColor Yellow
Start-Sleep -Seconds 2

$healthUrl = "http://localhost:${HostPort}/healthz"
try {
    $healthResp = Invoke-RestMethod -Uri$healthUrl -Method Get -TimeoutSec 5
    if ($healthResp.status -ne "healthy") {
        throw "Service returned unexpected status: $($healthResp.status)"
    }
    Write-Host "==> Service is healthy." -ForegroundColor Green
}
catch {
    Write-Host "ERROR: Health check failed at $healthUrl" -ForegroundColor Red
    docker logs $ContainerName
    exit 1
}

# Step 6: Execute curl / HTTP integration tests with payloads and assertions
Write-Host "==> Running endpoint payload verification..." -ForegroundColor Yellow

function Assert-Endpoint {
    param(
        [string]$Endpoint,
        [string]$Payload,
        [string]$Expected
    )

    $targetUrl = "http://localhost:${HostPort}${Endpoint}"
    try {
        # Raw string extraction to accurately compare formatted decimals and ints
        $rawResponse = Invoke-WebRequest -Uri$targetUrl `
            -Method Post `
            -ContentType "application/json" `
            -Body $Payload `
            -UseBasicParsing

        $actual =$rawResponse.Content.Trim()

        if ($actual -eq$Expected) {
            Write-Host "  [PASS] POST $Endpoint with $Payload ->$actual" -ForegroundColor Green
        }
        else {
            Write-Host "  [FAIL] POST $Endpoint with$Payload -> Got '$actual', expected '$Expected'" -ForegroundColor Red
            exit 1
        }
    }
    catch {
        Write-Host "  [FAIL] Request failed on POST $Endpoint with payload$Payload" -ForegroundColor Red
        Write-Host "  Error: $_" -ForegroundColor Red
        exit 1
    }
}

# Required assignment test vectors
Assert-Endpoint -Endpoint "/mean" -Payload '[1,2,3,4,5]' -Expected "3"
Assert-Endpoint -Endpoint "/mean" -Payload '[1.5,3,1,7,4.2]' -Expected "3.34"
Assert-Endpoint -Endpoint "/stddev" -Payload '[1,2,3,4,5]' -Expected "1.414"
Assert-Endpoint -Endpoint "/stddev" -Payload '[1.5,3,1,7,4.2]' -Expected "2.15"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host " All tests passed! Application is live at http://localhost:$HostPort" -ForegroundColor Green