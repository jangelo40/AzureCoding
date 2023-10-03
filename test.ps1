# Input bindings are passed in via param block.
param($Timer)

# Get the current universal time in the default string format.
$currentUTCtime = (Get-Date).ToUniversalTime()

# Authenticate to Azure via Function App Managed Identity
Connect-AzAccount -Identity -ErrorAction SilentlyContinue

# Set your teams webhook URL
$teamsWebhookUrl = "WebhookURLHere"

# Get all Key Vaults in the subscription
$KeyVaults = Get-AzKeyVault

# Loop through KeyVaults
foreach ($vault in $keyVaults) {
    $vaultName = $vault.VaultName
    $expiryThreshold = (Get-Date).AddDays(90)
    $ExpiredItems = @()

    # Retrieve secrets
    $secrets = Get-AzKeyVaultSecret -VaultName $vaultName
    foreach ($secret in $secrets) {
        if ($secret.Expires -le $expiryThreshold) {
            $ExpiredItems += "Secret: $($secret.Name), Expiry: $($secret.Expires)"
        }
    }

    # Retrieve keys
    $keys = Get-AzKeyVaultKey -VaultName $vaultName
    foreach ($key in $keys) {
        if ($key.Expires -le $expiryThreshold) {
            $ExpiredItems += "Key: $($key.Name), Expiry: $($key.Expires)"
        }
    }

    # Retrieve certificates
    $certificates = Get-AzKeyVaultCertificate -VaultName $vaultName
    foreach ($certificate in $certificates) {
        if ($certificate.Expires -le $expiryThreshold) {
            $ExpiredItems += "Certificate: $($certificate.Name), Expiry: $($certificate.Expires)"
        }
    }

    # If there are expiring/expired items, send a Teams notification
    if ($ExpiredItems.Count -gt 0) {
        $message = @{
            title = "Azure KeyVault Expiring/Expired Items"
            text = "Here are the items expiring or expired in KeyVault $($vaultName):`r`n$($ExpiredItems -join "`r`n")"
        }
        $messageJson = $message | ConvertTo-Json

        # Send data to Teams webhook
        Invoke-RestMethod -Uri $teamsWebhookUrl -Method Post -ContentType "application/json" -Body $messageJson
    }
}

# Write an information log with the current time.
Write-Host "PowerShell timer trigger function ran! TIME: $currentUTCtime"
