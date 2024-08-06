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

# Get all processes with "vmware-vmx" in the name
$vmwareProcesses = Get-Process | Where-Object { $_.ProcessName -like "*vmware-vmx*" }

# Get the current user that has just logged in
$currentUser = (Get-WmiObject -Class Win32_ComputerSystem).UserName
Write-Log "Current User: $currentUser"

# Get the user that started each process and additional details
foreach ($process in $vmwareProcesses) {
    try {
        $processDetails = Get-WmiObject Win32_Process -Filter "ProcessId = $($process.Id)"
        $processOwner = $processDetails.GetOwner()
        $cpuUsage = $process.CPU
        $memoryUsage = $process.WorkingSet64 / 1MB
        $privateMemorySize = $process.PrivateMemorySize64 / 1MB
        $processUser = "$($processOwner.Domain)\$($processOwner.User)"
        
        Write-Log "Process: $($process.ProcessName) | PID: $($process.Id) | User: $processUser | CPU: $cpuUsage | Memory: $([math]::Round($memoryUsage, 2)) MB | Private Memory: $([math]::Round($privateMemorySize, 2)) MB"
        
        if ($currentUser -ne $processUser) {
            Write-Log "Different user: $($process.ProcessName) | PID: $($process.Id)"
            try {
                Stop-Process -Id $process.Id -Force
                Write-Log "Process killed: $($process.ProcessName) | PID: $($process.Id)"
            } catch {
                Write-Log "Failed to kill process: $($process.ProcessName) | PID: $($process.Id)"
            }
        }
    } catch {
        Write-Log "Could not retrieve details for process: $($process.ProcessName) | PID: $($process.Id)"
    }
}
