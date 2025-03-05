# Constants
$sonarqubeServerUrl = "http://mysonarqube.org"
$projectKey = "my-project-key"
$projectName = "My Project"
$projectVersion = "1.0"
$sonarScannerVerboseLog = "false"

# Extract branch name from Git
$currentBranchName = $(git rev-parse --abbrev-ref HEAD)

#
# Input validation
#
if ( [String]::IsNullOrEmpty($sonarqubeServerUrl)) {
    Write-Error "Provide SonarQube URL in the script variable: ""sonarqubeServerUrl"""
    Exit 1
}

if ( [String]::IsNullOrEmpty($Env:SONARQUBE_TOKEN)) {
    Write-Error "Provide SonarQube URL in the ""SONARQUBE_TOKEN"" environment variable."
    Exit 1
}

if (-not (($sonarScannerVerboseLog -eq "true") -or ($sonarScannerVerboseLog -eq "false"))) {
    Write-Error "Unsupported value of the ""sonarScannerVerboseLog"" variable."
    Exit 1
}

if ( [String]::IsNullOrEmpty($currentBranchName)) {
    Write-Error "Didn't find branch name from Git."
    Exit 1
}

# Define logs directory
$logsDir = "./logs/$(Get-Date -Format "yyyy-MM-dd-HH-mm-ss")"

# Create the logs directory
if (-not (Test-Path $logsDir)) {
    New-Item -Path $logsDir -ItemType Directory
}

#
# Begin Phase - Pre-processing
#
dotnet sonarscanner begin `
    /d:sonar.host.url=$sonarqubeServerUrl `
    /d:sonar.token=$Env:SONARQUBE_TOKEN `
    /key:$projectKey `
    /name:$projectName `
    /v:$projectVersion `
    /d:sonar.branch.name=$currentBranchName `
    /d:sonar.verbose=$sonarScannerVerboseLog `
    3>&1 2>&1 > "$logsDir/1_prepare-analysis.log"

if (-not $?) {
    Write-Error "Error when executing the prepare step"
    Exit 1
}

#
# Build
#
dotnet restore
dotnet build -t:Rebuild --no-restore --configuration Release 3>&1 2>&1 > "$logsDir/2_dotnet-build.log"

if (-not $?) {
    Write-Error "Error building the project"
    Exit 1
}

#
# End Phase - Analysis
#
dotnet sonarscanner end /d:sonar.token=$Env:SONARQUBE_TOKEN 3>&1 2>&1 > "$logsDir/3_end-analysis.log"

if (-not $?) {
    Write-Error "Error analyzing the project"
    Exit 1
}
