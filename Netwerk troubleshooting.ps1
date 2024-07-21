param (
    [string]$reportPath = "C:\Reports\NetworkDiagnostics"
)

# Create the report directory if it doesn't exist
if (-not (Test-Path $reportPath)) {
    New-Item -ItemType Directory -Path $reportPath
}

# Timestamp for the report
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$reportFile = "$reportPath\NetworkDiagnostics_$timestamp.txt"

# Function to write to the report file
function Write-Report {
    param (
        [string]$message,
        [string]$status = "INFO"
    )
    $logMessage = "[$status] $message"
    $logMessage | Out-File -FilePath $reportFile -Append
    Write-Host $logMessage
}

# Function to execute a command and capture success or failure
function Execute-Command {
    param (
        [scriptblock]$command,
        [string]$description
    )
    Write-Report "$description..."
    try {
        & $command
        Write-Report "$description succeeded." "SUCCESS"
    } catch {
        Write-Report "$description failed. $_" "FAILURE"
    }
}

# Generate WLAN report
Execute-Command { netsh wlan show wlanreport } "Generating WLAN report"
$wlanReportSource = "C:\ProgramData\Microsoft\Windows\WlanReport\wlan-report-latest.html"
$wlanReportDestination = "$reportPath\WlanReport_$timestamp.html"
if (Test-Path $wlanReportSource) {
    Copy-Item -Path $wlanReportSource -Destination $wlanReportDestination -Force
    Write-Report "WLAN report copied to $wlanReportDestination" "SUCCESS"
} else {
    Write-Report "WLAN report not found." "FAILURE"
}

# Check network adapter status
Execute-Command { Get-NetAdapter | Format-List | Out-String | Write-Report } "Checking network adapter status"

# Check IP configuration
Execute-Command { Get-NetIPAddress | Format-List | Out-String | Write-Report } "Checking IP configuration"

# Check DNS client configuration
Execute-Command { Get-DnsClient | Format-List | Out-String | Write-Report } "Checking DNS client configuration"

# Ping common endpoints
$endpoints = @("8.8.8.8", "1.1.1.1", "google.com", "bing.com")
foreach ($endpoint in $endpoints) {
    Execute-Command { Test-Connection -ComputerName $endpoint -Count 4 | Format-Table -AutoSize | Out-String | Write-Report } "Pinging $endpoint"
}

# Check DNS resolution
$dnsNames = @("google.com", "bing.com")
foreach ($dnsName in $dnsNames) {
    Execute-Command { Resolve-DnsName -Name $dnsName | Format-Table -AutoSize | Out-String | Write-Report } "Resolving DNS for $dnsName"
}

# Traceroute to common endpoints
foreach ($endpoint in $endpoints) {
    Execute-Command { Test-NetConnection -ComputerName $endpoint -TraceRoute | Format-List | Out-String | Write-Report } "Traceroute to $endpoint"
}

# Check current network connections
Execute-Command { Get-NetTCPConnection | Format-Table -AutoSize | Out-String | Write-Report } "Checking current network connections"

# Check routing table
Execute-Command { Get-NetRoute | Format-Table -AutoSize | Out-String | Write-Report } "Checking routing table"

# Output the location of the report
Write-Report "Network diagnostics completed. Report saved to $reportFile" "INFO"

# Optionally open the report in the default text editor
Start-Process notepad.exe $reportFile
