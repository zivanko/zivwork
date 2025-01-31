# התחברות לחשבון Azure באמצעות Device Authentication
Connect-AzAccount -UseDeviceAuthentication

# קבלת כל המכונות הווירטואליות בסאבסקריפשן
$vms = Get-AzVM

# כיבוי כל המכונות הווירטואליות
foreach ($vm in $vms) {
    Write-Host "Stopping VM: $($vm.Name)"
    Stop-AzVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name -Force
}

Write-Host "All VMs in the subscription have been stopped successfully."
