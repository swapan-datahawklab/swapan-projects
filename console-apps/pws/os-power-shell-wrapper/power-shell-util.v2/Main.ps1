# Import modules
# Import required .NET assemblies
Add-Type -AssemblyName PresentationCore, PresentationFramework

function Test-OcExecutable {
    if (-not (Get-Command "oc.exe" -ErrorAction SilentlyContinue)) {
        throw "The 'oc.exe' CLI tool is not installed or not available in the system PATH."
    }
}

function Connect-OpenShiftClusterWithPassword {
    param (
        [string]$ClusterName,
        [string]$Username,
        [System.Security.SecureString]$MyPass
    )

    $BaseUrl = "https://{0}"
    $OpenShiftUrl = $BaseUrl -f $ClusterName.ToLower()

    $passwordPlainText = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($MyPass))
    $loginResult = & oc.exe login $OpenShiftUrl --username=$Username --password=$passwordPlainText --insecure-skip-tls-verify 2>&1
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR([Runtime.InteropServices.Marshal]::SecureStringToBSTR($MyPass))

    if ($loginResult -match "Logged into" -or $loginResult -match "Already on project") {
        return "Login successful to $ClusterName as $Username."
    } else {
        throw "Login failed: $loginResult"
    }
}

function Connect-OpenShiftClusterWithToken {
    param (
        [string]$ClusterName,
        [string]$Token
    )

    $BaseUrl = "https://{0}"
    $OpenShiftUrl = $BaseUrl -f $ClusterName.ToLower()

    $loginResult = & oc.exe login --token=$Token --server=$OpenShiftUrl 2>&1
    Write-Host $loginResult

    if ($loginResult -match "Logged into") {            
        return "Login successful to $ClusterName."
    } else {
        throw "Login failed: $loginResult"
    }
}

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

