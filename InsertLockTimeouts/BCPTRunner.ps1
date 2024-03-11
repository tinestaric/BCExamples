$localUser = "YourLocalUser"
$suiteCode = "YourSuiteCode"

$serviceUrl = "http://BC240/BC/"

$UserName = "admin"
$password = ConvertTo-SecureString -String "Password" -AsPlainText -Force
$Credential = New-Object PSCredential -ArgumentList $UserName, $password

$extensionsRoot = "C:\Users\$localUser\.vscode\extensions\"
$extensionPrefix = "ms-dynamics-smb.bcpt"
$extensionFolder = Get-ChildItem -Path $extensionsRoot -Recurse -Directory | Where-Object { $_.Name -like "$extensionPrefix*" } | Select-Object -First 1 -ExpandProperty FullName

$scriptsPath = "$extensionFolder\bin\Resources\BCPTScripts"
$BCPTRunnerScript = "$scriptsPath\Public\RunBCPTTests.ps1"

& $BCPTRunnerScript `
    -Environment OnPrem `
    -AuthorizationType NavUserPassword `
    -Credential $Credential `
    -ServiceUrl $serviceUrl `
    -TestRunnerPage 149002 `
    -SuiteCode $suiteCode `
    -BCPTTestRunnerInternalFolderPath "$scriptsPath\Internal"