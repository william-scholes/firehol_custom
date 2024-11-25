# Define the blocklist URLs
$lists = @'
https://raw.githubusercontent.com/firehol/blocklist-ipsets/refs/heads/master/firehol_level1.netset
https://raw.githubusercontent.com/firehol/blocklist-ipsets/refs/heads/master/firehol_level2.netset
https://raw.githubusercontent.com/firehol/blocklist-ipsets/refs/heads/master/firehol_level3.netset
'@ -split "`r`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }

# Define CIDR blocks to exclude
$exclude = @'
10.0.0.0/8
172.16.0.0/12
192.168.0.0/16
224.0.0.0/3
0.0.0.0/8
'@ -split "`r`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }

# Initialize collection for clean IP list
$cleanIPs = [System.Collections.Generic.List[string]]::new()

# Process each blocklist URL
foreach ($url in $lists) {
    try {
        Write-Host "Fetching data from $url ..."
        $content = (Invoke-WebRequest -Uri $url -UseBasicParsing -ErrorAction Stop).Content

        # Process each line in the content
        $lines = $content -split "`r?`n"
        foreach ($line in $lines) {
            # Exclude comments and private IP ranges
            if ($line -notmatch "^#" -and $line -notin $exclude) {
                $cleanIPs.Add($line.Trim())
            }
        }
    } catch {
        Write-Error "Failed to fetch or process $url`: $_"
    }
}

# Output the cleaned IP list
Write-Host "Writing file .\Firehol1_2_3_custom.netset"
$cleanIPs | Set-Content ".\Firehol1_2_3_custom.netset"

# Compare new and old lists 
Compare-Object -ReferenceObject (Get-Content ".\Firehol1_2_3_custom.netset") -DifferenceObject $cleanIPs


