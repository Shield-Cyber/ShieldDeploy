$installDir = "C:\ShieldAgent"

$resetScratch = $null

# Make Dir If Dir Exists, ask to reinstall.
if (Test-Path $installDir -PathType Container) {
    Write-Output "Install Directory exists. Would you like to reinstall?"
    while ($resetScratch -ne "Y" -and $resetScratch -ne "N") {
        $resetScratch = Read-Host "Reinstall? (Y/N)"
        $resetScratch = $resetScratch.ToUpper()
    }
} else {
    Write-Output "Install Directory does not exist."
    New-Item -ItemType Directory -Path $installDir
}
if ($resetScratch -eq "Y") {
    Write-Host "You chose YES."
    Remove-Item -Path $installDir -Recurse -Force
    New-Item -ItemType Directory -Path $installDir
}
else {
    Write-Host "You chose NO."
}

# Download ZIP File
$url = "https://shield-agent.s3.amazonaws.com/ShieldAgent.zip"
$zipFilePath = $installDir + "\ShieldAgent.zip"

if (Test-Path $zipFilePath -PathType Leaf) {
    Write-Output "Zip file exists. Delete this directory if you wish to reinstall. $installDir"
} else {
    Write-Output "Zip file does not exist. Downloading / Unzipping."
    $webClient = New-Object System.Net.WebClient
    $webClient.DownloadFile($url, $zipFilePath)

    $webClient.Dispose()

    # Unzip File
    Expand-Archive -Path $zipFilePath -DestinationPath (Split-Path -Path $zipFilePath -Parent)
}

# Prompt Y/N for Nessus
$confirmation = $null

while ($confirmation -ne "Y" -and $confirmation -ne "N") {
    $confirmation = Read-Host "Are you using Nessus Pro? (Y/N)"
    $confirmation = $confirmation.ToUpper()
}

if ($confirmation -eq "Y") {
    Write-Host "You chose YES."
    # Update AppSettings.json
}
else {
    Write-Host "You chose NO."
}

# Prompt Username/Password/Domain
$credential = Get-Credential
$agentUsername = $credential.UserName
$agentPassword = $credential.GetNetworkCredential().Password

Write-Host $agentUsername

# Install Agent.exe as Service
$serviceName = "ShieldAgent"
$binPath = $installDir + "\HopliteAgent\HopliteShield.Agent.exe"
$startType = "delayed-auto"

$completed = $false

while (-not $completed) {
    try {        
        sc.exe delete $serviceName

        sc.exe create $serviceName binpath= $binPath start= $startType obj= $agentUsername password= $agentPassword

        $completed = $true
    }
    catch {
        Write-Output "Failed to authenticate. Please check your credentials."

        $credential = Get-Credential
        $agentUsername = $credential.UserName
        $agentPassword = $credential.GetNetworkCredential().Password
    }
}

# Start Service
Start-Service -Name $serviceName