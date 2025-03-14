# Required setup
if ($args.Count -ne 2) {
    Write-Error "Unexpected number of arguments! 2 arguments are expeted!"
    Write-Output ""
    Write-Output "The script must be called like this:"
    Write-Output "./GetSonarQubeProjectInformation.ps1 <SONARQUBE_URL> <SONARQUBE_TOKEN>"
    Write-Output ""
    Exit 1
}

$global:SONARQUBE_URL = $args[0].TrimEnd('/')
$TOKEN = $args[1];

# Authentication
$encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("$($TOKEN):"))
$basicAuthValue = "Basic $encodedCreds"
$global:httpRequestHeaders = @{
    Authorization = $basicAuthValue
}

# Set progeress preference
$Global:ProgressPreference = "SilentlyContinue"

# Get all projects with the api/projects/search
$initialProjectList = [System.Collections.ArrayList]::new()
$currentPage = 0

do {
    $currentPage++
    $response = Invoke-WebRequest -Headers $httpRequestHeaders `
        -Method GET `
        -Uri "$SONARQUBE_URL/api/projects/search?p=$currentPage&ps=500"
    
    $content = $response.Content | ConvertFrom-Json

    # Get paging information
    $pageIndex = $content.paging.pageIndex
    $pageSize = $content.paging.pageSize
    $totalItems = $content.paging.total

    # Get project data
    $components = $content.components
    $initialProjectList.AddRange($components)

    Write-Output "Got projects - page $currentPage/$([Math]::Ceiling($totalItems / $pageSize))"

} while (($pageIndex * $pageSize) -lt $totalItems)

# Sanitize the project information is a new list. Collect additional information
$projectInformation = [System.Collections.ArrayList]::new()

for ($i = 0; $i -lt $initialProjectList.Count; $i++) {
    $prjInfo = [ProjectInformation]::new($initialProjectList[$i])
    $prjInfo.GetMainBranchName()
    $projectInformation.Add($prjInfo) > $null

    if (($i % 200) -eq 0) {
        Write-Output "Processing projects $i / $($initialProjectList.Count)"
    }
}

$csvFileName = "SonarQubeProjectInformation.csv"
$projectInformation | ConvertTo-Csv > $csvFileName

Write-Output "Script finished! The information was saved in $csvFileName"

###
### CLASS DEFINITION
###

class ProjectInformation {
    [string]$key
    [string]$name
    [string]$qualifier
    [string]$visibility
    [string]$lastAnalysisDate
    [string]$mainBranchName
    #[string]$bitbucketRepoName
    #[string]$doesMatchPermissionTemplate
    #[string]$permissionTemplateName
    #[string]$dceKey

    ProjectInformation($apiObject) {
        $this.key = $apiObject.key
        $this.name = $apiObject.name
        $this.qualifier = $apiObject.qualifier
        $this.visibility = $apiObject.visibility
        if ($null -ne $apiObject.lastAnalysisDate) {
            $this.lastAnalysisDate = $apiObject.lastAnalysisDate
        }
        else {
            $this.lastAnalysisDate = "-"
        }

        if ([string]::IsNullOrEmpty($this.key)) {
            Write-Error "Unexpected empty project key for project ""$($this.key)""! Investigation needed."
            Exit 1
        }

        if (([string]::IsNullOrEmpty($this.key)) -or
            ([string]::IsNullOrEmpty($this.name)) -or
            ([string]::IsNullOrEmpty($this.qualifier)) -or
            ([string]::IsNullOrEmpty($this.visibility)) -or
            ([string]::IsNullOrEmpty($this.lastAnalysisDate))
        ) {
            Write-Warning "Unexpect null when getting project information for project ""$($this.key)""."
        }
    }

    [void] GetMainBranchName() {
        $response = Invoke-WebRequest -Headers $global:httpRequestHeaders `
            -Method GET `
            -Uri "$global:SONARQUBE_URL/api/project_branches/list?project=$($this.key)"
        $content = $response.Content | ConvertFrom-Json

        if ($null -ne $content.branches) {
            $mainBranch = $($content.branches | Where-Object { $_.isMain -eq $true })
            if ($null -ne $mainBranch) {
                if (-not [string]::IsNullOrEmpty($mainBranch.name)) {
                    $this.mainBranchName = $mainBranch.name
                }
                else {
                    Write-Error "Unexpected empty main branch name for project ""$($this.key)"". Needs investigation!"
                    Exit 1
                }
            }
            else {
                Write-Error "No main branch found for project ""$($this.key)"". Unexpected - Needs investigation!"
                Exit 1
            }
        }
        else {
            Write-Error "No branches found for project ""$($this.key)"". Unexpected - Needs investigation!"
            Exit 1
        }
    }

    [void] DoesMatchPermissionTemplateKey([string[]]$templateKeyPatterns) {
        # TODO
        # The input could be just patterns, or patterns + template names
    }
}
