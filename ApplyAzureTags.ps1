#Connect-AzAccount
$csv = Import-Csv -Path '/Users/u13873/Desktop/TaggingFolder/Sandboxtags.csv'
$currentConfig = '/Users/u13873/Desktop/TaggingFolder/OriginalSandboxTags.csv'
 
foreach ($item in $csv) {
    #Point to proper subscription
    $null = Set-AzContext -Subscription $item.Subscription
    $rg = Get-AzResourceGroup -Name $item.ResourceGroup
    #Region Grab current configs and export to CSV
     [System.Collections.Hashtable]$Tags = $rg.Tags
     $out = [ordered]@{
         'ResourceGroupName' = $item.ResourceGroup
         'Subscription'      = $item.Subscription
     }
     $Tags.GetEnumerator() | ForEach-Object {
         $out.($_.Name) = $_.Value
     }
     $out | ForEach-Object {[PSCustomObject]$_} | Export-Csv -Path $currentConfig -NoTypeInformation -Append
     #EndRegion
 
    #Add tags to Resource Group AND everything underneath it
    # https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/tag-resources
    [Array]$ResID = (Get-AzResource -ResourceGroupName $rg.ResourceGroupName).ResourceId
    $ResID += $rg.ResourceId
    foreach ($id in $ResID) {
        Update-AzTag -Operation Merge -ResourceId $id -Tag @{
            #'Portfolio'           = $item.Portfolio
            #'Environment'         = $item.Environment
            'Application'         = $item.Application
            'ContactEmail'        = $item.ContactEmail
            'Project'             = $item.Project
            'BusinessCriticality' = $item.BusinessCriticality
            'DataClassification'  = $item.DataClassification
            }
    }
}
