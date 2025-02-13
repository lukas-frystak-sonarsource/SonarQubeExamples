# Required setup
$TOKEN = "squ_3f2bb67dcd83212242375673360bd0e935d40e48";
$SONARQUBE_URL = "http://localhost:20251"

# Email of the user to migrate to SAML and the intended external identity.
$USER_EMAIL = "ahoj@test.com"
$USER_EXTERNAL_ID = "ahoj-tets"

########################################################################

# Authorization token must be passed in a header.
$httpRequestHeaders = @{
    "Authorization" = "Bearer $TOKEN"
}

# Get users: search by the user's email.
# Note: the request doesn't handle paging, but it shouldn't
#       be needed since we are searching by their email.
$users = $(Invoke-WebRequest -Headers $httpRequestHeaders `
        -Method GET `
        -Uri "$SONARQUBE_URL/api/v2/users-management/users?q=$USER_EMAIL" `
    | ConvertFrom-Json).users

# Find the required user
$requiredUser = $users | Where-Object { $_.email -eq $USER_EMAIL }
if ($null -eq $requiredUser) {
    Write-Error "User not found"
    Exit 1
}

# Create the body for the request with the updated information.
$body = "{""externalProvider"": ""saml"", ""externalLogin"": ""$USER_EXTERNAL_ID""}"
try {
    $body | ConvertFrom-Json > $null
}
catch {
    Write-Error "Invalid JSON body"
    Exit 1
}

# Execute the user PATCH request
Invoke-WebRequest -Headers $httpRequestHeaders `
    -Method PATCH `
    -ContentType "application/merge-patch+json" -Body $body `
    -Uri "$SONARQUBE_URL/api/v2/users-management/users/$($requiredUser.id)" `
| ConvertFrom-Json
