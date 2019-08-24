function New-AzureVaultBKP {
    param(
        [parameter(Mandatory)]
        $name,
        [parameter(Mandatory)]
        $ResourceGroupName,
        [parameter(Mandatory)]
        $Location
        )    

    #Login-AzureRmAccount
    #Register-AzureRmResourceProvider -ProviderNamespace "Microsoft.RecoveryServices"

    $regex = "Y|N"

    $VaultParam = @{
        'Name' = $Name
        'ResourceGroupName' = $ResourceGroupName
        'Location' = $Location
    }

    $VaultParam | ft

    do{     
        $confirm = Read-Host "Confirm configuration [Y]es or [N]o?"
         if($regex -notmatch $confirm){
             Write-Warning "Invalid option, please hit the keys 'Y' or 'N'"
          }
    }Until($confirm -match 'Y')

        New-AzureRmRecoveryServicesVault @VaultParam

    #Configure backup type as LRS

        $Vault = Get-AzureRmRecoveryServicesVault -Name $Name 
        Set-AzureRmRecoveryServicesBackupProperties -Vault $Vault -BackupStorageRedundancy LocallyRedundant

    #Create azure folder and download vault settings file

    if(!(Test-Path "$env:SystemDrive\Azure_VaultSettings")){
        set-location $env:SystemDrive\
        mkdir Azure_VaultSettings
    }
        $Path = "$env:SystemDrive\Azure_VaultSettings"

    $VaultSettings = @{
        'Backup' = $true
        'Vault' = $Vault
        'Path' = $Path
}
        Get-AzureRmRecoveryServicesVaultSettingsFile @VaultSettings
}
