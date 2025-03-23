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
