# הגדרת לוג להתקנה
$LogPath = "C:\Logs\ServerInstallation.log"
$Date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# פונקציה לכתיבת לוג
function Write-InstallLog {
    param($Message)
    $LogMessage = "[$Date] $Message"
    Write-Host $LogMessage
    Add-Content -Path $LogPath -Value $LogMessage
}

# יצירת תיקיית לוג אם לא קיימת
if (!(Test-Path "C:\Logs")) {
    New-Item -ItemType Directory -Path "C:\Logs" -Force
}

Write-InstallLog "מתחיל התקנת IIS ו-DHCP..."

# התקנת IIS עם תכונות נפוצות
try {
    Write-InstallLog "מתקין IIS..."
    Install-WindowsFeature -Name Web-Server, Web-Common-Http, Web-Default-Doc, Web-Dir-Browsing, Web-Http-Errors, Web-Static-Content, Web-Http-Logging, Web-Stat-Compression, Web-Filtering, Web-Mgmt-Console, Web-Mgmt-Tools -IncludeManagementTools
    Write-InstallLog "התקנת IIS הושלמה בהצלחה"
} catch {
    Write-InstallLog "שגיאה בהתקנת IIS: $_"
}

# התקנת DHCP Server
try {
    Write-InstallLog "מתקין שרת DHCP..."
    Install-WindowsFeature -Name DHCP -IncludeManagementTools
    Write-InstallLog "התקנת DHCP הושלמה בהצלחה"
} catch {
    Write-InstallLog "שגיאה בהתקנת DHCP: $_"
}

Write-InstallLog "התקנת IIS ו-DHCP הושלמו"
