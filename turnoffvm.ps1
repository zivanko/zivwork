# ������� ������ Azure ������� Device Authentication
Connect-AzAccount -UseDeviceAuthentication

# ���� �� ������� ������������ �����������
$vms = Get-AzVM

# ����� �� ������� ������������
foreach ($vm in $vms) {
    Write-Host "Stopping VM: $($vm.Name)"
    Stop-AzVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name -Force
}

Write-Host "All VMs in the subscription have been stopped successfully."
