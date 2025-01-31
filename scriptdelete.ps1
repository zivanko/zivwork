# Connect to Azure with device authentication
Connect-AzAccount -UseDeviceAuthentication

# Function to delete all resources in a resource group
function Delete-ResourcesInResourceGroup {
    param(
        [string]$rgName
    )

    try {
        Write-Host "Deleting resources in resource group: $rgName"

        # Get all resources in the resource group
        $resources = Get-AzResource -ResourceGroupName $rgName

        # Loop to delete resources in the correct order (VM -> NIC -> Public IP -> NSG)
        foreach ($resource in $resources) {
            # Delete the VM first
            if ($resource.Type -eq "Microsoft.Compute/virtualMachines") {
                try {
                    Write-Host "Deleting Virtual Machine: $($resource.Name)"
                    Remove-AzResource -ResourceId $resource.ResourceId -Force
                    Write-Host "Virtual Machine $($resource.Name) deleted successfully."
                }
                catch {
                    Write-Host "Error deleting VM $($resource.Name): $($_)"
                }
            }
        }

        foreach ($resource in $resources) {
            # Delete the NIC second
            if ($resource.Type -eq "Microsoft.Network/networkInterfaces") {
                try {
                    Write-Host "Deleting Network Interface: $($resource.Name)"
                    Remove-AzResource -ResourceId $resource.ResourceId -Force
                    Write-Host "Network Interface $($resource.Name) deleted successfully."
                }
                catch {
                    Write-Host "Error deleting NIC $($resource.Name): $($_)"
                }
            }
        }

        foreach ($resource in $resources) {
            # Delete the Public IP third
            if ($resource.Type -eq "Microsoft.Network/publicIPAddresses") {
                try {
                    Write-Host "Deleting Public IP: $($resource.Name)"
                    Remove-AzResource -ResourceId $resource.ResourceId -Force
                    Write-Host "Public IP $($resource.Name) deleted successfully."
                }
                catch {
                    Write-Host "Error deleting Public IP $($resource.Name): $($_)"
                }
            }
        }

        foreach ($resource in $resources) {
            # Delete the NSG fourth
            if ($resource.Type -eq "Microsoft.Network/networkSecurityGroups") {
                try {
                    Write-Host "Deleting Network Security Group: $($resource.Name)"
                    Remove-AzResource -ResourceId $resource.ResourceId -Force
                    Write-Host "Network Security Group $($resource.Name) deleted successfully."
                }
                catch {
                    Write-Host "Error deleting NSG $($resource.Name): $($_)"
                }
            }
        }

        # Finally, delete the resource group itself
        Write-Host "Deleting the resource group $rgName"
        Remove-AzResourceGroup -Name $rgName -Force -AsJob
        Write-Host "Resource group $rgName deleted successfully."
    }
    catch {
        Write-Host "Error deleting resources in resource group $($rgName): $($_)"
    }
}

# Get all resource groups in the account
$resourceGroups = Get-AzResourceGroup

# Loop through each resource group and delete its resources
foreach ($rg in $resourceGroups) {
    # Delete all resources in the current resource group
    Delete-ResourcesInResourceGroup -rgName $rg.ResourceGroupName
}
