Add-Type -AssemblyName System.Net

Connect-AzAccount -UseDeviceAuthentication

function Validate-SubnetPrefix {
    param($vnetPrefix, $subnetPrefix)
    
    try {
        $vnetNetwork = [System.Net.IPNetwork]::Parse($vnetPrefix)
        $subnetNetwork = [System.Net.IPNetwork]::Parse($subnetPrefix)
        
        if ($subnetNetwork.NetworkAddress -lt $vnetNetwork.NetworkAddress -or 
            $subnetNetwork.BroadcastAddress -gt $vnetNetwork.BroadcastAddress) {
            Write-Host "Invalid Subnet Prefix! Must be within VNet address space." -ForegroundColor Red
            return $false
        }
        return $true
    }
    catch {
        Write-Host "Invalid IP network format." -ForegroundColor Red
        return $false
    }
}

# Common Azure Locations
$commonLocations = @(
    "eastus",
    "westeurope",
    "northeurope",
    "westus2",
    "southeastasia",
    "eastus2",
    "centralus",
    "uksouth"
)

function Select-AzureLocation {
    Write-Host "`nAvailable Locations:"
    for ($i = 0; $i -lt $commonLocations.Count; $i++) {
        Write-Host "$($i + 1). $($commonLocations[$i])"
    }
    Write-Host "$($commonLocations.Count + 1). Enter different location"
    
    $locationChoice = Read-Host "Enter your choice"
    
    if ($locationChoice -eq ($commonLocations.Count + 1)) {
        return Read-Host "Enter the location (e.g., eastus, westeurope)"
    } else {
        return $commonLocations[$locationChoice - 1]
    }
}

# Subscription Selection
$subscriptions = Get-AzSubscription
Write-Host "Available subscriptions:"
for ($i = 0; $i -lt $subscriptions.Count; $i++) {
    Write-Host "$($i + 1). $($subscriptions[$i].Name)"
}
$subscriptionChoice = Read-Host "Enter your choice"
$selectedSubscription = $subscriptions[$subscriptionChoice - 1]
Set-AzContext -SubscriptionId $selectedSubscription.Id

# Resource Group Selection
$resourceGroups = Get-AzResourceGroup
Write-Host "Available Resource Groups:"
for ($i = 0; $i -lt $resourceGroups.Count; $i++) {
    Write-Host "$($i + 1). $($resourceGroups[$i].ResourceGroupName)"
}
Write-Host "$($resourceGroups.Count + 1). Create a new Resource Group"
$resourceGroupChoice = Read-Host "Enter your choice"

if ($resourceGroupChoice -eq ($resourceGroups.Count + 1)) {
    $rgName = Read-Host "Enter the new Resource Group name"
    $rgLocation = Select-AzureLocation
    $selectedResourceGroup = New-AzResourceGroup -Name $rgName -Location $rgLocation
} else {
    $selectedResourceGroup = $resourceGroups[$resourceGroupChoice - 1]
    $rgLocation = $selectedResourceGroup.Location
}

# VNet Selection/Creation
$vnetList = Get-AzVirtualNetwork -ResourceGroupName $selectedResourceGroup.ResourceGroupName
Write-Host "Available VNets:"
for ($i = 0; $i -lt $vnetList.Count; $i++) {
    Write-Host "$($i + 1). $($vnetList[$i].Name)"
}
Write-Host "$($vnetList.Count + 1). Create a new VNet"
$vnetChoice = Read-Host "Enter your choice"

if ($vnetChoice -eq ($vnetList.Count + 1)) {
    $vnetName = Read-Host "Enter new VNet name"
    $vnetLocation = Select-AzureLocation
    $vnetAddressSpace = Read-Host "Enter VNet Address Space (e.g., 10.0.0.0/16)"
    $selectedVnet = New-AzVirtualNetwork -ResourceGroupName $selectedResourceGroup.ResourceGroupName -Location $vnetLocation -Name $vnetName -AddressPrefix $vnetAddressSpace
} else {
    $selectedVnet = $vnetList[$vnetChoice - 1]
}

