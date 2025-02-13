# Azure Resource Management Script

# Function to show menu and get user choice
function Show-Menu {
    param (
        [string]$Title,
        [array]$Options
    )
    Write-Host "`n$Title"
    for ($i = 0; $i -lt $Options.Count; $i++) {
        Write-Host "$($i+1): $($Options[$i])"
    }
    do {
        $selection = Read-Host "Enter your choice (1-$($Options.Count))"
        $index = [int]$selection - 1
        if ($index -lt 0 -or $index -ge $Options.Count) {
            Write-Host "Invalid selection. Please choose a number between 1 and $($Options.Count)"
            continue
        }
        return $index
    } while ($true)
}

# Function to create a new resource group
function New-ResourceGroupWithLocation {
    $rgName = Read-Host "Enter Resource Group name"
    $locationIndex = Show-Menu -Title "Select location for Resource Group:" -Options $locations
    $rg = New-AzResourceGroup -Name $rgName -Location $locations[$locationIndex]
    return $rg
}

# Popular Azure locations
$locations = @(
    "eastus",
    "westus2",
    "northeurope",
    "westeurope",
    "southeastasia",
    "australiaeast"
)

# VM Sizes
$vmSizes = @(
    @{
        Name = "Standard_B2s (Budget)";
        Description = "2 vCPU, 4 GB RAM, 8 GB Temporary Storage - Economic burstable compute";
        Size = "Standard_B2s"
    },
    @{
        Name = "Standard_D2s_v3 (General Purpose)";
        Description = "2 vCPU, 8 GB RAM, 16 GB Temporary Storage - Balanced CPU to memory ratio";
        Size = "Standard_D2s_v3"
    },
    @{
        Name = "Standard_D4s_v3 (General Purpose+)";
        Description = "4 vCPU, 16 GB RAM, 32 GB Temporary Storage - Enhanced general purpose";
        Size = "Standard_D4s_v3"
    },
    @{
        Name = "Standard_E2s_v3 (Memory Optimized)";
        Description = "2 vCPU, 16 GB RAM, 32 GB Temporary Storage - High memory per CPU";
        Size = "Standard_E2s_v3"
    },
    @{
        Name = "Standard_E4s_v3 (Memory Optimized+)";
        Description = "4 vCPU, 32 GB RAM, 64 GB Temporary Storage - Enhanced memory performance";
        Size = "Standard_E4s_v3"
    },
    @{
        Name = "Standard_F2s_v2 (Compute Optimized)";
        Description = "2 vCPU, 4 GB RAM, 16 GB Temporary Storage - High CPU to memory ratio";
        Size = "Standard_F2s_v2"
    },
    @{
        Name = "Standard_F4s_v2 (Compute Optimized+)";
        Description = "4 vCPU, 8 GB RAM, 32 GB Temporary Storage - Enhanced compute performance";
        Size = "Standard_F4s_v2"
    },
    @{
        Name = "Standard_DS2_v2 (Balanced SSD)";
        Description = "2 vCPU, 7 GB RAM, 14 GB Temporary Storage - Premium storage capable";
        Size = "Standard_DS2_v2"
    },
    @{
        Name = "Standard_D8s_v3 (Large Scale)";
        Description = "8 vCPU, 32 GB RAM, 64 GB Temporary Storage - High performance computing";
        Size = "Standard_D8s_v3"
    },
    @{
        Name = "Standard_E8s_v3 (Large Memory)";
        Description = "8 vCPU, 64 GB RAM, 128 GB Temporary Storage - Memory intensive workloads";
        Size = "Standard_E8s_v3"
    }
)

# Operating System options
$osOptions = @(
    "Windows 10",
    "Windows 11",
    "Windows Server 2019",
    "Windows Server 2022",
    "Debian 12"
)

# NSG default and optional ports
$defaultPorts = @(
    @{Name="RDP"; Port=3389; Protocol="Tcp"; Priority=1000},
    @{Name="SSH"; Port=22; Protocol="Tcp"; Priority=1001},
    @{Name="HTTP"; Port=80; Protocol="Tcp"; Priority=1002},
    @{Name="HTTPS"; Port=443; Protocol="Tcp"; Priority=1003}
)

$optionalPorts = @(
    @{Name="MySQL"; Port=3306; Protocol="Tcp"},
    @{Name="PostgreSQL"; Port=5432; Protocol="Tcp"},
    @{Name="MS SQL"; Port=1433; Protocol="Tcp"},
    @{Name="FTP"; Port=21; Protocol="Tcp"},
    @{Name="SMTP"; Port=25; Protocol="Tcp"},
    @{Name="DNS"; Port=53; Protocol="*"}
)

