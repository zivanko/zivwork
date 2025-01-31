# ����� ��� ������
$LogPath = "C:\Logs\ServerInstallation.log"
$Date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# ������� ������ ���
function Write-InstallLog {
    param($Message)
    $LogMessage = "[$Date] $Message"
    Write-Host $LogMessage
    Add-Content -Path $LogPath -Value $LogMessage
}

# ����� ������ ��� �� �� �����
if (!(Test-Path "C:\Logs")) {
    New-Item -ItemType Directory -Path "C:\Logs" -Force
}

Write-InstallLog "����� ����� IIS �-DHCP..."

# ����� IIS �� ������ ������
try {
    Write-InstallLog "����� IIS..."
    Install-WindowsFeature -Name Web-Server, Web-Common-Http, Web-Default-Doc, Web-Dir-Browsing, Web-Http-Errors, Web-Static-Content, Web-Http-Logging, Web-Stat-Compression, Web-Filtering, Web-Mgmt-Console, Web-Mgmt-Tools -IncludeManagementTools
    Write-InstallLog "����� IIS ������ ������"
} catch {
    Write-InstallLog "����� ������ IIS: $_"
}

# ����� DHCP Server
try {
    Write-InstallLog "����� ��� DHCP..."
    Install-WindowsFeature -Name DHCP -IncludeManagementTools
    Write-InstallLog "����� DHCP ������ ������"
} catch {
    Write-InstallLog "����� ������ DHCP: $_"
}

Write-InstallLog "����� IIS �-DHCP ������"
