function Get-OpenShiftProjectsWithNumbers {
    $projectsOutput = & oc.exe get projects -o jsonpath="{range .items[*]}{.metadata.name}{'\n'}{end}" 2>&1

    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to retrieve projects: $projectsOutput" -ForegroundColor Red
        return @()
    }

    $projects = $projectsOutput -split "`n" | Where-Object { $_ -ne "" }

    $projectsWithNumbers = @()
    for ($i = 0; $i -lt $projects.Count; $i++) {
        $projectsWithNumbers += ("{0} {1}" -f ($i + 1), $projects[$i])
    }

    return $projectsWithNumbers
}

function Set-OpenShiftProject {
    param (
        [string]$ProjectName
    )
    $switchOutput = & oc.exe project $ProjectName 2>&1
    if ($switchOutput -match "Now using project") {
        return "Switched to project '$ProjectName'."
    } else {
        return "Failed to switch to project '$ProjectName': $switchOutput"
    }
}
Export-ModuleMember -Function Get-OpenShiftProjectsWithNumbers, Set-OpenShiftProject
