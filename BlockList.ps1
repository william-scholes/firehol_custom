# Define the output location
$fhOut = ".\files\BlockList_Firehol1_2_3_custom.netset"

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

# Compare new and old lists
$compared = Compare-Object -ReferenceObject (Get-Content $fhOut) -DifferenceObject $cleanIPs
Write-Host $compared

# Output the cleaned IP list
Write-Host "Writing file $fhOut"
$cleanIPs | Set-Content $fhOut



<#
#FMA

#$email = ($testString | Select-String -Pattern 'Email: (\S+)' -AllMatches | ForEach-Object { $_.Matches } | ForEach-Object { $_.Groups[1].Value }).replace("Address:","")


$FMA_Url = "https://www.fma.govt.nz/library/warnings-and-alerts/downloadWarnings/?date=all"
$FMA_Data = (Invoke-WebRequest $FMA_Url -UseBasicParsing -ErrorAction Stop).Content

$FMA_URLs = [System.Collections.Generic.List[string]]::new()
$FMA_lines = $FMA_Data -split "`r?`n"

foreach ($FMA_line in $FMA_lines) {
    # Extract website URL and clean up common issues
    $website = ($FMA_line | Select-String -Pattern 'Website:\s*(\S+)' -AllMatches | 
        ForEach-Object { $_.Matches } | 
        ForEach-Object { $_.Groups[1].Value }) -replace 'Email:|ADDRESS:|PHONE:|REASON|;|"|,+$|&nbsp;'

    if ($website) {
        # Clean up the URL
        $website = $website.Trim()
        # Remove any trailing special characters
        $website = $website -replace '[,;"]$'
        # Remove any text after the domain (if it contains a word character after space)
        $website = $website -replace '\s+\w.*$'
        
        if ($website) {
            $FMA_URLs.Add($website)
        }
    }
}

# Optional: Remove duplicates and sort
$FMA_URLs = $FMA_URLs | Select-Object -Unique | Sort-Object

$FMA_URLs

#>