# SonarQubeExamples
A collection of SonarQube-related examples.

> [!IMPORTANT]  
> The examples in this repository are just that - *examples*!
> 
> They are meant to serve as inspiration; they are not tested for production systems.

## Get SonarQube Project Information

### How to use this script

1. PowerShell is used for all commands!
1. Download the script to a your machine:
    ```
    Invoke-WebRequest -OutFile "GetSonarQubeProjectInformation.ps1" -Uri "https://raw.githubusercontent.com/lukas-frystak-sonarsource/SonarQubeExamples/refs/heads/lukas/2025-03-28/GetSonarQubeProjectInformation.ps1"
    ```
1. The script takes the SonarQube URL and <u>administrator</u> token as inputs.
    - The token can be generated in the SonarQube UI. Go to *My account --> Security --> Generate tokens*
1. **Run the script**
    ```
    ./GetSonarQubeProjectInformation.ps1 <SONARQUBE_URL> <SONARQUBE_TOKEN>
    ```

**The output**

The output in the CSV file is the following (with some comments):
- "Basic" project properties
    - SonarQube project key
    - SonarQube project name
    - SonarQube object qualifier
        - *Note: TRK = project*
    - Visibility
        - *Note: Tall projects should be private*
    - Last analysis date
    - Main branch name in SonarQube
        - *Note: this should match the default branch name in the corresponding repository*
- Permission template association (*Note: verify that the project follow the naming convention*)
    - doesMatchPermissionTemplate
    - permissionTemplateName
    - permissionTemplatePattern
- DevOps properties
    - isBoundToDevOpsRepo
        - *Note: all SonarQube projects should be bound to their corresponding repository*
    - devOpsPlatformType
    - devOpsPlatformKey
    - devOpsProject
    - repositoryName
    - isMonorepo
    - devOpsPlatformUrl