# Input bindings are passed in via param block.
param($Timer)

# Get the current universal time in the default string format.
$currentUTCtime = (Get-Date).ToUniversalTime()

# Authenticate to Azure via Function App Managed Identity
Connect-AzAccount -Identity -ErrorAction SilentlyContinue

# Get all KeyVaults in the current subscription
$keyVaults = Get-AzKeyVault

# Define the expiration time (1 year from the current date)
$expirationDate = (Get-Date).AddYears(1)

# Iterate through each KeyVault
foreach ($vault in $keyVaults) {
    # Get all keys without an expiration date
    $keysWithoutExpiration = Get-AzKeyVaultKey -VaultName $vault.VaultName | Where-Object { $_.Expires -eq $null }

    # Set expiration for each key
    foreach ($key in $keysWithoutExpiration) {
        Set-AzKeyVaultKeyAttribute -VaultName $vault.VaultName -Name $key.Name -Expires $expirationDate
        Write-Host "Set expiration for Key $($key.Name) in $($vault.VaultName) to $($expirationDate.ToString())"
    }

    # Get all secrets without an expiration date
    $secretsWithoutExpiration = Get-AzKeyVaultSecret -VaultName $vault.VaultName | Where-Object { $_.Expires -eq $null }

    # Set expiration for each secret
    foreach ($secret in $secretsWithoutExpiration) {
        Set-AzKeyVaultSecretAttribute -VaultName $vault.VaultName -Name $secret.Name -Expires $expirationDate
        Write-Host "Set expiration for Secret $($secret.Name) in $($vault.VaultName) to $($expirationDate.ToString())"
    }
}
