$installDir = "C:\ShieldAgent"

# @REM Make Dir
New-Item -ItemType Directory -Path $installDir


# Check if file already downloaded.
# @REM Download ZIP File
$url = "https://shield-agent.s3.amazonaws.com/ShieldAgent.zip"
$zipFilePath = $installDir + "\ShieldAgent.zip"

# $url = "http://example.com/path/to/file.zip"
# $outputPath = "C:\Path\to\Save\file.zip"

$webClient = New-Object System.Net.WebClient
$webClient.DownloadFile($url, $zipFilePath)

$webClient.Dispose()

# Invoke-WebRequest -Uri $url -OutFile $zipFilePath

# Check if File already unzipped.
# @REM Unzip File
Expand-Archive -Path $zipFilePath -DestinationPath (Split-Path -Path $zipFilePath -Parent)

# @REM Prompt Y/N for Nessus
$confirmation = $null

while ($confirmation -ne "Y" -and $confirmation -ne "N") {
    $confirmation = Read-Host "Are you using Nessus Pro? (Y/N)"
    $confirmation = $confirmation.ToUpper()
}

if ($confirmation -eq "Y") {
    Write-Host "You chose YES."
    # @REM Update AppSettings.json
}
else {
    Write-Host "You chose NO."
    # @REM Continue
}

# Check creds before doing thing and ask again if wrong.
# @REM Prompt Username/Password/Domain
$credential = Get-Credential
$agentUsername = $credential.UserName
$agentPassword = $credential.GetNetworkCredential().Password
$agentDomain = $credential.GetNetworkCredential().Domain
$domainUsername = $agentDomain + "\" + $agentUsername

# @REM Install Agent.exe as Service
$serviceName = "ShieldAgent2"
$binPath = $installDir + "\HopliteAgent\HopliteShield.Agent.exe"
$startType = "delayed-auto"

Write-Output "sc.exe create $serviceName binpath=$binPath start=$startType obj=.\$agentUsername password=$agentPassword"

# @REM sc.exe Command
sc.exe create $serviceName binpath=$binPath start=$startType obj=".\$agentUsername" password=$agentPassword

# Start-Process -NoNewWindow -Wait -FilePath "sc.exe" -ArgumentList $arguments

# @REM Start Service
# Start-Service -Name $serviceName

# @REM Confirm Service is Running
# @REM Prompt Reinstall Y/N