<#
######## READEME #########
#To allow a non-admin user to run this script, in admin PowerShell allow the URL and user:
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

    # Handle CORS preflight request (OPTIONS) - I think this was only required when using HTTPS, this http server is not using HTTPS but I left this in case it is needed later
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
        $contentA = Get-Content $AllowList -Raw
        $bufferA = [System.Text.Encoding]::UTF8.GetBytes($contentA)
        $responseA = $context.Response
        $responseA.ContentLength64 = $bufferA.Length
        $responseA.ContentType = "text/plain"
        $responseA.OutputStream.Write($bufferA, 0, $bufferA.Length)
        $responseA.Close()
    }
	
    # Serve Blacklist file
    if ($request.RawUrl -eq "/BlockList_Firehol1_2_3_custom.netset") {
        $contentB = Get-Content $Blacklist -Raw
        $bufferB = [System.Text.Encoding]::UTF8.GetBytes($contentB)
        $responseB = $context.Response
        $responseB.ContentLength64 = $bufferB.Length
        $responseB.ContentType = "text/plain"
        $responseB.OutputStream.Write($bufferB, 0, $bufferB.Length)
        $responseB.Close()
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

