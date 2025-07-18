# Install all packages (old versions)
choco install googlechrome -y
choco install powerbi --version=2.141.1754.0 -y
choco install sql-server-management-studio --version=20.1.10 -y

# otherwise, install the standard versions with
choco install googlechrome -y
choco install powerbi -y
choco install sql-server-management-studio -y

choco list

param(
    [string]$AppList = "",
    [string]$ImageBuilderName = ""
)

Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

# Determine if current instance is an image within a fleet or an imagebuilder.
# We don't want to run this script if its in a fleet!
# Details: https://docs.aws.amazon.com/appstream2/latest/developerguide/user-instance-metadata-image-builders.html
$ResourceType = $Env:AppStream_Resource_Type

if ($ResourceType -eq "fleet") {
    # Do nothing
} else {
    $appsToUpdate = @()

    if ($AppList -ne "") {
        $apps = $AppList.Split(",")
        foreach ($app in $apps) {
            $app = $app.Trim()
            switch ($app.ToLower()) {
                "chrome" { $appsToUpdate += "googlechrome" }
                "powerbi" { $appsToUpdate += "powerbi" }
                "ssms" { $appsToUpdate += "sql-server-management-studio" }
                default { Write-Host " Unknown application alias specified: $app. Skipping." }
            }
        }
    } else {
        $appsToUpdate = "googlechrome", "powerbi", "sql-server-management-studio"
        Write-Host "No specific applications provided. Updating default applications: $($appsToUpdate -join ', ')."
    }

    if ($appsToUpdate.Count -eq 0) {
        Write-Host "No valid applications to update. Exiting."
        exit 0
    }

    Write-Host "`n--- Proceeding with application updates using Chocolatey ---"

    foreach ($packageId in $appsToUpdate) {
        Write-Host "`n--- Attempting to upgrade package: $packageId ---"
        try {
            choco upgrade $packageId --yes --ignore-checksums
            if ($LASTEXITCODE -eq 0) {
                Write-Host " Successfully processed $packageId."
            } else {
                Write-Warning " Chocolatey returned exit code $LASTEXITCODE for $packageId."
            }
        } catch {
            Write-Error "❌ Error while updating ${packageId}: $($_.Exception.Message)"
        }
    }

    Write-Host "`n✅ All specified applications processed."

    # --- Wait a bit before shutdown (optional, 2 min) ---
    Write-Host "Waiting 120 seconds to allow background processes to settle..."
    Start-Sleep -Seconds 120

    # --- Stop the Image Builder or Shutdown ---
    if ($ImageBuilderName -ne "") {
        try {
            Write-Host "`n--- Stopping AppStream Image Builder: $ImageBuilderName ---"
            aws appstream stop-image-builder --name $ImageBuilderName
            if ($LASTEXITCODE -eq 0) {
                Write-Host "Successfully sent stop request for $ImageBuilderName."
            } else {
                Write-Warning "⚠ AWS CLI returned exit code $LASTEXITCODE while stopping the image builder."
            }
        } catch {
            Write-Error "Failed to stop AppStream Image Builder: $($_.Exception.Message)"
        }
    } else {
        Write-Host "`n--- No ImageBuilderName provided. Shutting down this instance directly. ---"
        Stop-Computer -Force
    }

    Write-Host "`nAll tasks completed. The Image Builder will stop after shutdown."
}

# Define the path to your application update script
$scriptPath = "C:\Scripts\AppStream-AppUpdate.ps1"
$logPath = "C:\Logs\ApplicationUpdate.log" # For logging the script's output

# Ensure the directory for your script and logs exists
# In an AppStream Image Builder, you might use User Data to place these files and create directories
if (-not (Test-Path (Split-Path $scriptPath))) {
    New-Item -ItemType Directory -Path (Split-Path $scriptPath) -Force
}
if (-not (Test-Path (Split-Path $logPath))) {
    New-Item -ItemType Directory -Path (Split-Path $logPath) -Force
}

# --- 1. Define the Action ---
$action = New-ScheduledTaskAction -Execute "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`" -WindowStyle Hidden -ErrorAction Stop >> `"$logPath`" 2>&1"

# --- 2. Define the Trigger ---
$trigger = New-ScheduledTaskTrigger -AtStartup

# --- 3. Define the Principal (Security Context) ---
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

# --- 4. Define the Settings ---
$settings = New-ScheduledTaskSettingsSet `
    -ExecutionTimeLimit (New-TimeSpan -Hours 1) `
    -StartWhenAvailable `
    -MultipleInstances IgnoreNew

# --- 5. Create the Task Object ---
$taskName = "AppStreamAppUpdater"
$taskDescription = "Updates applications on AppStream 2.0 Image Builder startup."

$task = New-ScheduledTask `
    -Action $action `
    -Trigger $trigger `
    -Principal $principal `
    -Settings $settings `
    -Description $taskDescription

# --- 6. Register the Task ---
# This registers the task with the Task Scheduler service.
Register-ScheduledTask -TaskName $taskName -InputObject $task

Write-Host "Scheduled task '$taskName' created successfully."
Write-Host "The task will run '$scriptPath' on system startup."
Write-Host "Output will be logged to '$logPath'."

# --- Optional: Verification ---
Get-ScheduledTask -TaskName $taskName | Select-Object TaskName,State,Triggers,Actions,Principal
Get-ScheduledTaskInfo -TaskName $taskName

image-assistant.exe add-application --name Chrome `
    --display-name Chrome `
    --absolute-app-path "C:\Program Files\Google\Chrome\Application\chrome.exe"; `
image-assistant.exe add-application --name PowerBIDesktop `
    --display-name PowerBIDesktop `
    --absolute-app-path "C:\Program Files\Microsoft Power BI Desktop\bin\PBIDesktop.exe"; `
image-assistant.exe add-application --name SQLServerManagementStudio `
    --display-name SQLServerManagementStudio `
    --absolute-app-path "C:\Program Files (x86)\Microsoft SQL Server Management Studio 20\Common7\IDE\Ssms.exe"