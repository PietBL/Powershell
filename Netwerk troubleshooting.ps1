param (
    [string]$reportPath = "C:\Reports\NetworkDiagnostics"
)

# Create the main report directory if it doesn't exist
if (-not (Test-Path $reportPath)) {
    New-Item -ItemType Directory -Path $reportPath
}

# Create a subdirectory for individual command output files
$commandsPath = "$reportPath\Commands"
if (-not (Test-Path $commandsPath)) {
    New-Item -ItemType Directory -Path $commandsPath
}

# Timestamp for the report
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$reportFile = "$reportPath\NetworkDiagnostics_$timestamp.txt"

# Function to write to the main report file
function Write-Report {
    param (
        [string]$message,
        [string]$status = "INFO"
    )
    $statusMessage = if ($status -eq "SUCCESS") { "Succeeded" } elseif ($status -eq "FAILURE") { "Failed" } else { $status }
    $logMessage = "$message`n$statusMessage`n"
    $logMessage | Out-File -FilePath $reportFile -Append
    Write-Host $logMessage
}

# Function to execute a command and capture success or failure
function Execute-Command {
    param (
        [scriptblock]$command,
        [string]$description,
        [string]$outputFileName
    )
    Write-Report "$description"
    $outputFilePath = "$commandsPath\$outputFileName.txt"
    try {
        $result = & $command
        $result | Out-File -FilePath $outputFilePath
        Write-Report "$description output saved to $outputFilePath" "SUCCESS"
    } catch {
        Write-Report "$description failed. $_" "FAILURE"
    }
}

Execute-Command { netsh wlan show wlanreport } "Generating WLAN report" "WLAN_Report"
$wlanReportSource = "C:\ProgramData\Microsoft\Windows\WlanReport\wlan-report-latest.html"
$wlanReportDestination = "$reportPath\WlanReport_$timestamp.html"
if (Test-Path $wlanReportSource) {
    Copy-Item -Path $wlanReportSource -Destination $wlanReportDestination -Force
    Write-Report "WLAN report copied to $wlanReportDestination" "SUCCESS"
} else {
    Write-Report "WLAN report not found." "FAILURE"
}

Execute-Command { Get-NetAdapter | Format-List | Out-String } "Checking network adapter status" "Network_Adapter_Status"
Execute-Command { Get-NetIPAddress | Format-List | Out-String } "Checking IP configuration" "IP_Configuration"
Execute-Command { Get-DnsClient | Format-List | Out-String } "Checking DNS client configuration" "DNS_Client_Configuration"

$endpoints = @("8.8.8.8", "1.1.1.1", "google.com", "bing.com")
foreach ($endpoint in $endpoints) {
    Execute-Command { Test-Connection -ComputerName $endpoint -Count 4 | Format-Table -AutoSize | Out-String } "Pinging $endpoint" "Ping_$($endpoint.Replace('.','_'))"
}

$dnsNames = @("google.com", "bing.com")
foreach ($dnsName in $dnsNames) {
    Execute-Command { Resolve-DnsName -Name $dnsName | Format-Table -AutoSize | Out-String } "Resolving DNS for $dnsName" "DNS_Resolve_$($dnsName.Replace('.','_'))"
}

foreach ($endpoint in $endpoints) {
    Execute-Command { Test-NetConnection -ComputerName $endpoint -TraceRoute | Format-List | Out-String } "Traceroute to $endpoint" "Traceroute_$($endpoint.Replace('.','_'))"
}

Execute-Command { Get-NetTCPConnection | Format-Table -AutoSize | Out-String } "Checking current network connections" "Network_Connections"
Execute-Command { Get-NetRoute | Format-Table -AutoSize | Out-String } "Checking routing table" "Routing_Table"
Execute-Command { netsh wlan show interfaces | Select-String 'Signal' | Out-String } "Checking Wi-Fi signal strength" "WiFi_Signal_Strength"
Execute-Command { Get-NetAdapter | Select-Object Name, DriverVersion | Format-Table -AutoSize | Out-String } "Checking driver versions" "Driver_Versions"
Execute-Command { Get-NetAdapter | Where-Object {$_.Name -like "*Ethernet*"} | Select-Object Name, Status | Format-Table -AutoSize | Out-String } "Checking Ethernet connectivity" "Ethernet_Connectivity"
Execute-Command { netstat -an | Out-String } "Checking active network connections" "Active_Network_Connections"
Execute-Command { Get-NetFirewallProfile | Format-Table -AutoSize | Out-String } "Checking Windows Firewall status" "Firewall_Status"
Execute-Command { Get-NetAdapterStatistics | Format-Table -AutoSize | Out-String } "Checking network interface errors" "Network_Interface_Errors"
Execute-Command { Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" | Select-Object -Property ProxyServer, ProxyEnable | Format-Table -AutoSize | Out-String } "Verifying proxy settings" "Proxy_Settings"
Execute-Command { Invoke-WebRequest -Uri "http://www.google.com" -UseBasicParsing | Out-String } "Testing HTTP connectivity" "HTTP_Connectivity"
Execute-Command { Get-WindowsUpdateLog | Out-String } "Checking for system updates" "System_Updates"
Execute-Command { Get-WinEvent -LogName System | Where-Object {$_.Message -like "*network*"} | Format-Table -AutoSize | Out-String } "Checking Windows Event Logs for network-related errors" "Event_Logs"

$networkShares = @("\\server\share1", "\\server\share2")
foreach ($share in $networkShares) {
    Execute-Command { Test-Path $share | Out-String } "Checking access to $share" "Network_Share_$($share.Replace('\\','_'))"
}

Write-Report "Network diagnostics completed. Report saved to $reportFile" "INFO"
Start-Process notepad.exe $reportFile