# Login to Azure
try {
    Connect-AzAccount
} catch {
    Write-Error "Failed to connect to Azure: $_"
    exit
}

# Get and select subscription
$subscriptions = Get-AzSubscription
Write-Host "`nAvailable Subscriptions:"
for ($i = 0; $i -lt $subscriptions.Count; $i++) {
    Write-Host "$($i+1): $($subscriptions[$i].Name)"
}
$subChoice = Read-Host "Select subscription (1-$($subscriptions.Count))"
Set-AzContext -Subscription $subscriptions[$subChoice-1].Id

# Resource Group Management
Write-Host "`nResource Group Management"

# Get existing Resource Groups
$existingResourceGroups = Get-AzResourceGroup
if ($existingResourceGroups) {
    Write-Host "`nExisting Resource Groups:"
    for ($i = 0; $i -lt $existingResourceGroups.Count; $i++) {
        Write-Host "$($i+1): $($existingResourceGroups[$i].ResourceGroupName) (Location: $($existingResourceGroups[$i].Location))"
    }
} else {
    Write-Host "No existing Resource Groups found in this subscription."
}

$createNew = Read-Host "`nDo you want to create new Resource Groups? (Y/N)"
if ($createNew -eq 'Y') {
    $rgCount = Read-Host "How many Resource Groups do you want to create"
    for ($i = 0; $i -lt [int]$rgCount; $i++) {
        Write-Host "`nCreating Resource Group $($i+1):"
        $rg = New-ResourceGroupWithLocation
        Write-Host "Created new Resource Group: $($rg.ResourceGroupName)"
    }
}

# Update the list of all Resource Groups
$allResourceGroups = Get-AzResourceGroup
if ($allResourceGroups) {
    Write-Host "`nAll Available Resource Groups:"
    for ($i = 0; $i -lt $allResourceGroups.Count; $i++) {
        Write-Host "$($i+1): $($allResourceGroups[$i].ResourceGroupName) (Location: $($allResourceGroups[$i].Location))"
    }
} else {
    Write-Error "No Resource Groups available. Please create at least one Resource Group to continue."
    exit
}

$rgNames = $allResourceGroups | Select-Object -ExpandProperty ResourceGroupName

# Virtual Network Management
Write-Host "`nVirtual Network Management"

# Show existing VNets across all Resource Groups
Write-Host "`nExisting Virtual Networks:"
$allVNets = Get-AzVirtualNetwork
if ($allVNets) {
    foreach ($vnet in $allVNets) {
        Write-Host "`nVNet Name: $($vnet.Name)"
        Write-Host "Resource Group: $($vnet.ResourceGroupName)"
        Write-Host "Location: $($vnet.Location)"
        Write-Host "Address Space: $($vnet.AddressSpace.AddressPrefixes -join ', ')"
        Write-Host "Subnets:"
        foreach ($subnet in $vnet.Subnets) {
            Write-Host "  - $($subnet.Name) ($($subnet.AddressPrefix))"
        }
    }
} else {
    Write-Host "No existing Virtual Networks found."
}

