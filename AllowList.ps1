# Output file names
$ghGitOut = ".\files\AllowList_Github_git.netset"
$logFile = ".\AllowList.log"

Set-Location $PSScriptRoot

Out-File -InputObject "$(Get-Date -Format g) Script start" -FilePath $logFile -Append

#Github IPs to Allow
$url = "https://api.github.com/meta"
$content = (Invoke-WebRequest -Uri $url -UseBasicParsing -ErrorAction Stop).Content
$json = $content | ConvertFrom-Json


# Output the cleaned IP list
Write-Host "Writing file $ghGitOut"
$json.git | Set-Content $ghGitOut

# Compare new and old lists
# Compare-Object -ReferenceObject (Get-Content $ghGitOut) -DifferenceObject $json.git

if (!!($error)) {Out-File -InputObject $error -FilePath $logFile -Append}
Out-File -InputObject "$(Get-Date -Format g) Script end" -FilePath $logFile -Append