# Subnet Selection/Creation
$subnetList = $selectedVnet | Get-AzVirtualNetworkSubnetConfig
Write-Host "Available Subnets:"
for ($i = 0; $i -lt $subnetList.Count; $i++) {
    Write-Host "$($i + 1). $($subnetList[$i].Name)"
}
Write-Host "$($subnetList.Count + 1). Create a new Subnet"
$subnetChoice = Read-Host "Enter your choice"

if ($subnetChoice -eq ($subnetList.Count + 1)) {
    $subnetName = Read-Host "Enter new subnet name"
    $subnetAddressPrefix = Read-Host "Enter subnet address prefix"
    while (-not (Validate-SubnetPrefix -vnetPrefix $selectedVnet.AddressSpace.AddressPrefixes[0] -subnetPrefix $subnetAddressPrefix)) {
        $subnetAddressPrefix = Read-Host "Re-enter valid subnet address prefix"
    }
    Add-AzVirtualNetworkSubnetConfig -Name $subnetName -VirtualNetwork $selectedVnet -AddressPrefix $subnetAddressPrefix | Out-Null
    $selectedVnet = $selectedVnet | Set-AzVirtualNetwork
    $subnet = Get-AzVirtualNetworkSubnetConfig -Name $subnetName -VirtualNetwork $selectedVnet
} else {
    $subnet = $subnetList[$subnetChoice - 1]
}

# VM Sizes
$vmSizes = @(
    @{ Size = "Standard_B1s"; Cpus = 1; Ram = 1 },
    @{ Size = "Standard_B2s"; Cpus = 2; Ram = 4 },
    @{ Size = "Standard_D2s_v3"; Cpus = 2; Ram = 8 },
    @{ Size = "Standard_D4s_v3"; Cpus = 4; Ram = 16 },
    @{ Size = "Standard_E2s_v3"; Cpus = 2; Ram = 16 },
    @{ Size = "Standard_E4s_v3"; Cpus = 4; Ram = 32 },
    @{ Size = "Standard_F2s"; Cpus = 2; Ram = 4 },
    @{ Size = "Standard_F4s"; Cpus = 4; Ram = 8 }
)
Write-Host "Available VM Sizes:"
for ($i = 0; $i -lt $vmSizes.Count; $i++) {
    Write-Host "$($i + 1). $($vmSizes[$i].Size) - CPUs: $($vmSizes[$i].Cpus), RAM: $($vmSizes[$i].Ram) GB"
}
$vmSizeChoice = Read-Host "Enter your choice"
$selectedVmSize = $vmSizes[$vmSizeChoice - 1]

# Default NSG Rules Configuration
Write-Host "`nConfiguring Network Security Group (NSG) Rules"

# Default rules
$nsgRules = @(
    @{
        Name = "Allow-HTTP"
        Port = "80"
        Priority = "200"
        Protocol = "TCP"
    },
    @{
        Name = "Allow-HTTPS"
        Port = "443"
        Priority = "210"
        Protocol = "TCP"
    },
    @{
        Name = "Allow-RDP"
        Port = "3389"
        Priority = "220"
        Protocol = "TCP"
    },
    @{
        Name = "Allow-SSH"
        Port = "22"
        Priority = "230"
        Protocol = "TCP"
    }
)

Write-Host "`nDefault rules that will be created:"
foreach ($rule in $nsgRules) {
    Write-Host "- $($rule.Name) (Port: $($rule.Port), Priority: $($rule.Priority))"
}

$addMore = Read-Host "`nDo you want to add more rules? (Y/N)"
$nextPriority = 260  # Start custom rules from 260

while ($addMore.ToUpper() -eq 'Y') {
    Write-Host "`nAdd new NSG rule:"
    $ruleName = Read-Host "Enter rule name"
    $port = Read-Host "Enter port number"
    
    $nsgRules += @{
        Name = $ruleName
        Port = $port
        Priority = $nextPriority.ToString()
        Protocol = "TCP"
    }
    
    $nextPriority += 10
    $addMore = Read-Host "Add another rule? (Y/N)"
}

