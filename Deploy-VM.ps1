# Microsoft Azure

# Login
# Login-AzureRmAccount

# Register resource providers
# Register-AzureRmResourceProvider -ProviderNamespace 'Microsoft.Network'
# Register-AzureRmResourceProvider -ProviderNamespace 'Microsoft.Compute'
# Register-AzureRmResourceProvider -ProviderNamespace 'Microsoft.Storage'

function NEW-AZUREVM {
    [Cmdletbinding()]
        param (
            [Parameter(Mandatory,HelpMessage='Select yes or no for creating a new resource group')]
            [ValidateSet('yes','no')]
            $NewResourceGroup,
            [Parameter(Mandatory,HelpMessage='Select yes or no for creating a new VNET')]
            [ValidateSet('yes','no')]
            $New_VNET,
            [Parameter(Mandatory)]
            $SubnetName,
            [Parameter(Mandatory)]
            $ResourceGroupName,
            [Parameter(Mandatory)]
            $VnetName,     
            [Parameter(Mandatory)]
            $VMname,
            [Parameter(Mandatory)]
            $Publisher,  
            [Parameter(Mandatory)]
            $location,  
            [Parameter(Mandatory)]
            $offer,  
            [Parameter(Mandatory)]
            $sku,  
            [Parameter(Mandatory)]
            $vmsize,         
            [Parameter(Mandatory)]
            $IPPUB,  
            [Parameter(Mandatory)]
            $nsgname,
            [Parameter(Mandatory)]
            $nicname,
            [Parameter(Mandatory)]
            $user         
        )
    
$regex = '[yn]'
    
Write-Output "
AZURE-VM configuration:
    
New resource group: $NewResourceGroup 
New VNET: $New_VNET
Subnet Name: $SubnetName
Resouce group name: $ResourceGroupName
VNET Name: $VnetName 
VM Name: $VMname
Publisher: $Publisher  
Location: $location  
Offer: $offer  
Sku: $sku  
VM Size: $vmsize         
Public IP: $IPPUB         
NSG Name: $nsgname
NIC Name: $nicname        
User: $user
    
Confirm action, press [Y]es or [N]o:
"
    do {
        $Confirm = Read-host     
            if($Confirm -notmatch $regex) {
                Write-Warning "Invalid option, please choose Y or N"
            }
    }until ($confirm -match $regex)
            
            if($Confirm -eq 'Y') {
    
        # Public IP 
        $PublicIP_Params = @{
            'ResourceGroupName' = $ResourceGroupName
            'Location' = $location
            'AllocationMethod' = 'Static'
            'IdletimeoutInMinutes'= 4
            'Name' = $IPPUB
        }
            if($NewResourceGroup -eq 'yes'){
                New-AzureRmResourceGroup -Name $ResourceGroupName -Location $location
            }    
            
        $pip = New-AzureRmPublicIpAddress @PublicIP_Params
        
    # NEW_Vnet
    if($New_VNET -eq 'yes'){    
        $SubNet_Address = read-host "Subnet address" 
        $VNET_Address = Read-Host "VNET address"                        
        $Subnet_Params = @{
            'Name' = $SubNet_Name
            'AddressPrefix' = $SubNet_Address
        }
            $subnet = New-AzureRmVirtualNetworkSubnetConfig -Name $SubnetName -AddressPrefix $SubNet_Address
            
        $VNET_Params = @{
            'Name' = $VnetName
            'ResourceGroupName' = $ResourceGroupName
            'Location' = $location
            'AddressPrefix' = $VNET_Address
            'Subnet' = $subnet
        }
            New-AzureRmVirtualNetwork @VNET_Params    
    }    
        #NSG Rule RDP    
        $RDP_Params = @{
            'Name' = 'Allow_RDP'
            'Protocol' = 'TCP'
            'Direction' = 'Inbound'
            'Priority' = 1000
            'SourceAddressPrefix' = '*'
            'SourcePortRange' = '*'
            'DestinationAddressPrefix' = '*'
            'DestinationPortRange' = 3389
            'Access' = 'Allow'
        }
            $NsgRuleRDP = New-AzureRmNetworkSecurityRuleConfig @RDP_Params
    
        #NSG Rule WEB    
        $WEB_Params = @{
            'Name' = 'Allow_WWW'
            'Protocol' = 'TCP'
            'Direction' = 'Inbound'
            'Priority' = 1001
            'SourceAddressPrefix' = '*'
            'SourcePortRange' = '*'
            'DestinationAddressPrefix' = '*'
            'DestinationPortRange' = 80
            'Access' = 'Allow'                  
        }
            $NsgRuleWeb = New-AzureRmNetworkSecurityRuleConfig @WEB_Params
    
        #NSG
        $NSG_Params = @{
            'Name' = $nsgname
            'ResourceGroupName' = $ResourceGroupName
            'Location' = $location
            'SecurityRules' = $NsgRuleRDP,$NsgRuleWeb
        }
            $nsg = New-AzureRmNetworkSecurityGroup @NSG_Params
    
        #NIC 
        $VnetInfo_Params = @{
            'Name' = $VnetName
            'ResourceGroupName' = $ResourceGroupName
        }
            $VnetInfo = Get-AzureRmVirtualNetwork @VnetInfo_Params | Get-AzureRmVirtualNetworkSubnetConfig -Name $SubnetName   
        
        $NIC_Params = @{
            'Name' = $nicname
            'ResourceGroupName' = $ResourceGroupName
            'Location' = $location
            'SubnetID' = $VnetInfo.Id
            'PublicIpAddressId' = $pip.Id
            'NetworkSecurityGroupId' = $nsg.Id
        }
            $nic = New-AzureRmNetworkInterface @NIC_Params
    
        #Credential
        $pwd = Read-Host -AsSecureString -Prompt 'Enter a password'  
        $cred = New-Object -TypeName PSCredential -ArgumentList (($user),($pwd))
    
        #VM_Config
        $VMConfig_Params = @{
            'VMName' = $VMname
            'VMSize' = $vmsize
        }
    
        $VMOS_Params = @{
            'Windows' = $true
            'ComputerName' = $VMname
            'Credential' = $cred
        }
    
        $SRC_ImageParams = @{
            'PublisherName' = $Publisher
            'Offer' = $offer
            'Skus' = $sku
            'Version' = 'Latest'
        }
            $VMConfig = New-AzureRmVMConfig @VMConfig_Params | 
            Set-AzureRmVMOperatingSystem @VMOS_Params | 
            Set-AzureRmVMSourceImage @SRC_ImageParams | 
            Add-AzureRmVMNetworkInterface -Id $nic.Id
                   
            New-AzureRmVM -ResourceGroupName $ResourceGroupName -Location $Location -VM $VMConfig
        }
            else{break;}
    }
