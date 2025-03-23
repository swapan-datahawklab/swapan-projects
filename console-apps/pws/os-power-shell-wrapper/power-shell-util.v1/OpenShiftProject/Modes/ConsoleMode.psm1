function Invoke-OpenShiftConsole {
    param (
        [string]$ClusterName,
        [string]$Username,
        [string]$Password
    )

    try {
        Test-OcExecutable
        $loginMessage = Connect-OpenShiftCluster -ClusterName $ClusterName -Username $Username -Password $Password
        Write-Host $loginMessage -ForegroundColor Green

        $projects = Get-OpenShiftProjectsWithNumbers
        if (-not $projects) {
            Write-Host "No projects found!" -ForegroundColor Yellow
            return
        }

        Write-Host "`nAvailable Namespaces:" -ForegroundColor Cyan
        $projects | ForEach-Object { Write-Host $_ }

        Write-Host "`nEnter the number corresponding to the namespace you want to switch to:"
        $selectedNumber = Read-Host "Namespace Number"

        if ($selectedNumber -match '^\d+$') {
            $index = [int]$selectedNumber - 1
            if ($index -ge 0 -and $index -lt $projects.Count) {
                $selectedNamespace = ($projects[$index] -split " ", 2)[1]
                $switchMessage = Set-OpenShiftProject -ProjectName $selectedNamespace
                Write-Host $switchMessage -ForegroundColor Green
            } else {
                Write-Host "Invalid selection. Please enter a valid number from the list." -ForegroundColor Red
            }
        } else {
            Write-Host "Invalid input. Please enter a number." -ForegroundColor Red
        }
    } catch {
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
}
Export-ModuleMember -Function Invoke-OpenShiftConsole
