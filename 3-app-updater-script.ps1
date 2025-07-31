# Step 1: Ensure the target directory exists
$folderPath = "C:\Scripts"
if (-not (Test-Path $folderPath)) {
    New-Item -Path $folderPath -ItemType Directory -Force | Out-Null
}

# Step 2: Define the full update script content using Chocolatey
$scriptContent = @'
param(
    [string]$AppList = "",
    [string]$ImageBuilderName = ""
)

# === Global Settings ===
$ErrorActionPreference = "Stop"
$logPath = "C:\Logs\ApplicationUpdate.log"

# Ensure the log folder exists
if (-not (Test-Path (Split-Path $logPath))) {
    New-Item -ItemType Directory -Path (Split-Path $logPath) -Force | Out-Null
}

Start-Transcript -Path $logPath -Append
Write-Host "$(Get-Date): Script started."

# === Wait for AppStream environment ===
$maxWait = 300  # max 5 minutes
$waited = 0
while (-not $Env:AppStream_Resource_Name -and $waited -lt $maxWait) {
    Write-Host "$(Get-Date): Waiting for AppStream_Resource_Name... ($waited sec)"
    Start-Sleep -Seconds 5
    $waited += 5
}
if ($Env:AppStream_Resource_Name) {
    Write-Host "$(Get-Date): AppStream_Resource_Name = $($Env:AppStream_Resource_Name)"
    Write-Host "$(Get-Date): AppStream_Resource_Type = $($Env:AppStream_Resource_Type)"
} else {
    Write-Warning "$(Get-Date): AppStream_Resource_Name never became available."
    Get-ChildItem Env: | Out-String | Write-Host
}

# === Use fallback if needed ===
if (-not $ImageBuilderName) {
    if ($Env:AppStream_Resource_Name) {
        $ImageBuilderName = $Env:AppStream_Resource_Name
        Write-Host "$(Get-Date): Using AppStream_Resource_Name as ImageBuilderName: $ImageBuilderName"
    } else {
        try {
            Write-Host "$(Get-Date): Attempting fallback via EC2 metadata..."
            $instanceId = Invoke-RestMethod -Uri http://169.254.169.254/latest/meta-data/instance-id
            Write-Host "$(Get-Date): EC2 Instance ID: $instanceId"

            $awsCli = "C:\Program Files\Amazon\AWSCLIV2\aws.exe"
            if (-not (Test-Path $awsCli)) { $awsCli = "aws" }

            $ImageBuilderName = & $awsCli appstream describe-image-builders `
                --query "ImageBuilders[?InstanceId=='$instanceId'].Name | [0]" `
                --region ap-southeast-2 `
                --output text

            if ($ImageBuilderName) {
                Write-Host "$(Get-Date): Found ImageBuilderName via AWS CLI: $ImageBuilderName"
            } else {
                Write-Warning "$(Get-Date): Could not determine ImageBuilderName via EC2 metadata or CLI."
            }
        } catch {
            Write-Error "$(Get-Date): Failed to resolve ImageBuilderName: $($_.Exception.Message)"
        }
    }
}

try {
    # === Exit if not an image builder ===
    if ($Env:AppStream_Resource_Type -eq "fleet") {
        Write-Host "$(Get-Date): Running in a fleet instance. Exiting script."
        Stop-Transcript
        exit 0
    }

    # --- Determine apps to update ---
    $appsToUpdate = @()
    if ($AppList -ne "") {
        $apps = $AppList.Split(",")
        foreach ($app in $apps) {
            $app = $app.Trim()
            switch ($app.ToLower()) {
                "chrome" { $appsToUpdate += "googlechrome" }
                "powerbi" { $appsToUpdate += "powerbi" }
                "ssms" { $appsToUpdate += "sql-server-management-studio" }
                default { Write-Warning "Unknown application alias specified: $app. Skipping." }
            }
        }
    } else {
        $appsToUpdate = "googlechrome", "powerbi", "sql-server-management-studio"
        Write-Host "$(Get-Date): No specific applications provided. Using default apps: $($appsToUpdate -join ', ')."
    }

    if ($appsToUpdate.Count -eq 0) {
        Write-Host "$(Get-Date): No valid applications to update. Exiting."
        Stop-Transcript
        exit 0
    }

    # --- Update apps with Chocolatey ---
    Write-Host "`n$(Get-Date): --- Proceeding with application updates ---"
    foreach ($packageId in $appsToUpdate) {
        Write-Host "$(Get-Date): Updating $packageId..."
        try {
            choco upgrade $packageId --yes --ignore-checksums
            if ($LASTEXITCODE -eq 0) {
                Write-Host "$(Get-Date): Successfully processed $packageId."
            } else {
                Write-Warning "$(Get-Date): Chocolatey returned exit code $LASTEXITCODE for $packageId."
            }
        } catch {
            Write-Error "$(Get-Date):  Error while updating ${packageId}: $($_.Exception.Message)"
        }
    }

    # --- Create AppStream Image using Image Assistant ---
    $timestamp = Get-Date -Format "yyyyMMdd-HHmm"
    $finalImageName = "AutoImage-$timestamp"

    Write-Host "$(Get-Date): Triggering image creation: $finalImageName"

    $imageAssistantPath = 'C:\Program Files\Amazon\Photon\ConsoleImageBuilder\image-assistant.exe'

    # --- Stop Image Builder or Shutdown ---
    if (Test-Path $imageAssistantPath) {
        try {
            $resultRaw = & $imageAssistantPath create-image --name $finalImageName
            Write-Host "$(Get-Date): Raw result from image-assistant.exe:"
            Write-Host $resultRaw

            try {
                $resultJson = $resultRaw | ConvertFrom-Json
                if ($resultJson.status -eq 0) {
                    Write-Host "$(Get-Date):  Image creation successfully triggered: $finalImageName"
                } else {
                    Write-Warning "$(Get-Date):  Image creation failed. Status: $($resultJson.status), Message: $($resultJson.message)"
                }
            } catch {
                Write-Warning "$(Get-Date):  Failed to parse result as JSON. Output:"
                Write-Host $resultRaw
            }
        } catch {
            Write-Error "$(Get-Date):  Failed to trigger image creation: $($_.Exception.Message)"
        }
    } else {
        Write-Warning "$(Get-Date):  Image Assistant executable not found at $imageAssistantPath"
    }
    Write-Host "$(Get-Date): Update + Image creation flow complete."
    Write-Host "$(Get-Date): You may shut down the instance after snapshotting starts."

    Write-Host "$(Get-Date): All tasks completed."
} catch {
    Write-Error "$(Get-Date):  Fatal error: $($_.Exception.Message)"
} finally {
    Stop-Transcript
}
'@

# Step 3: Write to file
Set-Content -Path "C:\Scripts\AppStream-AppUpdate.ps1" -Value $scriptContent -Encoding UTF8 -Force

Write-Host "✅ Script written to C:\Scripts\AppStream-AppUpdate.ps1"

& "C:\Scripts\AppStream-AppUpdate.ps1"