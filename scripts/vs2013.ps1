param (
  [switch]$Silent = $true
)


function Install-VisualStudio
{
    [CmdletBinding()]
    param (
        [string] $ImagePath,
        [string[]] $ArgumentList,
        [string] $InstallPath,
        [string] $ProductKey,
        [string] $AdminFile,
        [switch] $Silent = $true
    )
    Write-Verbose "Installing Visual Studio..."
    
    $filePath = Join-Path $ImagePath "vs_*.exe" -Resolve
    $argumentList = @("/NoRestart","/Log c:\VisualStudio_Install.log", "/Passive")
 
    if(![String]::IsNullOrEmpty($InstallPath))
    {
        $argumentList +="/CustomInstallPath ${InstallPath}"
    }
    if(![String]::IsNullOrEmpty($ProductKey))
    {
        $argumentList +="/ProductKey ${ProductKey}"
    }

    if(![String]::IsNullOrEmpty($AdminFile)){
        $argumentList += "/adminfile ${AdminFile}"
    } else {
        $argumentList += "/Full"
    }

    if($Silent){
        $argumentList += "/quiet"
    }
    
    Write-Progress -Activity "Installing Visual Studio" -Status "Install..."
    Start-Process -FilePath $filePath -ArgumentList $ArgumentList  -Wait 
    Write-Progress -Activity "Installing Visual Studio" -Completed
}
 
function Install-VisualStudioUpdate
{
    [CmdletBinding()]
    param (
        [string] $ImagePath
    )
    Write-Verbose "Install Visual Studio Update..."
    
    $filePath = Join-Path $ImagePath "VS2012.*.exe" -Resolve
 
    $argumentList = @("/Full","/Passive","/NoRestart","/NoWeb","/Log c:\VisualStudio_Update_Install.log")
 
    Write-Progress -Activity "Install Visual Studio Update" -Status "Install..."
    Start-Process -FilePath $filePath -ArgumentList $ArgumentList -Wait 
    Write-Progress -Activity "Install Visual Studio Update" -Completed
}



$destinationInstallPath = "c:\VisualStudio"
Write-Host "Destination install path for Visual Studio ${destinationInstallPath}"

Write-Host "Installing Visual Studio"
$isoPath = "C:\users\vagrant\visual_studio.iso"
$rc = Mount-DiskImage -PassThru -ImagePath $isoPath
$driveLetter = ($rc | Get-Volume).DriveLetter
Install-VisualStudio -ImagePath "${driveLetter}:" -InstallPath $destinationInstallPath -AdminFile A:\AdminDeployment.xml -Silent $Silent

Dismount-DiskImage -ImagePath $isoPath
#Remove-Item -Force -Path $isoPath
#Remove-Item -Force -Path c:\VisualStudio_Install*.log



Write-Host "Pinning Visual Studio to the TaskBar"
$shell = new-object -com "Shell.Application"
$dir = $shell.Namespace("${destinationInstallPath}\Common7\IDE")
$item = $dir.ParseName("devenv.exe")
$item.InvokeVerb('taskbarpin')


Write-Host "FIXING THE ALL CAPS MENU IN VISUAL STUDIO"
Set-ItemProperty -Path HKCU:\Software\Microsoft\VisualStudio\12.0\General -Name SuppressUppercaseConversion -Type DWord -Value 1


#Write-Host "Fixing the Visual Studio Start Screen"
New-ItemProperty -Force -Path HKCU:\Software\Microsoft\VisualStudio\12.0\General -Name OnEnvironmentStartup -Type DWord -Value 4
New-Item -Force -Path HKCU:\Software\Microsoft\VisualStudio\12.0\General\StartPage
New-ItemProperty -Force -Path HKCU:\Software\Microsoft\VisualStudio\12.0\General\StartPage -Name IsDownloadRefreshEnabled -Type DWord -Value 0
New-ItemProperty -Force -Path HKCU:\Software\Microsoft\VisualStudio\12.0\General\StartPage -Name OptIn -Type DWord -Value 0

#We register ReSharper in the box VagrantFile instead of here as it's
# a per user setting which comes from an environment variable.
