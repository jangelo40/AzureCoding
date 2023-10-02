# Input bindings are passed in via param block.
param($Timer)
Write-Host "Running"

# Connect to subscription
$subscriptionId = "subscriptionIDHere"
Connect-AzAccount -Identity

# Set your teams webhook URL
$teamsWebhookUrl = “https:/WwebhookURLhere!"

# Get all Key Vaults in the subscription
$KeyVaults = Get-AzKeyVault -SubscriptionId $subscriptionId

# Loop through KeyVaults
foreach ($vault in $keyVaults) {
    $vaultName = $vault.VaultName
    $expiryThreshold = (Get-Date).AddDays(90)
    $expiringOrExpiredItems = @()

    # Retrieve secrets
    $secrets = Get-AzKeyVaultSecret -VaultName $vaultName
    foreach ($secret in $secrets) {
        if ($secret.Expires -le $expiryThreshold) {
            $expiringOrExpiredItems += "Secret: $($secret.Name), Expiry: $($secret.Expires)"
        }
    }

    # Retrieve keys
    $keys = Get-AzKeyVaultKey -VaultName $vaultName
    foreach ($key in $keys) {
        if ($key.Expires -le $expiryThreshold) {
            $expiringOrExpiredItems += "Key: $($key.Name), Expiry: $($key.Expires)"
        }
    }

    # Retrieve certificates
    $certificates = Get-AzKeyVaultCertificate -VaultName $vaultName
    foreach ($certificate in $certificates) {
        if ($certificate.Expires -le $expiryThreshold) {
            $expiringOrExpiredItems += "Certificate: $($certificate.Name), Expiry: $($certificate.Expires)"
        }
    }

    # If there are expiring/expired items, send a Teams notification
    if ($expiringOrExpiredItems.Count -gt 0) {
        $message = @{
            title = "Azure KeyVault Expiring/Expired Items"
            text = "Here are the items expiring or expired in KeyVault $($vaultName):`r`n$($expiringOrExpiredItems -join "`r`n")"
        }
        $messageJson = $message | ConvertTo-Json

        # Send data to Teams webhook
        Invoke-RestMethod -Uri $teamsWebhookUrl -Method Post -ContentType "application/json" -Body $messageJson
    }
}

# Write an information log with the current time.
Write-Host "PowerShell timer trigger function ran! TIME: $currentUTCtime"
