$url = "https://api.github.com/meta"
$content = (Invoke-WebRequest -Uri $url -UseBasicParsing -ErrorAction Stop).Content
$json = $content | ConvertFrom-Json -Depth 10
$json.git