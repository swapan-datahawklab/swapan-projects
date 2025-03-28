<#
.SYNOPSIS
    Manages WSL distributions with three options: Create, Delete, and Re-create.

.DESCRIPTION
    This script will:
      - Check that WSL is available.
      - Present a menu with three options:
          1. Create a new distribution.
          2. Delete an existing distribution.
          3. Re-create an existing distribution (delete then import again).
      - For creation/re-creation, the user is prompted for:
          • Distribution name (or, in re-create, the selected distro’s name is used)
          • Tarball URL (to download a Linux rootfs)
          • Installation directory (with a default value)
          • Desired WSL version (default is 2)
      - The tarball is downloaded, the distro imported via `wsl --import`, and its version set.

.NOTES
    Run PowerShell as an administrator.
    Unregistering (deleting) a distribution deletes its data permanently.
#>

# Function: Check if WSL is available
function Test-WSLInstallation {
    if (-not (Get-Command wsl.exe -ErrorAction SilentlyContinue)) {
        Write-Error "WSL (wsl.exe) is not installed or not in PATH. Please install WSL and try again."
        exit 1
    }
}

Test-WSLInstallation

# Function: Retrieve list of installed WSL distributions
# Modified Get-WSLDistros function
function Get-WSLDistros {
    Write-Host "Fetching list of WSL distributions..."
    $wslListRaw = wsl -l -v | Select-Object -Skip 1 | ForEach-Object { $_.Trim() }
    $distros = @()
    foreach ($line in $wslListRaw) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        $columns = $line -split "\s+"
        if ($columns[0] -eq "*") {
            $columns = $columns[1..($columns.Count - 1)]
        }
        if ($columns.Count -ge 2) {
            $distros += [PSCustomObject]@{
                Name    = $columns[0]
                State   = $columns[1]
                Version = ($columns.Count -ge 3) ? $columns[2] : 2
            }
        }
    }
    return $distros
}

# Function: Create a new WSL distribution
function New-WSLDistro {
    Write-Host "`n=== Create WSL Distribution ==="
    $name = Read-Host "Enter the new distribution name"
    if ([string]::IsNullOrWhiteSpace($name)) {
        Write-Error "Distribution name cannot be empty."
        return
    }
    $tarballUrl = Read-Host "Enter the tarball URL to import the distribution (e.g., https://aka.ms/wsl-ubuntu-2004)"
    if ([string]::IsNullOrWhiteSpace($tarballUrl)) {
        Write-Error "Tarball URL cannot be empty."
        return
    }
    $defaultInstallDir = "$env:LOCALAPPDATA\WSL\$name"
    $installLocation = Read-Host "Enter the installation directory for '$name' (default: $defaultInstallDir)"
    if ([string]::IsNullOrWhiteSpace($installLocation)) {
        $installLocation = $defaultInstallDir
    }
    $wslVersionInput = Read-Host "Enter the WSL version to set for '$name' (default is 2)"
    if ([string]::IsNullOrWhiteSpace($wslVersionInput)) {
        $wslVersion = 2
    }
    else {
        if (-not [int]::TryParse($wslVersionInput, [ref]$null)) {
            Write-Error "Invalid WSL version entered."
            return
        }
        $wslVersion = [int]$wslVersionInput
    }

    # Create installation directory if it doesn't exist
    if (-not (Test-Path -Path $installLocation)) {
        Write-Host "Creating installation directory at '$installLocation'..."
        New-Item -ItemType Directory -Path $installLocation | Out-Null
    }

    # Download tarball to a temporary file
    $tarballFile = Join-Path -Path $env:TEMP -ChildPath "$name.tar.gz"
    if (Test-Path $tarballFile) {
        Write-Host "Deleting existing tarball file at '$tarballFile'..."
        Remove-Item $tarballFile -Force
    }
    Write-Host "Downloading tarball from '$tarballUrl' to '$tarballFile'..."
    try {
        Invoke-WebRequest -Uri $tarballUrl -OutFile $tarballFile -UseBasicParsing
        Write-Host "Tarball downloaded successfully."
    }
    catch {
        Write-Error "Failed to download tarball from '$tarballUrl'."
        return
    }

    # Import the distribution using the downloaded tarball
    Write-Host "Importing distribution '$name' into WSL..."
    try {
        wsl --import $name $installLocation $tarballFile
        Write-Host "Import of '$name' successful."
    }
    catch {
        Write-Error "Failed to import the distribution '$name'."
        return
    }

    # Set the desired WSL version
    Write-Host "Setting WSL version for '$name' to $wslVersion..."
    try {
        wsl --set-version $name $wslVersion
        Write-Host "WSL version set successfully."
    }
    catch {
        Write-Warning "Failed to set WSL version for '$name'."
    }
    Write-Host "`nOperation completed: Distribution '$name' has been created successfully."
}

# Function: Delete an existing WSL distribution
function Remove-WSLDistro {
    Write-Host "`n=== Delete WSL Distribution ==="
    $distros = Get-WSLDistros
    if ($distros.Count -eq 0) {
        Write-Host "No WSL distributions found."
        return
    }
    Write-Host "`nAvailable WSL Distributions:"
    for ($i = 0; $i -lt $distros.Count; $i++) {
        Write-Host ("{0}. {1} - State: {2}, Version: {3}" -f ($i + 1), $distros[$i].Name, $distros[$i].State, $distros[$i].Version)
    }
    $choice = Read-Host "`nEnter the number of the distribution you want to delete"
    if (-not [int]::TryParse($choice, [ref]$null)) {
        Write-Error "Invalid input. Please enter a valid number."
        return
    }
    $index = [int]$choice - 1
    if ($index -lt 0 -or $index -ge $distros.Count) {
        Write-Error "Selection out of range."
        return
    }
    $selectedDistro = $distros[$index]
    Write-Host "`nYou selected: $($selectedDistro.Name) - State: $($selectedDistro.State), Version: $($selectedDistro.Version)"
    $confirm = Read-Host "Are you sure you want to unregister (delete) the distribution '$($selectedDistro.Name)'? (Y/N)"
    if ($confirm -notin @("Y", "y")) {
        Write-Host "Operation cancelled."
        return
    }
    Write-Host "Unregistering distribution '$($selectedDistro.Name)'..."
    try {
        wsl --unregister $selectedDistro.Name
        Write-Host "Distribution '$($selectedDistro.Name)' has been unregistered successfully."
    }
    catch {
        Write-Error "Failed to unregister distribution '$($selectedDistro.Name)'."
    }
}