function Invoke-OpenShiftConsole {
    param (
        [string]$ClusterName,
        [string]$Username,
        [System.Security.SecureString]$MyPass,
        [string]$Token
    )

    try {
        Test-OcExecutable
        if ($MyPass) {
            $loginMessage = Connect-OpenShiftClusterWithPassword -ClusterName $ClusterName -Username $Username -MyPass $MyPass
        } elseif ($Token) {
            $loginMessage = Connect-OpenShiftClusterWithToken -ClusterName $ClusterName -Token $Token
        } else {
            throw "Either Password or Token must be provided."
        }
        Write-Host $loginMessage -ForegroundColor Green

        $selectedNamespace = Select-OpenShiftNamespace
        Switch-OpenShiftProject -Namespace $selectedNamespace
    } catch {
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
}

function Select-OpenShiftNamespace {
    $projects = Get-OpenShiftProjectsWithNumbers
    if (-not $projects) {
        Write-Host "No projects found!" -ForegroundColor Yellow
        return $null
    }

    Write-Host "`nAvailable Namespaces:" -ForegroundColor Cyan
    $projects | ForEach-Object { Write-Host $_ }

    Write-Host "`nEnter the number corresponding to the namespace you want to switch to:"
    $selectedNumber = Read-Host "Namespace Number"

    if ($selectedNumber -match '^\d+$') {
        $index = [int]$selectedNumber - 1
        if ($index -ge 0 -and $index -lt $projects.Count) {
            return ($projects[$index] -split " ", 2)[1]
        } else {
            Write-Host "Invalid selection. Please enter a valid number from the list." -ForegroundColor Red
        }
    } else {
        Write-Host "Invalid input. Please enter a number." -ForegroundColor Red
    }
    return $null
}

function Switch-OpenShiftProject {
    param (
        [string]$Namespace
    )
    
    if ($Namespace) {
        $switchMessage = Set-OpenShiftProject -ProjectName $Namespace
        Write-Host $switchMessage -ForegroundColor Green
    }
}

function Show-OpenShiftGui {

$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="OpenShift Login and Projects" Height="400" Width="600">
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
            <ColumnDefinition Width="Auto" />
        </Grid.ColumnDefinitions>

        <!-- Labels and Inputs -->
        <TextBlock Grid.Row="0" Grid.Column="0" Margin="5" VerticalAlignment="Center" HorizontalAlignment="Left">Cluster Name:</TextBlock>
        <ComboBox x:Name="ClusterComboBox" Grid.Row="0" Grid.Column="1" Margin="5" Width="200" />

        <TextBlock Grid.Row="1" Grid.Column="0" Margin="5" VerticalAlignment="Center" HorizontalAlignment="Left">Username:</TextBlock>
        <TextBox x:Name="UsernameTextBox" Grid.Row="1" Grid.Column="1" Margin="5" Width="200" />

        <TextBlock Grid.Row="2" Grid.Column="0" Margin="5" VerticalAlignment="Center" HorizontalAlignment="Left">Password:</TextBlock>
        <PasswordBox x:Name="PasswordBox" Grid.Row="2" Grid.Column="1" Margin="5" Width="200" IsEnabled="False" />
        <CheckBox x:Name="PasswordCheckBox" Grid.Row="2" Grid.Column="2" Content="Enable" Margin="5" VerticalAlignment="Center" />

        <TextBlock Grid.Row="3" Grid.Column="0" Margin="5" VerticalAlignment="Center" HorizontalAlignment="Left">Token:</TextBlock>
        <TextBox x:Name="TokenBox" Grid.Row="3" Grid.Column="1" Margin="5" Width="200" IsEnabled="False" />
        <CheckBox x:Name="TokenCheckBox" Grid.Row="3" Grid.Column="2" Content="Enable" Margin="5" VerticalAlignment="Center" />

        <!-- Project List (initially hidden) -->
        <ListBox x:Name="ProjectsListBox" Grid.Row="4" Grid.ColumnSpan="3" Margin="5" Visibility="Collapsed" />

        <!-- Buttons -->
        <StackPanel Orientation="Horizontal" Grid.Row="5" Grid.ColumnSpan="3" HorizontalAlignment="Center" Margin="5">
            <Button x:Name="LoginButton" Content="Login" Width="100" Margin="5" />
            <Button x:Name="SwitchProjectButton" Content="Switch Project" Width="150" Margin="5" IsEnabled="False" />
            <Button x:Name="CancelButton" Content="Cancel" Width="100" Margin="5" />
        </StackPanel>
    </Grid>
</Window>
"@
    
    $reader = New-Object System.Xml.XmlNodeReader([xml]$xaml)
    $window = [Windows.Markup.XamlReader]::Load($reader)
    
    $clusterComboBox = $window.FindName("ClusterComboBox")
    $usernameTextBox = $window.FindName("UsernameTextBox")
    $passwordBox = $window.FindName("PasswordBox")
    $passwordCheckBox = $window.FindName("PasswordCheckBox")
    $tokenBox = $window.FindName("TokenBox")
    $tokenCheckBox = $window.FindName("TokenCheckBox")
    $projectsListBox = $window.FindName("ProjectsListBox")
    $loginButton = $window.FindName("LoginButton")
    $switchProjectButton = $window.FindName("SwitchProjectButton")
    $cancelButton = $window.FindName("CancelButton")

    function Get-ClustersFromFile {
        param ([string]$FilePath)

        if (-not (Test-Path $FilePath)) {
            throw "Cluster property file not found: $FilePath"
        }

        $clusters = @{}
        foreach ($line in Get-Content $FilePath) {
            $key = $line.Trim()
            if ($key) {
            $clusters[$key] = $key
            }
        }
        return $clusters
    }

    # Path to the cluster property file
    $propertyFilePath = "C:\Users\swapa\OneDrive\Desktop\stuff\OpenShiftProject\cluster.properties"
    try {
        $clusters = Get-ClustersFromFile -FilePath $propertyFilePath
        foreach ($cluster in $clusters.Keys) {
            $comboBoxItem = New-Object System.Windows.Controls.ComboBoxItem
            $comboBoxItem.Content = $cluster
            $comboBoxItem.Tag = $clusters[$cluster]
            $clusterComboBox.Items.Add($comboBoxItem)
        }
    } catch {
        [System.Windows.MessageBox]::Show($_.Exception.Message, "Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
        return
    }

    $passwordCheckBox.Add_Checked({
        $passwordBox.IsEnabled = $true
        $tokenBox.IsEnabled = $false
        $tokenBox.Clear()
        $tokenCheckBox.IsChecked = $false
    })

    $passwordCheckBox.Add_Unchecked({
        $passwordBox.IsEnabled = $false
        $passwordBox.Clear()
    })

    $tokenCheckBox.Add_Checked({
        $tokenBox.IsEnabled = $true
        $passwordBox.IsEnabled = $false
        $passwordBox.Clear()
        $passwordCheckBox.IsChecked = $false
    })

    $tokenCheckBox.Add_Unchecked({
        $tokenBox.IsEnabled = $false
        $tokenBox.Clear()
    })

    $loginButton.Add_Click({
        try {
            $selectedCluster = $clusterComboBox.SelectedItem.Content
            $username = $usernameTextBox.Text
            $password = $passwordBox.Password
            $token = $tokenBox.Text

            if (-not $selectedCluster -or (-not $username -and -not $token) -or (-not $password -and -not $token)) {
                [System.Windows.MessageBox]::Show("All fields are required!", "Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
                return
            }

            if ($password) {
                $loginMessage = Connect-OpenShiftClusterWithPassword -ClusterName $selectedCluster -Username $username -MyPass $password
            } elseif ($token) {
                $loginMessage = Connect-OpenShiftClusterWithToken -ClusterName $selectedCluster -Token $token
            } else {
                throw "Either Password or Token must be provided."
            }

            [System.Windows.MessageBox]::Show($loginMessage, "Success", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)

            $projectsListBox.Items.Clear()
            $projects = Get-OpenShiftProjectsWithNumbers
            foreach ($project in $projects) {
                $projectsListBox.Items.Add($project)
            }

            $projectsListBox.Visibility = "Visible"
            $switchProjectButton.IsEnabled = $true
        } catch {
            [System.Windows.MessageBox]::Show($_.Exception.Message, "Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
        }
    })

    $switchProjectButton.Add_Click({
        try {
            $selectedNamespace = Select-OpenShiftNamespace
            Switch-OpenShiftProject -Namespace $selectedNamespace
        } catch {
            [System.Windows.MessageBox]::Show($_.Exception.Message, "Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
        }
    })

    $cancelButton.Add_Click({
        $window.Close()
    })
    
    $window.ShowDialog() | Out-Null
}

function Convert-Arguments {
    param (
        [string[]]$InputArgs
    )

    $parsedArgs = @{
        Cluster = $null
        Username = $null
        MyPass = $null
        Token = $null
    }

    for ($i = 0; $i -lt $InputArgs.Length; $i++) {
        switch ($InputArgs[$i]) {
            '--cluster' {
                $parsedArgs.Cluster = $InputArgs[$i + 1]
                $i++
            }
            '--user' {
                $parsedArgs.Username = $InputArgs[$i + 1]
                $i++
            }
            '--password' {
                $parsedArgs.MyPass = Read-Host "Enter Password" -AsSecureString
            }
            '--token' {
                $parsedArgs.Token = $InputArgs[$i + 1]
                $i++
            }
        }
    }

    return $parsedArgs
}

if ($args.Count -eq 0) {
    Show-OpenShiftGui
} else {
    $parsedArgs = Convert-Arguments -InputArgs $args

    if (-not $parsedArgs.Cluster -or (-not $parsedArgs.Username -and -not $parsedArgs.Token) -or (-not $parsedArgs.MyPass -and -not $parsedArgs.Token)) {
        Write-Host "Usage: .\Main.ps1 --cluster <ClusterName> [--user <Username> --password | --token <Token>]" -ForegroundColor Yellow
        exit 1
    }

    Invoke-OpenShiftConsole -ClusterName $parsedArgs.Cluster -Username $parsedArgs.Username -MyPass $parsedArgs.MyPass -Token $parsedArgs.Token
}