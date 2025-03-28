# Prompt for a string input
$name = Read-Host -Prompt "Enter your name"
 
#Get the input and store it in $Age variable name - without Prompt parameter
$Age = Read-Host "Please enter your age"
 
Write-Host "Hello $Name, you are $Age years old. Welcome to my script!"

param (
    [string[]]$Args
)

$parsedArgs = @{
    Cluster = $null
    Username = $null
    MyPass = $null
    Token = $null
}

for ($i = 0; $i -lt $Args.Length; $i++) {
    switch ($Args[$i]) {
        '--cluster' {
            $parsedArgs.Cluster = $Args[$i + 1]
            $i++
        }
        '--user' {
            $parsedArgs.Username = $Args[$i + 1]
            $i++
        }
        '--password' {
            $parsedArgs.MyPass = Read-Host "Enter Password" -AsSecureString
        }
        '--token' {
            $parsedArgs.Token = $Args[$i + 1]
            $i++
        }
    }
}
$parsedArgs.foreach{"Item [$PSItem]"}