$createNewVNet = Read-Host "`nDo you want to create new Virtual Networks? (Y/N)"
if ($createNewVNet -eq 'Y') {
    $vnetCount = Read-Host "How many Virtual Networks do you want to create"
    
    for ($i = 0; $i -lt [int]$vnetCount; $i++) {
        Write-Host "`nCreating Virtual Network $($i+1):"
        
        # Select Resource Group for VNet
        $selectedRG = $rgNames[(Show-Menu -Title "Select Resource Group for VNet:" -Options $rgNames)]
        
        $vnetName = Read-Host "Enter VNet name"
        $vnetAddress = Read-Host "Enter address prefix (e.g., 10.0.0.0/16)"
        $locationIndex = Show-Menu -Title "Select location:" -Options $locations
        
        $vnet = New-AzVirtualNetwork `
            -ResourceGroupName $selectedRG `
            -Location $locations[$locationIndex] `
            -Name $vnetName `
            -AddressPrefix $vnetAddress

        # Subnet Management
        Write-Host "`nSubnet Creation for $vnetName"
        $createNewSubnet = Read-Host "Do you want to create subnets? (Y/N)"
        
        if ($createNewSubnet -eq 'Y') {
            $subnetCount = Read-Host "How many subnets do you want to create"
            
            for ($j = 0; $j -lt [int]$subnetCount; $j++) {
                Write-Host "`nCreating Subnet $($j+1):"
                $subnetName = Read-Host "Enter subnet name"
                $subnetPrefix = Read-Host "Enter subnet address prefix"
                
                Add-AzVirtualNetworkSubnetConfig `
                    -Name $subnetName `
                    -VirtualNetwork $vnet `
                    -AddressPrefix $subnetPrefix

                $vnet | Set-AzVirtualNetwork
            }
        }
    }
}

# VM Creation
Write-Host "`nVirtual Machine Management"

# Show existing VMs across all Resource Groups
Write-Host "`nExisting Virtual Machines:"
$allVMs = Get-AzVM
if ($allVMs) {
    foreach ($vm in $allVMs) {
        Write-Host "`nVM Name: $($vm.Name)"
        Write-Host "Resource Group: $($vm.ResourceGroupName)"
        Write-Host "Location: $($vm.Location)"
        Write-Host "Size: $($vm.HardwareProfile.VmSize)"
        Write-Host "OS: $($vm.StorageProfile.OsDisk.OsType)"
    }
} else {
    Write-Host "No existing Virtual Machines found."
}

$createNewVM = Read-Host "`nDo you want to create new Virtual Machines? (Y/N)"
if ($createNewVM -eq 'Y') {
    [int]$vmCount = Read-Host "How many VMs do you want to create"
    
    for ($vmIndex = 0; $vmIndex -lt $vmCount; $vmIndex++) {
        Write-Host "`nCreating Virtual Machine $($vmIndex + 1):"
        
        # Select Resource Group for VM
        $rgIndex = Show-Menu -Title "Select Resource Group for VM:" -Options $rgNames
        $selectedRG = $rgNames[$rgIndex]
        
        $vmName = Read-Host "Enter VM name"
        $locationIndex = Show-Menu -Title "Select VM location:" -Options $locations
        
        # Select VNet and Subnet
        $vnets = Get-AzVirtualNetwork -ResourceGroupName $selectedRG
        if (!$vnets) {
            Write-Host "`nNo Virtual Networks found in resource group $selectedRG."
            $createVNet = Read-Host "Would you like to create a new VNet? (Y/N)"
            if ($createVNet -eq 'Y') {
                Write-Host "`nCreating new Virtual Network:"
                $vnetName = Read-Host "Enter VNet name"
                $vnetAddress = Read-Host "Enter address prefix (e.g., 10.0.0.0/16)"
                
                $vnet = New-AzVirtualNetwork `
                    -ResourceGroupName $selectedRG `
                    -Location $locations[$locationIndex] `
                    -Name $vnetName `
                    -AddressPrefix $vnetAddress

                Write-Host "`nCreating subnet:"
                $subnetName = Read-Host "Enter subnet name"
                $subnetPrefix = Read-Host "Enter subnet address prefix (e.g., 10.0.1.0/24)"
                
                Add-AzVirtualNetworkSubnetConfig `
                    -Name $subnetName `
                    -VirtualNetwork $vnet `
                    -AddressPrefix $subnetPrefix

                $vnet = $vnet | Set-AzVirtualNetwork
                
                $selectedVNet = $vnetName
                $selectedSubnet = $subnetName
            } else {
                Write-Error "A Virtual Network is required to create a VM. Please create a VNet first."
                continue
            }
        } else {
            $vnetNames = @($vnets | ForEach-Object { $_.Name })
            $vnetIndex = Show-Menu -Title "Select VNet:" -Options $vnetNames
            $selectedVNet = $vnetNames[$vnetIndex]
            $vnet = $vnets | Where-Object { $_.Name -eq $selectedVNet }
            
            if (!$vnet.Subnets) {
                Write-Host "`nNo subnets found in VNet $selectedVNet."
                $createSubnet = Read-Host "Would you like to create a new subnet? (Y/N)"
                if ($createSubnet -eq 'Y') {
                    Write-Host "`nCreating new subnet:"
                    $subnetName = Read-Host "Enter subnet name"
                    $subnetPrefix = Read-Host "Enter subnet address prefix (e.g., 10.0.1.0/24)"
                    
                    Add-AzVirtualNetworkSubnetConfig `
                        -Name $subnetName `
                        -VirtualNetwork $vnet `
                        -AddressPrefix $subnetPrefix

                    $vnet = $vnet | Set-AzVirtualNetwork
                    $selectedSubnet = $subnetName
                } else {
                    Write-Error "A subnet is required to create a VM. Please create a subnet first."
                    continue
                }
            } else {
                $subnetNames = @($vnet.Subnets | ForEach-Object { $_.Name })
                $subnetIndex = Show-Menu -Title "Select subnet:" -Options $subnetNames
                $selectedSubnet = $subnetNames[$subnetIndex]
            }
        }
        
       # OS Selection with validation
        Write-Host "`nSelecting Operating System:"
        do {
            $osChoice = Show-Menu -Title "Select Operating System:" -Options $osOptions
            if ($osChoice -ge 0 -and $osChoice -lt $osOptions.Count) {
                Write-Host "Selected OS: $($osOptions[$osChoice])"
                break
            }
            Write-Host "Invalid selection. Please try again."
        } while ($true)
        
        # VM Size Selection with validation
        Write-Host "`nSelecting VM Size:"
        do {
            Write-Host "`nAvailable VM Sizes:"
            for ($i = 0; $i -lt $vmSizes.Count; $i++) {
                Write-Host ("`n{0}: {1}" -f ($i+1), $vmSizes[$i].Name)
                Write-Host ("   Hardware: {0}" -f $vmSizes[$i].Description)
            }
            
            $sizeChoice = Read-Host "`nSelect VM Size (1-$($vmSizes.Count))"
            $sizeIndex = [int]$sizeChoice - 1
            if ($sizeIndex -ge 0 -and $sizeIndex -lt $vmSizes.Count) {
                $selectedSize = $vmSizes[$sizeIndex].Size
                Write-Host "Selected Size: $($vmSizes[$sizeIndex].Name)"
                break
            }
            Write-Host "Invalid selection. Please try again."
        } while ($true)
        
        # Create VM configuration with selected options
        $vmConfig = New-AzVMConfig -VMName $vmName -VMSize $selectedSize
        
        Write-Host "`nConfiguring OS: $($osOptions[$osChoice])"
        
        # Get credentials after OS selection
        $vmUsername = Read-Host "`nEnter username"
        $vmPassword = Read-Host "Enter password" -AsSecureString
        
        # Ensure we have a valid OS choice
        Write-Host "Selected OS Choice Index: $osChoice"
        Write-Host "Available OS Options: $($osOptions.Count)"
        
        if ($osChoice -lt 0 -or $osChoice -ge $osOptions.Count) {
            Write-Error "Invalid OS selection. Please choose a number between 1 and $($osOptions.Count)"
            continue
        }
        
        switch ($osOptions[$osChoice]) {
            "Windows 10" {
                $vmConfig = Set-AzVMOperatingSystem -VM $vmConfig -Windows -ComputerName $vmName -Credential (New-Object PSCredential ($vmUsername, $vmPassword))
                $vmConfig = Set-AzVMSourceImage -VM $vmConfig -PublisherName "MicrosoftWindowsDesktop" -Offer "Windows-10" -Skus "win10-21h2-pro" -Version "latest"
            }
            "Windows 11" {
                $vmConfig = Set-AzVMOperatingSystem -VM $vmConfig -Windows -ComputerName $vmName -Credential (New-Object PSCredential ($vmUsername, $vmPassword))
                $vmConfig = Set-AzVMSourceImage -VM $vmConfig -PublisherName "MicrosoftWindowsDesktop" -Offer "Windows-11" -Skus "win11-23h2-pro" -Version "latest"
            }
            "Windows Server 2019" {
                $vmConfig = Set-AzVMOperatingSystem -VM $vmConfig -Windows -ComputerName $vmName -Credential (New-Object PSCredential ($vmUsername, $vmPassword))
                $vmConfig = Set-AzVMSourceImage -VM $vmConfig -PublisherName "MicrosoftWindowsServer" -Offer "WindowsServer" -Skus "2019-Datacenter" -Version "latest"
            }
            "Windows Server 2022" {
                $vmConfig = Set-AzVMOperatingSystem -VM $vmConfig -Windows -ComputerName $vmName -Credential (New-Object PSCredential ($vmUsername, $vmPassword))
                $vmConfig = Set-AzVMSourceImage -VM $vmConfig -PublisherName "MicrosoftWindowsServer" -Offer "WindowsServer" -Skus "2022-Datacenter" -Version "latest"
            }
            "Debian 12" {
                $vmConfig = Set-AzVMOperatingSystem -VM $vmConfig -Linux -ComputerName $vmName -Credential (New-Object PSCredential ($vmUsername, $vmPassword))
                $vmConfig = Set-AzVMSourceImage -VM $vmConfig -PublisherName "Debian" -Offer "debian-12" -Skus "12" -Version "latest"
            }
        }
        
        # Create Public IP
        $publicIp = New-AzPublicIpAddress `
            -Name "$vmName-ip" `
            -ResourceGroupName $selectedRG `
            -Location $locations[$locationIndex] `
            -AllocationMethod Dynamic `
            -Sku Basic

        # Create NSG with default rules
        $nsgName = "$vmName-nsg"
        $nsg = New-AzNetworkSecurityGroup `
            -ResourceGroupName $selectedRG `
            -Location $locations[$locationIndex] `
            -Name $nsgName

        # Add default ports
        foreach ($port in $defaultPorts) {
            Add-AzNetworkSecurityRuleConfig `
                -NetworkSecurityGroup $nsg `
                -Name "$($port.Name)Rule" `
                -Protocol $port.Protocol `
                -SourcePortRange * `
                -DestinationPortRange $port.Port `
                -SourceAddressPrefix * `
                -DestinationAddressPrefix * `
                -Access Allow `
                -Priority $port.Priority `
                -Direction Inbound | Set-AzNetworkSecurityGroup
        }
        
        # Ask for additional ports
        Write-Host "`nAdditional available ports:"
        foreach ($port in $optionalPorts) {
            Write-Host "$($port.Name) ($($port.Port))"
        }
        
        $addPorts = Read-Host "Do you want to add more ports? (Y/N)"
        if ($addPorts -eq 'Y') {
            do {
                $portIndex = Show-Menu -Title "Select port to add:" -Options ($optionalPorts | ForEach-Object { $_.Name })
                $selectedPort = $optionalPorts[$portIndex]
                
                $priority = Read-Host "Enter priority for this rule (1004-4096)"
                
                Add-AzNetworkSecurityRuleConfig `
                    -NetworkSecurityGroup $nsg `
                    -Name "$($selectedPort.Name)Rule" `
                    -Protocol $selectedPort.Protocol `
                    -SourcePortRange * `
                    -DestinationPortRange $selectedPort.Port `
                    -SourceAddressPrefix * `
                    -DestinationAddressPrefix * `
                    -Access Allow `
                    -Priority $priority `
                    -Direction Inbound | Set-AzNetworkSecurityGroup
                    
                $addMore = Read-Host "Add more ports? (Y/N)"
            } while ($addMore -eq 'Y')
        }
        
        # Create NIC
        $nic = New-AzNetworkInterface `
            -Name "$vmName-nic" `
            -ResourceGroupName $selectedRG `
            -Location $locations[$locationIndex] `
            -SubnetId ($vnet.Subnets | Where-Object { $_.Name -eq $selectedSubnet }).Id `
            -PublicIpAddressId $publicIp.Id `
            -NetworkSecurityGroupId $nsg.Id

        # Add NIC to VM config
        $vmConfig = Add-AzVMNetworkInterface -VM $vmConfig -Id $nic.Id -Primary
        
        # Create VM
        Write-Host "`nCreating VM $vmName. This may take several minutes..."
        try {
            $newVM = New-AzVM `
                -ResourceGroupName $selectedRG `
                -Location $locations[$locationIndex] `
                -VM $vmConfig

            Write-Host "VM $vmName created successfully!"
            
            # Display VM connection information
            Write-Host "`nConnection Information for $($vmName):"
            try {
                $publicIpAddress = Get-AzPublicIpAddress -Name "$vmName-ip" -ResourceGroupName $selectedRG
                $ipAddress = $publicIpAddress.IpAddress
                if ($ipAddress -eq "Not Assigned") {
                    Write-Host "Public IP: Waiting for assignment. Please check Azure portal."
                    if ($osOptions[$osChoice] -like "Windows*") {
                        Write-Host "Once IP is assigned, connect using RDP."
                    } else {
                        Write-Host "Once IP is assigned, connect using SSH: ssh $vmUsername@<IP>"
                    }
                } else {
                    Write-Host "Public IP: $ipAddress"
                    if ($osOptions[$osChoice] -like "Windows*") {
                        Write-Host "Connect using RDP to IP: $ipAddress"
                    } else {
                        Write-Host "Connect using SSH: ssh $vmUsername@$ipAddress"
                    }
                }
            } catch {
                Write-Host "Public IP: Waiting for assignment. Please check Azure portal."
                if ($osOptions[$osChoice] -like "Windows*") {
                    Write-Host "Once IP is assigned, connect using RDP."
                } else {
                    Write-Host "Once IP is assigned, connect using SSH: ssh $vmUsername@<IP>"
                }
            }
        } catch {
            Write-Error "Failed to create VM: $_"
            continue
        }
    }
}

Write-Host "`nResource deployment completed successfully!"
Write-Host "Script execution finished."