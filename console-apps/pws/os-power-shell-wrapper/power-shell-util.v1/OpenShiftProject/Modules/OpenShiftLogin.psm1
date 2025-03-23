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