# Function: Re-create an existing WSL distribution (delete then create)
function Reset-WSLDistro {
    Write-Host "`n=== Re-create WSL Distribution ==="
    $distros = Get-WSLDistros
    if ($distros.Count -eq 0) {
        Write-Host "No WSL distributions found."
        return
    }
    Write-Host "`nAvailable WSL Distributions:"
    for ($i = 0; $i -lt $distros.Count; $i++) {
        Write-Host ("{0}. {1} - State: {2}, Version: {3}" -f ($i + 1), $distros[$i].Name, $distros[$i].State, $distros[$i].Version)
    }
    $choice = Read-Host "`nEnter the number of the distribution you want to re-create"
    if (-not [int]::TryParse($choice, [ref]$null)) {
        Write-Error "Invalid input. Please enter a valid number."
        return
    }
    $index = [int]$choice - 1
    if ($index -lt 0 -or $index -ge $distros.Count) {
        Write-Error "Selection out of range."
        return
    }
    $selectedDistro = $distros[$index]
    Write-Host "`nYou selected: $($selectedDistro.Name) - State: $($selectedDistro.State), Version: $($selectedDistro.Version)"
    $confirm = Read-Host "Are you sure you want to unregister (delete) the distribution '$($selectedDistro.Name)'? (Y/N)"
    if ($confirm -notin @("Y", "y")) {
        Write-Host "Operation cancelled."
        return
    }
    Write-Host "Unregistering distribution '$($selectedDistro.Name)'..."
    try {
        wsl --unregister $selectedDistro.Name
        Write-Host "Distribution '$($selectedDistro.Name)' has been unregistered successfully."
    }
    catch {
        Write-Error "Failed to unregister distribution '$($selectedDistro.Name)'."
        return
    }

    # Re-create process
    $tarballUrl = Read-Host "Enter the tarball URL to import the distribution (e.g., https://aka.ms/wsl-ubuntu-2004)"
    if ([string]::IsNullOrWhiteSpace($tarballUrl)) {
        Write-Error "Tarball URL cannot be empty."
        return
    }
    $defaultInstallDir = "$env:LOCALAPPDATA\WSL\$($selectedDistro.Name)"
    $installLocation = Read-Host "Enter the installation directory for '$($selectedDistro.Name)' (default: $defaultInstallDir)"
    if ([string]::IsNullOrWhiteSpace($installLocation)) {
        $installLocation = $defaultInstallDir
    }
    $wslVersionInput = Read-Host "Enter the WSL version to set for '$($selectedDistro.Name)' (default is 2)"
    if ([string]::IsNullOrWhiteSpace($wslVersionInput)) {
        $wslVersion = 2
    }
    else {
        if (-not [int]::TryParse($wslVersionInput, [ref]$null)) {
            Write-Error "Invalid WSL version entered."
            return
        }
        $wslVersion = [int]$wslVersionInput
    }
    if (-not (Test-Path -Path $installLocation)) {
        Write-Host "Creating installation directory at '$installLocation'..."
        New-Item -ItemType Directory -Path $installLocation | Out-Null
    }
    $tarballFile = Join-Path -Path $env:TEMP -ChildPath "$($selectedDistro.Name).tar.gz"
    if (Test-Path $tarballFile) {
        Write-Host "Deleting existing tarball file at '$tarballFile'..."
        Remove-Item $tarballFile -Force
    }
    Write-Host "Downloading tarball from '$tarballUrl' to '$tarballFile'..."
    try {
        Invoke-WebRequest -Uri $tarballUrl -OutFile $tarballFile -UseBasicParsing
        Write-Host "Tarball downloaded successfully."
    }
    catch {
        Write-Error "Failed to download tarball from '$tarballUrl'."
        return
    }
    Write-Host "Importing distribution '$($selectedDistro.Name)' into WSL..."
    try {
        wsl --import $selectedDistro.Name $installLocation $tarballFile
        Write-Host "Import of '$($selectedDistro.Name)' successful."
    }
    catch {
        Write-Error "Failed to import the distribution '$($selectedDistro.Name)'."
        return
    }
    Write-Host "Setting WSL version for '$($selectedDistro.Name)' to $wslVersion..."
    try {
        wsl --set-version $selectedDistro.Name $wslVersion
        Write-Host "WSL version set successfully."
    }
    catch {
        Write-Warning "Failed to set WSL version for '$($selectedDistro.Name)'."
    }
    Write-Host "`nOperation completed: Distribution '$($selectedDistro.Name)' has been re-created successfully."
}

# Main Menu
Write-Host "=== WSL Distribution Manager ==="
Write-Host "1. Create a new distribution"
Write-Host "2. Delete an existing distribution"
Write-Host "3. Re-create an existing distribution"
$option = Read-Host "Enter the number of your choice"

switch ($option) {
    "1" { New-WSLDistro }
    "2" { Remove-WSLDistro }
    "3" { Reset-WSLDistro }
    default { Write-Host "Invalid option selected. Exiting." }
}
