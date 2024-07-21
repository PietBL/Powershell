param (
    [string]$reportPath = "C:\Reports\NetworkDiagnostics"
)

if (-not (Test-Path $reportPath)) {
    New-Item -ItemType Directory -Path $reportPath
}

$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$reportFile = "$reportPath\NetworkDiagnostics_$timestamp.txt"

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

function Execute-Command {
    param (
        [scriptblock]$command,
        [string]$description
    )
    Write-Report "$description"
    try {
        $result = & $command
        Write-Report "$result" "SUCCESS"
    } catch {
        Write-Report "$_" "FAILURE"
    }
}

Execute-Command { netsh wlan show wlanreport } "Generating WLAN report"
$wlanReportSource = "C:\ProgramData\Microsoft\Windows\WlanReport\wlan-report-latest.html"
$wlanReportDestination = "$reportPath\WlanReport_$timestamp.html"
if (Test-Path $wlanReportSource) {
    Copy-Item -Path $wlanReportSource -Destination $wlanReportDestination -Force
    Write-Report "WLAN report copied to $wlanReportDestination" "SUCCESS"
} else {
    Write-Report "WLAN report not found." "FAILURE"
}

Execute-Command { Get-NetAdapter | Format-List | Out-String } "Checking network adapter status"
Execute-Command { Get-NetIPAddress | Format-List | Out-String } "Checking IP configuration"
Execute-Command { Get-DnsClient | Format-List | Out-String } "Checking DNS client configuration"

$endpoints = @("8.8.8.8", "1.1.1.1", "google.com", "bing.com")
foreach ($endpoint in $endpoints) {
    Execute-Command { Test-Connection -ComputerName $endpoint -Count 4 | Format-Table -AutoSize | Out-String } "Pinging $endpoint"
}

$dnsNames = @("google.com", "bing.com")
foreach ($dnsName in $dnsNames) {
    Execute-Command { Resolve-DnsName -Name $dnsName | Format-Table -AutoSize | Out-String } "Resolving DNS for $dnsName"
}

foreach ($endpoint in $endpoints) {
    Execute-Command { Test-NetConnection -ComputerName $endpoint -TraceRoute | Format-List | Out-String } "Traceroute to $endpoint"
}

Execute-Command { Get-NetTCPConnection | Format-Table -AutoSize | Out-String } "Checking current network connections"
Execute-Command { Get-NetRoute | Format-Table -AutoSize | Out-String } "Checking routing table"
Execute-Command { netsh wlan show interfaces | Select-String 'Signal' | Out-String } "Checking Wi-Fi signal strength"
Execute-Command { Get-NetAdapter | Select-Object Name, DriverVersion | Format-Table -AutoSize | Out-String } "Checking driver versions"
Execute-Command { Get-NetAdapter | Where-Object {$_.Name -like "*Ethernet*"} | Select-Object Name, Status | Format-Table -AutoSize | Out-String } "Checking Ethernet connectivity"
Execute-Command { netstat -an | Out-String } "Checking active network connections"
Execute-Command { Get-NetFirewallProfile | Format-Table -AutoSize | Out-String } "Checking Windows Firewall status"
Execute-Command { Get-NetAdapterStatistics | Format-Table -AutoSize | Out-String } "Checking network interface errors"
Execute-Command { Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" | Select-Object -Property ProxyServer, ProxyEnable | Format-Table -AutoSize | Out-String } "Verifying proxy settings"
Execute-Command { Invoke-WebRequest -Uri "http://www.google.com" -UseBasicParsing | Out-String } "Testing HTTP connectivity"
Execute-Command { Get-WindowsUpdateLog | Out-String } "Checking for system updates"
Execute-Command { Get-WinEvent -LogName System | Where-Object {$_.Message -like "*network*"} | Format-Table -AutoSize | Out-String } "Checking Windows Event Logs for network-related errors"

$networkShares = @("\\server\share1", "\\server\share2")
foreach ($share in $networkShares) {
    Execute-Command { Test-Path $share | Out-String } "Checking access to $share"
}

Write-Report "Network diagnostics completed. Report saved to $reportFile" "INFO"
Start-Process notepad.exe $reportFile
