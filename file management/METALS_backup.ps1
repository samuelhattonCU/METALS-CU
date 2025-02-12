# Set process name
$Host.UI.RawUI.WindowTitle = "METALS Backup"

# Define source and destination directories
$SOURCE_DIR = "F:\DATA\METALS"
$DEST1 = "H:\DATA\METALS"
$DEST2 = "G:\DATA\METALS"

# Create log file name with date
$LOG_DATE = Get-Date -Format "MM-dd-yyyy_HH-mm-ss"
$LOG_FILE = "C:\METALS Utilities\METALS LOG\backup logs\backup_$LOG_DATE.log"

# Create log directory if it doesn't exist
New-Item -ItemType Directory -Force -Path (Split-Path $LOG_FILE -Parent)

# Write start time
$startTime = Get-Date
"Backup started at $startTime" | Tee-Object -FilePath $LOG_FILE

function Sync-Directory {
    param($source, $dest, $logFile)
    
    Write-Host "Copying $source to $dest..."
    Add-Content -Path $logFile -Value "Copying $source to $dest..."
    
    # Robocopy parameters:
    # /MIR - Mirror mode
    # /MT:32 - 32 threads
    # /Z - Restart mode
    # /W:1 - Wait time between retries
    # /R:3 - Number of retries
    # /TEE - Output to console and log file
    # /NP - No progress percentage
    # /NDL - No directory list
    
    $result = robocopy $source $dest /MIR /MT:32 /Z /W:1 /R:3 /TEE /NP /NDL /LOG+:$logFile
    
    if ($LASTEXITCODE -ge 8) {
        Write-Error "Error copying files from $source to $dest"
        Add-Content -Path $logFile -Value "Error copying files from $source to $dest"
    }
    else {
        Write-Host "Successfully copied files from $source to $dest"
        Add-Content -Path $logFile -Value "Successfully copied files from $source to $dest"
    }
}

# Main backup process
try {
    Sync-Directory -source $SOURCE_DIR -dest $DEST1 -logFile $LOG_FILE
    Sync-Directory -source $SOURCE_DIR -dest $DEST2 -logFile $LOG_FILE
    
    "Backup completed at $(Get-Date)" | Tee-Object -FilePath $LOG_FILE -Append
}
catch {
    $errorMessage = $_.Exception.Message
    "Error: $errorMessage" | Tee-Object -FilePath $LOG_FILE -Append
}

Read-Host -Prompt "Press Enter to exit"