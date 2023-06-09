$installDir = "C:\ShieldAgent"

# @REM Make Dir
New-Item -ItemType Directory -Path $installDir

# @REM Download ZIP File
$url = "http://example.com/path/to/file.zip"
$zipFilePath = $installDir + "\agent.zip"

Invoke-WebRequest -Uri $url -OutFile $zipFilePath

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

# @REM Prompt Username/Password/Domain
$credential = Get-Credential
$agentUsername = $credential.UserName
$agentPassword = $credential.GetNetworkCredential().Password
$agentDomain = $credential.GetNetworkCredential().Domain
$domainUsername = ""$agentDomain"\"$agentUsername""

# @REM Install Agent.exe as Service
$serviceName = "Shield Agent"
$binPath = $installDir + "\app.exe"
$startType = "delayed-auto"

$arguments = "create "$serviceName" binpath= "$binPath" start= $startType obj= "$domainUsername" password= "$agentPassword""

# @REM sc.exe Command
Start-Process -NoNewWindow -Wait -FilePath "sc.exe" -ArgumentList $arguments

# @REM Start Service
Start-Service -Name $serviceName

# @REM Confirm Service is Running
# @REM Prompt Reinstall Y/N