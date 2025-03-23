function Test-OcExecutable {
    if (-not (Get-Command "oc.exe" -ErrorAction SilentlyContinue)) {
        throw "The 'oc.exe' CLI tool is not installed or not available in the system PATH."
    }
}
Export-ModuleMember -Function Test-OcExecutable
