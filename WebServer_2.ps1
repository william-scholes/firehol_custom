<#
######## READEME #########
To allow a non-admin user to run this script, in admin PowerShell allow the URL and user:
netsh http add urlacl url="$baseURL" user=<username>

#remove it if you want
netsh http delete urlacl url="$baseURL" user=<username>
######## READEME #########
#>

######## Variables ##########
$rootdir = ${PSScriptRoot}
$logFile = ".\WebServer_2.log"
$FilesFolder = "$rootdir\Files"

Out-File -InputObject "$(Get-Date -Format g) Script start" -FilePath $logFile -Append

#$GetBestHostAdaptor = (Get-NetAdapter | Where-Object { $_.Status -eq "Up"} | Sort-Object Speed | Select-Object -Last 1).InterfaceIndex
#$HostIP = (Get-NetIPAddress | where-object { $_.InterfaceIndex -eq $GetBestHostAdaptor -and $_.AddressFamily -eq "IPv4"})[0].IPAddress
$HostIP = (Find-NetRoute -RemoteIPAddress "1.1.1.1")[0].IPAddress #gets the local IP address with route to 1.1.1.1, usually the default route
$Port = 8080

$baseURL = "http://$($HostIP):$($Port)/"
######## Variables ##########

####### Load data from variables ######
Set-Location $rootdir

# Get the files
$AllowList = Get-Item "$FilesFolder\AllowList_Github_git.netset"
$Blacklist = Get-Item "$FilesFolder\BlockList_Firehol1_2_3_custom.netset"
####### Load data from variables ######


# Create an HttpListener object
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($baseURL)

# Function to stop the web server
function StopWebServer {
    Write-Host "Stopping the web server..."
    $listener.Stop()
    if (!!($error)) {Out-File -InputObject $error -FilePath $logFile -Append}
    Out-File -InputObject "$(Get-Date -Format g) Script end" -FilePath $logFile -Append
    exit
}

# Start listening for incoming requests
$listener.Start()

Write-Host "Server is listening at $baseURL"
Write-Host "Server running from $rootdir"
Write-Host "Files served from $FilesFolder"

if (!!($error)) {Out-File -InputObject $error -FilePath $logFile -Append}

# Handle incoming requests
while ($listener.IsListening) {

    $context = $listener.GetContext() # Wait for a request to come in
    $request = $context.Request
    $response = $context.Response

    # Handle CORS preflight request (OPTIONS)
    if ($request.HttpMethod -eq "OPTIONS") {
        $response.Headers.Add("Access-Control-Allow-Origin", "*")
        $response.Headers.Add("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        $response.Headers.Add("Access-Control-Allow-Headers", "Content-Type, Authorization")
        $response.StatusCode = 200
        $response.Close()
        continue
    }

    # Set CORS headers to allow cross-origin requests
    $response.Headers.Add("Access-Control-Allow-Origin", "*")

    # Serve Allowlist file
    if ($request.RawUrl -eq "/AllowList_Github_git.netset") {
        $contentCSV = Get-Content $AllowList -Raw
        $bufferCSV = [System.Text.Encoding]::UTF8.GetBytes($contentCSV)
        $responseCSV = $context.Response
        $responseCSV.ContentLength64 = $bufferCSV.Length
        $responseCSV.ContentType = "text/plain"
        $responseCSV.OutputStream.Write($bufferCSV, 0, $bufferCSV.Length)
        $responseCSV.Close()
    }
	
    # Serve Blacklist file
    if ($request.RawUrl -eq "/BlockList_Firehol1_2_3_custom.netset") {
        $contentPowerGainCSV = Get-Content $Blacklist -Raw
        $bufferPGCSV = [System.Text.Encoding]::UTF8.GetBytes($contentPowerGainCSV)
        $responsePGCSV = $context.Response
        $responsePGCSV.ContentLength64 = $bufferPGCSV.Length
        $responsePGCSV.ContentType = "text/plain"
        $responsePGCSV.OutputStream.Write($bufferPGCSV, 0, $bufferPGCSV.Length)
        $responsePGCSV.Close()
    }



    # Loop to continuously check for Ctrl+C
    # Check if Ctrl+C has been pressed
    if ([console]::KeyAvailable) {
        $key = [console]::ReadKey($true)
        if (($key.Modifiers -band [consolemodifiers]"Control") -and ($key.Key -eq "C")) {
            StopWebServer
        }
    }
}

# Stop the listener when done
StopWebServer

