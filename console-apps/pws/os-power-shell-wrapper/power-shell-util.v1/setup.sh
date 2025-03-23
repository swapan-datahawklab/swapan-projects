#!/bin/bash

# Define the base project directory
BASE_DIR="./OpenShiftProject"

# Define module directories
MODULES_DIR="$BASE_DIR/Modules"
MODES_DIR="$BASE_DIR/Modes"

# Create directory structure
mkdir -p "$MODULES_DIR"
mkdir -p "$MODES_DIR"

# Create module files
cat > "$MODULES_DIR/CheckEnvironment.psm1" << 'EOL'
function Test-OcExecutable {
    if (-not (Get-Command "oc.exe" -ErrorAction SilentlyContinue)) {
        throw "The 'oc.exe' CLI tool is not installed or not available in the system PATH."
    }
}
Export-ModuleMember -Function Test-OcExecutable
EOL

cat > "$MODULES_DIR/OpenShiftLogin.psm1" << 'EOL'
function Connect-OpenShiftCluster {
    param (
        [string]$ClusterName,
        [string]$Username,
        [string]$Password
    )

    $BaseUrl = "https://api.openshift.{0}.example.com:6443"
    $OpenShiftUrl = $BaseUrl -f $ClusterName.ToLower()

    $loginResult = & oc.exe login $OpenShiftUrl --username=$Username --password=$Password --insecure-skip-tls-verify 2>&1

    if ($loginResult -match "Login successful") {
        return "Login successful to $ClusterName as $Username."
    } else {
        throw "Login failed: $loginResult"
    }
}
Export-ModuleMember -Function Connect-OpenShiftCluster
EOL

cat > "$MODULES_DIR/ProjectManagement.psm1" << 'EOL'
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
EOL

cat > "$MODES_DIR/ConsoleMode.psm1" << 'EOL'
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
EOL

cat > "$MODES_DIR/GuiMode.psm1" << 'EOL'
function Show-OpenShiftGui {
    Add-Type -AssemblyName PresentationCore, PresentationFramework

    $xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="OpenShift Login and Projects" Height="450" Width="600">
    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto" />
            <RowDefinition Height="Auto" />
            <RowDefinition Height="Auto" />
            <RowDefinition Height="Auto" />
            <RowDefinition Height="*" />
            <RowDefinition Height="Auto" />
        </Grid.RowDefinitions>
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="Auto" />
            <ColumnDefinition Width="*" />
        </Grid.ColumnDefinitions>

        <TextBlock Grid.Row="0" Grid.Column="0" Margin="5" VerticalAlignment="Center">Cluster Name:</TextBlock>
        <ComboBox x:Name="ClusterComboBox" Grid.Row="0" Grid.Column="1" Margin="5" />

        <TextBlock Grid.Row="1" Grid.Column="0" Margin="5" VerticalAlignment="Center">Username:</TextBlock>
        <TextBox x:Name="UsernameTextBox" Grid.Row="1" Grid.Column="1" Margin="5" />

        <TextBlock Grid.Row="2" Grid.Column="0" Margin="5" VerticalAlignment="Center">Password:</TextBlock>
        <PasswordBox x:Name="PasswordBox" Grid.Row="2" Grid.Column="1" Margin="5" />

        <ListBox x:Name="ProjectsListBox" Grid.Row="3" Grid.ColumnSpan="2" Margin="5" Visibility="Collapsed" />

        <StackPanel Orientation="Horizontal" Grid.Row="5" Grid.ColumnSpan="2" HorizontalAlignment="Center" Margin="5">
            <Button x:Name="LoginButton" Content="Login" Width="100" Margin="5" />
            <Button x:Name="SwitchProjectButton" Content="Switch Project" Width="150" Margin="5" IsEnabled="False" />
            <Button x:Name="CancelButton" Content="Cancel" Width="100" Margin="5" />
        </StackPanel>
    </Grid>
</Window>
"@

    $reader = New-Object System.Xml.XmlNodeReader([xml]$xaml)
    $window = [Windows.Markup.XamlReader]::Load($reader)

    $window.ShowDialog() | Out-Null
}
Export-ModuleMember -Function Show-OpenShiftGui
EOL

# Create the main script file
cat > "$BASE_DIR/Main.ps1" << 'EOL'
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
EOL

echo "Project structure created successfully in $BASE_DIR."
