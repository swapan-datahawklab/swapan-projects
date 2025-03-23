# Import modules
Import-Module -Name "$PSScriptRoot/Modules/CheckEnvironment.psm1"
Import-Module -Name "$PSScriptRoot/Modules/OpenShiftLogin.psm1"
Import-Module -Name "$PSScriptRoot/Modules/ProjectManagement.psm1"
Import-Module -Name "$PSScriptRoot/Modes/ConsoleMode.psm1"
Import-Module -Name "$PSScriptRoot/Modes/GuiMode.psm1"

if ($args.Count -eq 0) {
    Show-OpenShiftGui
} else {
    if ($args.Count -lt 3) {
        Write-Host "Usage: .\Main.ps1 <ClusterName> <Username> <Password>" -ForegroundColor Yellow
        exit 1
    }

    $ClusterName = $args[0]
    $Username = $args[1]
    $Password = $args[2]

    Invoke-OpenShiftConsole -ClusterName $ClusterName -Username $Username -Password $Password
}