# OS Images
$osImages = @(
    @{ Name = "Windows 10"; Publisher = "MicrosoftWindowsDesktop"; Offer = "Windows-10"; Sku = "win10-21h2-pro"; Version = "latest" },
    @{ Name = "Windows 11"; Publisher = "MicrosoftWindowsDesktop"; Offer = "Windows-11"; Sku = "win11-22h2-pro"; Version = "latest" },
    @{ Name = "Windows Server 2019"; Publisher = "MicrosoftWindowsServer"; Offer = "WindowsServer"; Sku = "2019-Datacenter"; Version = "latest" },
    @{ Name = "Windows Server 2022"; Publisher = "MicrosoftWindowsServer"; Offer = "WindowsServer"; Sku = "2022-Datacenter"; Version = "latest" },
    @{ Name = "Debian 11"; Publisher = "Debian"; Offer = "debian-11"; Sku = "11"; Version = "latest" }
)
Write-Host "Available OS Images:"
for ($i = 0; $i -lt $osImages.Count; $i++) {
    Write-Host "$($i + 1). $($osImages[$i].Name)"
}
$imageChoice = Read-Host "Enter your choice"
$selectedImage = $osImages[$imageChoice - 1]

# VM Name and Credentials
$vmName = Read-Host "Enter VM name"
$adminUser = Read-Host "Enter admin username"
$adminPassword = Read-Host "Enter admin password" -AsSecureString

# Public IP Creation
$publicIpName = $vmName + "-PublicIP"
$publicIp = New-AzPublicIpAddress -Name $publicIpName `
    -ResourceGroupName $selectedResourceGroup.ResourceGroupName `
    -Location $rgLocation `
    -AllocationMethod Static `
    -Sku Standard

# Network Security Group Creation
$nsgName = $vmName + "-NSG"
$nsg = New-AzNetworkSecurityGroup -Name $nsgName -ResourceGroupName $selectedResourceGroup.ResourceGroupName -Location $rgLocation

# Add Network Security Group Rules
foreach ($rule in $nsgRules) {
    Add-AzNetworkSecurityRuleConfig -NetworkSecurityGroup $nsg `
        -Name $rule.Name `
        -Description "Allow $($rule.Name) Inbound" `
        -Access Allow `
        -Protocol $rule.Protocol `
        -Direction Inbound `
        -Priority $rule.Priority `
        -SourceAddressPrefix Internet `
        -SourcePortRange * `
        -DestinationAddressPrefix * `
        -DestinationPortRange $rule.Port | Out-Null
}

# Update Network Security Group
$nsg | Set-AzNetworkSecurityGroup | Out-Null

# Network Interface Creation
$nicName = $vmName + "-NIC"
$nicConfig = New-AzNetworkInterfaceIpConfig -Name "ipconfig1" -SubnetId $subnet.Id -PublicIpAddressId $publicIp.Id
$nic = New-AzNetworkInterface -Name $nicName `
    -ResourceGroupName $selectedResourceGroup.ResourceGroupName `
    -Location $rgLocation `
    -IpConfiguration $nicConfig `
    -NetworkSecurityGroupId $nsg.Id

# VM Configuration
$vmConfig = New-AzVMConfig -VMName $vmName -VMSize $selectedVmSize.Size

# Set OS configuration based on the selected image
if ($selectedImage.Publisher -like "*Windows*") {
    $vmConfig = Set-AzVMOperatingSystem -VM $vmConfig `
        -Windows `
        -ComputerName $vmName `
        -Credential (New-Object System.Management.Automation.PSCredential($adminUser, $adminPassword))
} else {
    $vmConfig = Set-AzVMOperatingSystem -VM $vmConfig `
        -Linux `
        -ComputerName $vmName `
        -Credential (New-Object System.Management.Automation.PSCredential($adminUser, $adminPassword))
}

# Set source image
$vmConfig = Set-AzVMSourceImage -VM $vmConfig `
    -PublisherName $selectedImage.Publisher `
    -Offer $selectedImage.Offer `
    -Skus $selectedImage.Sku `
    -Version $selectedImage.Version

# Add NIC to VM config
$vmConfig = Add-AzVMNetworkInterface -VM $vmConfig -Id $nic.Id -Primary

# Create VM
New-AzVM `
    -ResourceGroupName $selectedResourceGroup.ResourceGroupName `
    -Location $rgLocation `
    -VM $vmConfig

Write-Host "VM $vmName created successfully with Public IP and Configured NSG!" -ForegroundColor Green