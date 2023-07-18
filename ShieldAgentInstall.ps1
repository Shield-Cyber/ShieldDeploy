$installDir = "C:\ShieldAgent"
$serviceName = "Shield Agent"
$binPath = $installDir + "\ShieldAgent\HopliteShield.Agent.exe"
$startType = "delayed-auto"
$scratchInstall = "Y"
$zipURL = "https://shield-agent.s3.amazonaws.com/ShieldAgent.zip"
$zipFilePath = $installDir + "\ShieldAgent.zip"
$subscriptionID = "XXX-XXX-XXX"
$appSettingsFilePath = $installDir + "\ShieldAgent\appsettings.json"
$agentCredntials = Get-Credential -Message "Domain User Creds: domain\username"
$agentUsername = $agentCredntials.UserName
$agentPassword = $agentCredntials.GetNetworkCredential().Password
$dotnetInstallURL = "https://dot.net/v1/dotnet-install.ps1"
$dotnetInstallPath = $installDir + "\dotnet-install.ps1 --Runtime windowsdesktop"

Write-Host "WARNING: This script will install the Shield Agent under the service name '$serviceName', if this service name already exists in your system it WILL be deleted. There will be a confirmation before this action occurs." -ForegroundColor Red
Start-Sleep -Seconds 5

if (Test-Path -Path $installDir -PathType Container) {
    Write-Host "Insallation Directory Exists."
    $scratchInstall = Read-Host "Would you like to reinstall? (Y/N)"
    $scratchInstall = $scratchInstall.ToUpper()
}

if ($scratchInstall -eq "Y") {
    Write-Host "Starting Installation..."

    # Check if Service Already Exists
    if (Get-Service -Name $serviceName -ErrorAction SilentlyContinue) {
        $deleteAgent = Read-Host "Delete Service $serviceName? (Y/N)"
        $deleteAgent = $deleteAgent.ToUpper()
        if ($deleteAgent -eq "Y") {
            sc.exe stop $serviceName
            sc.exe delete $serviceName
            Write-Host "If output above states 'Service Marked for Deletion' the system must be rebooted before continuing installation." -ForegroundColor Yellow
            Start-Sleep -Seconds 5
        }
    }

    # Check if Install Directory Already Exists
    if (Test-Path -Path $installDir -PathType Container) {
        $delInstall = Read-Host "Delete Install Directory $installDir? (Y/N)"
        $delInstall = $delInstall.ToUpper()
        if ($delInstall -eq "Y") {
            Remove-Item -Path $installDir -Recurse -Force
        }
    }

    # Create Install Directory
    New-Item -ItemType Directory -Path $installDir

    # Install Dependencies (DotNet)
    Write-Host "Downloading DotNet Installation Script..."
    $webClient = New-Object System.Net.WebClient
    $webClient.DownloadFile($dotnetInstallURL, $dotnetInstallPath)
    $webClient.Dispose()
    Write-Host "Installing DotNet Version 7.0.5..."
    & $dotnetInstallPath -Runtime dotnet -Version 7.0.5
    Write-Host "Dependency Installation Successful" -ForegroundColor Green

    # Install Dependencies (AD Powershell)
    try {
        Write-Host "Installing Windows Feature AD Powershell..."
        Install-WindowsFeature RSAT-AD-PowerShell
        Write-Host "Dependency Installation Successful" -ForegroundColor Green
    } catch {
        Write-Host "Dependency Installation Failed" -ForegroundColor Red
        Write-Host "Is this running on Windows Server?" -ForegroundColor Yellow
    }

    # Install Dependencies (Docker) Yet to be Figured Out - Only Installed if Using OpenVAS

    # Download Shield Agent ZIP File
    Write-Host "Downloading Agent ZIP File..."
    $webClient = New-Object System.Net.WebClient
    $webClient.DownloadFile($zipURL, $zipFilePath)
    $webClient.Dispose()

    # Expanding ZIP File
    Write-Host "Expanding Agent ZIP File..."
    Expand-Archive -Path $zipFilePath -DestinationPath (Split-Path -Path $zipFilePath -Parent)

    # Create Service
    sc.exe create $serviceName binpath= $binPath start= $startType obj= $agentUsername password= $agentPassword
    Write-Host "Confirm create service above did not fail. If failed it is likely that the Credentials enetered were incorrect." -ForegroundColor Yellow

    # Get Subscription ID
    $subscriptionID = Read-Host "Subscription ID"

    # Get Location Name
    $locationName = Read-Host "Location Name"

    # Nessus Config Info
    $nessusInfo = $null

    while ($nessusInfo -ne "Y" -and $nessusInfo -ne "N") {
        $nessusInfo = Read-Host "Are you using Nessus Pro? (Y/N)"
        $nessusInfo = $nessusInfo.ToUpper()
    }

    if ($nessusInfo -eq "Y") {
        Write-Host "You chose YES." -ForegroundColor Yellow
        $xapikey = Read-Host "Nessus X-API-Key"
        $useNessus = "true"
    } elseif ($nessusInfo -eq "N") {
        $useNessus = "false"
    }

    # Update appsettings.json Configuration File
    $jsonContent = Get-Content -Path $appSettingsFilePath -Raw
    $jsonObject = $jsonContent | ConvertFrom-Json
    $jsonObject.AppSettings.SubscriptionId = $subscriptionID
    $jsonObject.AppSettings.LocationName = $locationname
    $jsonObject.AppSettings.xApiKey = $xapikey
    $jsonObject.AppSettings.NessusEnabled = $useNessus
    $modifiedJsonContent = $jsonObject | ConvertTo-Json -Depth 4
    $modifiedJsonContent | Set-Content -Path $appSettingsFilePath

    sc.exe start $serviceName

}
Write-Host "Installation Complete."
