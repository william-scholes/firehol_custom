param(
    [string]$HostIP = "0.0.0.0",
    [int]$Port = 8080,
    [string]$RootPath = "C:\SharedFiles"  # Default directory to serve files from
)

#Usage:
# Run as admin or you need to use netsh to allow specific user to run on specific port
# You need to allow the port windows firewall if enabled
#.\WebServer.ps1 -HostIP "192.168.1.100" -Port 8080 -RootPath "C:\SharedFiles"

# Create directory if it doesn't exist
if (-not (Test-Path $RootPath)) {
    New-Item -ItemType Directory -Path $RootPath
    Write-Host "Created directory: $RootPath"
}

# Create HTTP listener
$Listener = New-Object System.Net.HttpListener
$Listener.Prefixes.Add("http://${HostIP}:${Port}/")

try {
    # Start the listener
    $Listener.Start()
    Write-Host "Web server started at http://${HostIP}:${Port}/"
    Write-Host "Serving files from: $((Resolve-Path $RootPath).Path)"

    while ($Listener.IsListening) {
        $Context = $Listener.GetContext()
        $Request = $Context.Request
        $Response = $Context.Response

        # Get requested file path
        $RequestedFile = $Request.Url.LocalPath.TrimStart('/')
        $FilePath = Join-Path $RootPath $RequestedFile

        if ($RequestedFile -eq '') {
            # Show directory listing for root
            $FileList = Get-ChildItem -Path $RootPath -Recurse | Where-Object { !$_.PSIsContainer }
            $Html = "<html><body><h1>Available Files:</h1><ul>"
            foreach ($File in $FileList) {
                $RelativePath = $File.FullName.Replace((Resolve-Path $RootPath).Path, '').TrimStart('\')
                $Html += "<li><a href='$RelativePath'>$RelativePath</a></li>"
            }
            $Html += "</ul></body></html>"
            $Buffer = [System.Text.Encoding]::UTF8.GetBytes($Html)
            $Response.ContentType = "text/html"
            $Response.ContentLength64 = $Buffer.Length
            $Response.OutputStream.Write($Buffer, 0, $Buffer.Length)
        }
        elseif (Test-Path $FilePath -PathType Leaf) {
            # Serve the requested file
            $Buffer = [System.IO.File]::ReadAllBytes($FilePath)
            $Response.ContentType = "application/octet-stream"
            $Response.ContentLength64 = $Buffer.Length
            $Response.OutputStream.Write($Buffer, 0, $Buffer.Length)
        }
        else {
            # Return 404 if file not found
            $Response.StatusCode = 404
            $Buffer = [System.Text.Encoding]::UTF8.GetBytes("404 - File Not Found")
            $Response.ContentLength64 = $Buffer.Length
            $Response.OutputStream.Write($Buffer, 0, $Buffer.Length)
        }

        $Response.Close()
    }
}
catch {
    Write-Host "An error occurred: $_"
}
finally {
    # Clean up
    if ($Listener) {
        $Listener.Stop()
        $Listener.Close()
    }
}


