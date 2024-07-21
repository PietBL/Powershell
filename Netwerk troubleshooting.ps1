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
        [string]$message
    )
    $message | Out-File -FilePath $reportFile -Append
    $message
}

# Generate WLAN report
Write-Report "Generating WLAN report..."
netsh wlan show wlanreport
$wlanReportSource = "C:\ProgramData\Microsoft\Windows\WlanReport\wlan-report-latest.html"
$wlanReportDestination = "$reportPath\WlanReport_$timestamp.html"
if (Test-Path $wlanReportSource) {
    Copy-Item -Path $wlanReportSource -Destination $wlanReportDestination -Force
    Write-Report "WLAN report generated: $wlanReportDestination"
} else {
    Write-Report "Failed to generate WLAN report."
}

# Check network adapter status
Write-Report "`nChecking network adapter status..."
Get-NetAdapter | Format-List | Out-String | Write-Report

# Check IP configuration
Write-Report "`nChecking IP configuration..."
Get-NetIPAddress | Format-List | Out-String | Write-Report

# Check DNS client configuration
Write-Report "`nChecking DNS client configuration..."
Get-DnsClient | Format-List | Out-String | Write-Report

# Ping common endpoints
$endpoints = @("8.8.8.8", "1.1.1.1", "google.com", "bing.com")
foreach ($endpoint in $endpoints) {
    Write-Report "`nPinging $endpoint..."
    Test-Connection -ComputerName $endpoint -Count 4 | Format-Table -AutoSize | Out-String | Write-Report
}

# Check DNS resolution
$dnsNames = @("google.com", "bing.com")
foreach ($dnsName in $dnsNames) {
    Write-Report "`nResolving DNS for $dnsName..."
    Resolve-DnsName -Name $dnsName | Format-Table -AutoSize | Out-String | Write-Report
}

# Traceroute to common endpoints
foreach ($endpoint in $endpoints) {
    Write-Report "`nTraceroute to $endpoint..."
    Test-NetConnection -ComputerName $endpoint -TraceRoute | Format-List | Out-String | Write-Report
}

# Check current network connections
Write-Report "`nChecking current network connections..."
Get-NetTCPConnection | Format-Table -AutoSize | Out-String | Write-Report

# Check routing table
Write-Report "`nChecking routing table..."
Get-NetRoute | Format-Table -AutoSize | Out-String | Write-Report

# Output the location of the report
Write-Report "`nNetwork diagnostics completed. Report saved to $reportFile"

# Optionally open the report in the default text editor
Start-Process notepad.exe $reportFile
