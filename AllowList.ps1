# Output file names
$ghGitOut = ".\files\AllowList_Github_git.netset"

#Github IPs to Allow
$url = "https://api.github.com/meta"
$content = (Invoke-WebRequest -Uri $url -UseBasicParsing -ErrorAction Stop).Content
$json = $content | ConvertFrom-Json -Depth 10


# Output the cleaned IP list
Write-Host "Writing file $ghGitOut"
$json.git | Set-Content $ghGitOut

# Compare new and old lists
Compare-Object -ReferenceObject (Get-Content $ghGitOut) -DifferenceObject $cleanIPs