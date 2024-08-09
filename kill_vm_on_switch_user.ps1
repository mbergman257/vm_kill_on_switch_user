# Define the log file path
$logFilePath = "C:\Users\Public\automate\log_killvm.txt"

# Create the directory if it doesn't exist
$logDirectory = [System.IO.Path]::GetDirectoryName($logFilePath)
if (-not (Test-Path -Path $logDirectory)) {
    New-Item -Path $logDirectory -ItemType Directory | Out-Null
}

# Create the log file if it doesn't exist
if (-not (Test-Path -Path $logFilePath)) {
    New-Item -Path $logFilePath -ItemType File | Out-Null
}

# Function to write output to the log file with a timestamp
function Write-Log {
    param (
        [string]$message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp - $message"
    Add-Content -Path $logFilePath -Value $logMessage
}

# Get all processes with "VirtualBoxVM" in the name, and sort list to kill largest Memory first
$processes = Get-Process | Where-Object { $_.ProcessName -like "*VirtualBoxVM*" } | Sort-Object -Property  PrivateMemorySize

# Get the current user that has just logged in
$currentUser = (Get-WmiObject -Class Win32_ComputerSystem).UserName
Write-Log "Current User: $currentUser"

# Get the user that started each process and additional details
foreach ($process in $processes) {
    try {
        $processDetails = Get-WmiObject Win32_Process -Filter "ProcessId = $($process.Id)"
        $processOwner = $processDetails.GetOwner()
        $cpuUsage = $process.CPU
        $memoryUsage = $process.WorkingSet64 / 1MB
        $privateMemorySize = $process.PrivateMemorySize64 / 1MB
        $processUser = "$($processOwner.Domain)\$($processOwner.User)"
        
        Write-Log "Process: $($process.ProcessName) | PID: $($process.Id) | User: $processUser | CPU: $cpuUsage | Memory: $([math]::Round($memoryUsage, 2)) MB | Private Memory: $([math]::Round($privateMemorySize, 2)) MB"

        # Kill if the process was started by a different user
        if ($currentUser -ne $processUser) {
            Write-Log "`tDifferent user: $($process.ProcessName) | PID: $($process.Id)"
            try {
                Stop-Process -Id $process.Id -Force
                Write-Log "`tProcess killed: $($process.ProcessName) | PID: $($process.Id)"
            } catch {
                Write-Log "`tFailed to kill process: $($process.ProcessName) | PID: $($process.Id)"
            }
        }
    } catch {
        Write-Log "Could not retrieve details for process: $($process.ProcessName) | PID: $($process.Id)"
    }
}
# Add line for formatting
Add-Content -Path $logFilePath -Value ""
