# SonarQube connection parameters
$TOKEN = "";
$SONARQUBE_URL = ""

# Email of the user to migrate to SAML and the intended external identity.
$USER_EMAIL = ""
$USER_EXTERNAL_ID = $USER_EMAIL.ToLower()

# Get all users
$users = $(curl -s --header "Authorization: Bearer $TOKEN" --url "$SONARQUBE_URL/api/v2/users-management/users" | ConvertFrom-Json).users

# Find the required user
$requiredUser = $users | Where-Object { $_.email -eq $USER_EMAIL }
if ($null -eq $requiredUser) {
    Write-Error "User not found"
    Exit 1
}

# Extract the users ID
$SQ_USER_ID = $requiredUser.id

# Create the body for the request with the updated information.
$body = "{""externalProvider"": ""saml"", ""externalLogin"": ""$USER_EXTERNAL_ID""}"
try {
    $body | ConvertFrom-Json > $null
}
catch{
    Write-Error "Invalid JSON body"
    Exit 1
}

# Execute the user PATCH request
curl `
    -s --header "Authorization: Bearer $TOKEN" `
     -X PATCH -H "Content-Type: application/merge-patch+json" -d $body `
    --url "$SONARQUBE_URL/api/v2/users-management/users/$SQ_USER_ID" | ConvertFrom-Json
